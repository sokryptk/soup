# Quickshell

Hyprland shell with a top bar, workspace overview, window switcher, control center,
calendar, world clocks, and AI usage indicator.

## Usage indicator

- Scroll over the indicator to switch between Codex and Claude.
- Codex shows the weekly allowance remaining; Claude shows the five-hour session
  allowance remaining.
- Click the indicator for usage details, reset times, pacing, manual refresh, and
  a link to the provider's usage dashboard. Claude's popup also shows weekly usage.
- Both providers refresh every two minutes, including the provider currently hidden.
- Claude uses CodexBar's OAuth source with the existing Claude Code login. Usage
  credentials are kept outside this repository.

## Requirements

- Quickshell with its Hyprland, Wayland, MPRIS, system tray, and I/O modules, plus
  Qt Quick Layouts and Qt 5 compatibility graphical effects.
- `codexbar` at `/usr/bin/codexbar`, with Codex and Claude Code already signed in.
- GNU `timeout` at `/usr/bin/timeout` for the bounded Claude usage check.
- The other shell controls use `bash`, `timedatectl`, `iwctl`, `rfkill`,
  `bluetoothctl`, `wpctl`, `pactl`, `jq`, `brightnessctl`, `ddcutil`, and `xdg-open`.
- The configured font is SF Pro Text. Wi-Fi commands currently target `wlan0`.

## Install

From the repository root:

```sh
mkdir -p ~/.config/quickshell
cp -r ingredients/quickshell/components ingredients/quickshell/services ~/.config/quickshell/
cp ingredients/quickshell/shell.qml ~/.config/quickshell/
cp ingredients/quickshell/world-clocks.json ~/.config/quickshell/
quickshell --no-duplicate --daemonize
```

Keep `components/` and `services/` alongside `shell.qml`. World clock selections are saved to
`~/.config/quickshell/world-clocks.json` when edited in the shell.

To launch on login, add `quickshell --no-duplicate --daemonize` to Hyprland's startup
commands. Quickshell automatically reloads when its configuration changes.

## Quick overview

The overview is in `components/Overview.qml`: live workspace and window previews,
workspace switching, and click-to-focus windows. Open it with the grid button on
the left of the bar, and close it with Escape or a click on the background.

The companion `hyprland-overview.lua` preserves the current Lua-based Hyprland
integration: Quickshell autostart, overview blur, and the `XF86LaunchA` and
`mouse:277` shortcuts. Install it with:

```sh
cp ingredients/quickshell/hyprland-overview.lua ~/.config/quickshell/
```

Load it from `~/.config/hypr/hyprland.lua` in place of the equivalent existing
startup entry, overview layer rule, and overview bindings:

```lua
dofile(os.getenv("HOME") .. "/.config/quickshell/hyprland-overview.lua")
```

The overview can also be controlled directly:

```sh
quickshell ipc call overview toggle
quickshell ipc call overview open
quickshell ipc call overview close
```

## Layout

- `shell.qml` creates the shared services and one `ScreenShell` per monitor.
- `services/` owns desktop state, calendar settings, hardware polling, usage
  fetching, and theme colors. Polling runs once, regardless of monitor count.
- `components/ScreenShell.qml` connects each monitor's windows to those services.
- `components/Bar.qml`, `SystemTrayWidget.qml`, and `UsageWidget.qml` build the bar;
  each provider has a separate usage popup.
- `components/Overview.qml` and `WindowSwitcher.qml` own the window previews.
- `components/ClockCenter.qml` and `ControlCenter.qml` compose their smaller panels
  and have separate click-outside dismissal windows.

Components declare their service dependencies as required properties. Keep
background processes in services and pass those services into views instead of
referencing IDs in another QML file.
