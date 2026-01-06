#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

YELLOW='\033[0;33m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

command -v aws >/dev/null 2>&1 || error "aws CLI not found"

ERRORS=0
track_error() { ((ERRORS++)) || true; warn "$1"; }

if [[ "${AWS_ENDPOINT_URL:-}" != "http://localhost:4566" ]]; then
    error "AWS_ENDPOINT_URL must be http://localhost:4566 (got: ${AWS_ENDPOINT_URL:-<not set>})"
fi

export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_EC2_METADATA_DISABLED=true

ACCOUNTS=("111111111111" "222222222222")
REGIONS=("us-east-1" "us-west-2" "ap-northeast-1")

aws_cmd() {
    aws --endpoint-url="${AWS_ENDPOINT_URL}" "$@"
}

cleanup_account_region() {
    local account="$1"
    local region="$2"
    export AWS_ACCESS_KEY_ID="$account"
    export AWS_DEFAULT_REGION="$region"
    
    log "Cleaning $account / $region..."
    
    local instances=$(aws_cmd ec2 describe-instances \
        --filters "Name=tag:Project,Values=claws-demo" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
        --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "")
    if [[ -n "$instances" ]]; then
        for id in $instances; do
            aws_cmd ec2 terminate-instances --instance-ids "$id" 2>/dev/null && log "  Terminated: $id" || track_error "Failed: $id"
        done
        sleep 2
    fi
    
    local sgs=$(aws_cmd ec2 describe-security-groups \
        --filters "Name=tag:Project,Values=claws-demo" \
        --query 'SecurityGroups[].GroupId' --output text 2>/dev/null || echo "")
    for sg in $sgs; do
        aws_cmd ec2 delete-security-group --group-id "$sg" 2>/dev/null && log "  Deleted SG: $sg" || track_error "Failed SG: $sg"
    done
    
    local subnets=$(aws_cmd ec2 describe-subnets \
        --filters "Name=tag:Project,Values=claws-demo" \
        --query 'Subnets[].SubnetId' --output text 2>/dev/null || echo "")
    for subnet in $subnets; do
        aws_cmd ec2 delete-subnet --subnet-id "$subnet" 2>/dev/null && log "  Deleted subnet: $subnet" || track_error "Failed subnet: $subnet"
    done
    
    local rts=$(aws_cmd ec2 describe-route-tables \
        --filters "Name=tag:Project,Values=claws-demo" \
        --query 'RouteTables[].RouteTableId' --output text 2>/dev/null || echo "")
    for rt in $rts; do
        local assocs=$(aws_cmd ec2 describe-route-tables --route-table-ids "$rt" \
            --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' --output text 2>/dev/null || echo "")
        for assoc in $assocs; do
            aws_cmd ec2 disassociate-route-table --association-id "$assoc" 2>/dev/null || true
        done
        aws_cmd ec2 delete-route-table --route-table-id "$rt" 2>/dev/null && log "  Deleted RT: $rt" || track_error "Failed RT: $rt"
    done
    
    local igws=$(aws_cmd ec2 describe-internet-gateways \
        --filters "Name=tag:Project,Values=claws-demo" \
        --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null || echo "")
    for igw in $igws; do
        local vpc=$(aws_cmd ec2 describe-internet-gateways --internet-gateway-ids "$igw" \
            --query 'InternetGateways[0].Attachments[0].VpcId' --output text 2>/dev/null || echo "")
        if [[ -n "$vpc" && "$vpc" != "None" ]]; then
            aws_cmd ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" 2>/dev/null || true
        fi
        aws_cmd ec2 delete-internet-gateway --internet-gateway-id "$igw" 2>/dev/null && log "  Deleted IGW: $igw" || track_error "Failed IGW: $igw"
    done
    
    local vpcs=$(aws_cmd ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=claws-demo" \
        --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
    for vpc in $vpcs; do
        aws_cmd ec2 delete-vpc --vpc-id "$vpc" 2>/dev/null && log "  Deleted VPC: $vpc" || track_error "Failed VPC: $vpc"
    done
}

log "=== claws LocalStack Demo Cleanup ==="

for account in "${ACCOUNTS[@]}"; do
    for region in "${REGIONS[@]}"; do
        cleanup_account_region "$account" "$region"
    done
done

export AWS_ACCESS_KEY_ID="${ACCOUNTS[0]}"
export AWS_DEFAULT_REGION="us-east-1"

log "Deleting S3 buckets..."
for bucket in claws-demo-assets claws-demo-logs claws-demo-backups; do
    aws_cmd s3 rb "s3://${bucket}" --force 2>/dev/null && log "  Deleted: $bucket" || true
done

if [[ $ERRORS -gt 0 ]]; then
    warn "=== Cleanup completed with $ERRORS error(s) ==="
else
    log "=== Cleanup complete ==="
fi
