# Power Manager Daemon

## Building and Installation

You will need the folowing dependencies:
* `glib-2.0`
* `gobject-2.0`
* `meson`
* `valac`


Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

```bash
meson build --prefix=/usr
cd build
ninja
```

To install, use `ninja install`, then execute with `io.elementary.power-manager-daemon`

```bash
ninja install
sudo io.elementary.power-manager-daemon
```

## Usage

- The daemon requires root priviledges to manage CPU frequencies at kernel level. Hence, its run as a systemd service as root.
- The daemon provides an user facing gsettings schema to control the management mode.
- There's three management modes available:
    -  `0: Power Saver`
    -  `1: Automatic`
    -  `2: High Performance`
- The daemon does not set fixed min or max frequencies for the CPU even if the CPU driver provides them. It merely sets a cpufreq governor mode and a *suggestive* turbo mode if turbo is available.
- In any mode ("Power Saving" or "High Performance"), the daemon scales governor and/or turbo to a degree based on average system load.
- In "Automatic" mode, in addition to aforementioned scaling, the daemon uses battery sensor data to determine the mode automatically.
