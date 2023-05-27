# Assorted Scripts

A collection of scripts that I use on my system and for my workflow.

## Scripts

### [Alacritty](https://github.com/alacritty/alacritty)

These scripts are not as useful to me anymore as I use `tmux`.

- `alacritty-create-window.sh` - create a new Alacritty window through IPC as
  opposed to launching a new process.
- `alacritty-open-cwd.sh` - launch new Alacritty process with the same starting
  directory as the currently selected Alacritty window.

### Ardour/JACK

I use Ardour as my audio mixer so that I can control the volume/mute state of
different JACK clients with the help of a MIDI controller and add plugins to the
channels.

- `ardour-nsm-session-name.sh` - query the Ardour session name from nsmd logs.
- `ardour-save-restore-node.sh` - exists for historical reasons only, before I
  used nsmd.
- `desktop2-jack-ardour-patchbay.sh` - connect netjack clients from my second
  desktop to the Ardour client.
- `pulse-jack-modules.sh` - load JACK sinks and sources into pulseaudio.
- `qjackctl-startup.sh` - script to execute after QjackCtl starts the JACK
  server.
- `qjackctl-shutdown.sh` - script to execute before QjackCtl shuts down the JACK
  server.

### [bspwm](https://github.com/baskerville/bspwm)

- `bspwm-scratchpad.sh` - my attempt at implementing a scratchpad-like
  functionality in bspwm. I use a separate desktop rather than hiding windows
  because the latter had some problems with window focus after un-hiding them.
- `bspwm-zen-mode.sh` - implement something akin to a "zen mode" by hiding my
  status bar (polybar), reducing window gaps and optionally pausing
  notifications.

### [dunst](https://github.com/dunst-project/dunst)

- `dunst-backlight-brightness.sh` - control the laptop's backlight brightness
  and display a notification with a progress bar.
- `dunst-notification-sound-message.sh` - single-line script to play a
  notification sound.
- `dunst-pulseaudio-toggle-mute.sh` - toggle the mute state of the current
  default pulseaudio sink and show a notification.
- `dunst-pulseaudio-volume.sh` - control the volume of the current default
  pulseaudio sink and show a notification with a progress bar.

### [Rofi](https://github.com/davatorium/rofi)

- `rofi-gpu-clock-profiles.sh` - display a set of GPU overclocking or
  underclocking profiles.
- `rofi-manage-skyrimse-launch.sh` - display a set of Skyrim SE launch
  configurations and change to a different one. More on this inside
  `steam-launch/`.
- `rofi-manage-vms.sh` - display libvirt VMs and launch, shut down, pause them
  or launch [Looking Glass](https://looking-glass.io/).
- `rofi-scratchpad.sh` - show a list of windows in the scratchpad and select one
  to bring it to the current desktop. Works in tandem with
  `bspwm-scratchpad.sh`.
- `rofi-sxhkd-cheatsheet.sh` - show my
  [sxhkd](https://github.com/baskerville/sxhkd) key combinations.

### OBS

- `launch-obs-portable.sh` - simple script to launch a portable installation of
  OBS.
- `obs-jack-patchbay.sh` - connect OBS JACK clients to the Ardour client.

### Virtual Machines

- `launch-vm-jack-patchbay.sh` - connect JACK clients of a specific libvirt VM
  to the Ardour client.
- `launch-vm-looking-glass.sh` - launch [Looking
  Glass](https://looking-glass.io/) client for a particular VM and connect JACK
  patchbay.

### Misc

- `check-iommu.sh` - script shamelessly copied from ArchWiki to check IOMMU
  groups.
- `ddc-switch-input-source.sh` - switch input source of a monitor through DDC.
- `env-generic-dxvk-game.sh` - print the assignment of some environment
  variables when launching a dxvk game through Steam.
- `nsmd-action.py` - execute NSM action by sending a message to nsmd.
- `scripts-generate-symlinks.sh` - generate symbolic links in some target
  directory to these scripts, useful when I want these scripts in PATH.
- `toggle-secondary-monitor.sh` - what the name implies, turn on or off my
  secondary monitor when gaming in X11.

### Steam Launch

The scripts contained in `steam-launch/` serve as a way to modify launch
configurations of games when launched from Steam, especially modded ones.
