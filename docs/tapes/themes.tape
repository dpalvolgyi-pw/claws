# Generate theme screenshots - run via: task demo:record:themes
# Requires LocalStack running with demo data

Set FontSize 16
Set Width 1920
Set Height 1080
Set TypingSpeed 0.05

# Theme: dark (default)
Type "./claws -t dark"
Enter
Sleep 2s
Type ":"
Sleep 0.5s
Type "ec2/instances"
Enter
Sleep 2s
Screenshot docs/images/theme-dark.png
Type "q"
Sleep 0.5s

# Theme: light (white background)
Set Theme { "background": "#ffffff", "foreground": "#333333", "black": "#000000", "white": "#ffffff" }
Type "./claws -t light"
Enter
Sleep 2s
Type ":"
Sleep 0.5s
Type "ec2/instances"
Enter
Sleep 2s
Screenshot docs/images/theme-light.png
Type "q"
Sleep 0.5s

# Reset to dark background for remaining themes
Set Theme "Builtin Dark"

# Theme: nord
Type "./claws -t nord"
Enter
Sleep 2s
Type ":"
Sleep 0.5s
Type "ec2/instances"
Enter
Sleep 2s
Screenshot docs/images/theme-nord.png
Type "q"
Sleep 0.5s

# Theme: dracula
Type "./claws -t dracula"
Enter
Sleep 2s
Type ":"
Sleep 0.5s
Type "ec2/instances"
Enter
Sleep 2s
Screenshot docs/images/theme-dracula.png
Type "q"
Sleep 0.5s

# Theme: gruvbox
Type "./claws -t gruvbox"
Enter
Sleep 2s
Type ":"
Sleep 0.5s
Type "ec2/instances"
Enter
Sleep 2s
Screenshot docs/images/theme-gruvbox.png
Type "q"
Sleep 0.5s

# Theme: catppuccin
Type "./claws -t catppuccin"
Enter
Sleep 2s
Type ":"
Sleep 0.5s
Type "ec2/instances"
Enter
Sleep 2s
Screenshot docs/images/theme-catppuccin.png
Type "q"
Sleep 0.5s
