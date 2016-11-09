# i3wm-app-finder

Dependencies:
* SWI Prolog 7.2.3 or lower which has dicts and strings
* dmenu
* ImageMagick import command

Usage:

Add keybinding to i3wm configuration **$HOME/.config/i3/config**

```
bindsym $mod+g exec $HOME/.software/i3wm/i3wm-app-finder/find-app.pl

#
# To take screenshots
#

set $mode_screenshot Screenshot (r) rectangle, (w) window
mode "$mode_screenshot" {
    bindsym r exec $HOME/.software/i3wm/i3wm-app-finder/take-screenshot.pl rectangle && sleep 1, mode "default"
    bindsym w exec $HOME/.software/i3wm/i3wm-app-finder/take-screenshot.pl window && sleep 1, mode "default"

    # back to normal: Enter or Escape
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym Print mode "$mode_screenshot"

# Or
bindsym Print exec $HOME/.software/i3wm/i3wm-app-finder/take-screenshot.pl rectangle && sleep 1
bindsym $mod+Print exec $HOME/.software/i3wm/i3wm-app-finder/take-screenshot.pl window && sleep 1

```
