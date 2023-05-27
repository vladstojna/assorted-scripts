# Steam Launch

The `skyrimse-*` scripts represent different configurations to launch:

- `skyrimse-mo2-skse.sh` - basic, vanilla configuration with only SKSE.
- `skyrimse-wildlander-launcher.sh` - launch the Wildlander mod pack launcher.
- `skyrimse-wildlander.sh` - launch the Wildlander mod pack directly from MO2.

`skyrimse.sh` is the script called from inside Steam's launch options. It uses
a symbolic link `skyrim-executable` in this directory which points to a script
from the above list to dynamically consider a different configuration.

Steam's launch options look like this:

```sh
$(echo %command% | /path/to/steam-launch/skyrimse.sh)
```

In conjunction with `rofi-manage-skyrimse-launch.sh`, I can use different mod
packs in Skyrim with ease :)
