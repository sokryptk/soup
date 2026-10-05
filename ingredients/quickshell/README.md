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
cp ingredients/quickshell/shell.qml ingredients/quickshell/ClaudeUsage.qml ~/.config/quickshell/
cp ingredients/quickshell/world-clocks.json ~/.config/quickshell/
quickshell --no-duplicate --daemonize
```

Keep `ClaudeUsage.qml` alongside `shell.qml`. World clock selections are saved to
`~/.config/quickshell/world-clocks.json` when edited in the shell.

To launch on login, add `quickshell --no-duplicate --daemonize` to Hyprland's startup
commands. Quickshell automatically reloads when its configuration changes.
