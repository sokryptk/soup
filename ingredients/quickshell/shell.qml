//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

ShellRoot {
    id: root

    property bool overviewOpen: false
    property string overviewScreenName: ""
    property bool windowSwitcherOpen: false
    property string windowSwitcherScreenName: ""
    property var windowSwitcherWindows: []
    property int windowSwitcherIndex: 0
    property bool controlCenterOpen: false
    property string controlCenterScreenName: ""
    property bool clockCenterOpen: false
    property string clockCenterScreenName: ""
    property int calendarYear: clock.date.getFullYear()
    property int calendarMonth: clock.date.getMonth()
    property var worldClocks: [
        { label: "San Francisco", timezone: "America/Los_Angeles" },
        { label: "London", timezone: "Europe/London" },
        { label: "Dubai", timezone: "Asia/Dubai" },
        { label: "Mumbai", timezone: "Asia/Kolkata" }
    ]
    property var worldClockValues: []
    property string usageProvider: "codex"
    property real usageWheelDelta: 0
    property real codexUsageLeft: -1
    property string codexUsageStatus: "loading"
    property string codexUsageTooltip: "Loading Codex usage…"
    property string codexUsageResetLabel: "unknown"
    property string codexUsagePaceSummary: ""
    property string codexUsagePlan: ""
    property string codexUsageCredits: ""
    property bool codexUsageOpen: false
    readonly property string codexUsageLabel: codexUsageLeft >= 0
                                                ? "Codex " + Math.round(codexUsageLeft * 100) + "%"
                                                : "Codex --"
    readonly property color codexUsageColor: codexUsageStatus !== "ok"
                                              ? root.urgent
                                              : codexUsageLeft < 0.2
                                                ? root.urgent
                                                : codexUsageLeft < 0.5
                                                  ? "#e5c07b" : "#98c379"
    readonly property string codexUsagePaceText: codexUsageStatus === "ok"
                                                  ? "Pace: " + codexUsagePaceSummary
                                                  : "Pace: waiting for usage data"
    property bool worldClockEditing: false
    property bool clockPickerOpen: false
    property string clockSearch: ""
    property var availableWorldClocks: [
        { label: "San Francisco", timezone: "America/Los_Angeles" },
        { label: "New York", timezone: "America/New_York" },
        { label: "Vancouver", timezone: "America/Vancouver" },
        { label: "Toronto", timezone: "America/Toronto" },
        { label: "São Paulo", timezone: "America/Sao_Paulo" },
        { label: "London", timezone: "Europe/London" },
        { label: "Paris", timezone: "Europe/Paris" },
        { label: "Berlin", timezone: "Europe/Berlin" },
        { label: "Istanbul", timezone: "Europe/Istanbul" },
        { label: "Dubai", timezone: "Asia/Dubai" },
        { label: "Mumbai", timezone: "Asia/Kolkata" },
        { label: "Singapore", timezone: "Asia/Singapore" },
        { label: "Tokyo", timezone: "Asia/Tokyo" },
        { label: "Seoul", timezone: "Asia/Seoul" },
        { label: "Sydney", timezone: "Australia/Sydney" },
        { label: "Auckland", timezone: "Pacific/Auckland" }
    ]
    property bool wifiExpanded: false
    property bool bluetoothExpanded: false
    readonly property bool connectivityDetailsOpen: wifiExpanded || bluetoothExpanded
    property var wifiNetworks: []
    property var bluetoothDevices: []
    property var wifiNetworkIndex: ({})
    property var bluetoothDeviceIndex: ({})
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property string wifiConnectedName: ""
    property string bluetoothConnectedName: ""
    property real brightnessLevel: 0.7
    property bool brightnessAvailable: false
    property real volumeLevel: 0.2
    property bool outputExpanded: false
    property var audioOutputs: []
    property string defaultAudioOutput: ""
    readonly property string currentAudioOutputLabel: {
        const output = audioOutputs.find(item => item.name === defaultAudioOutput)
        return output?.description || "Choose output"
    }
    readonly property string wifiSubtitle: !wifiEnabled ? "Off"
                                           : wifiConnectedName || "On"
    readonly property string bluetoothSubtitle: !bluetoothEnabled ? "Off"
                                                : bluetoothConnectedName || "On"
    readonly property var mediaPlayer: Mpris.players.values.find(player => player.isPlaying)
                                       ?? Mpris.players.values[0] ?? null

    function screenIsCaptureable(screenName): bool {
        if (!screenName)
            return false

        return Quickshell.screens.some(screen =>
            screen.name === screenName && Hyprland.monitorFor(screen) !== null)
    }

    function toplevelIsCaptureable(toplevel): bool {
        return toplevel?.wayland
            && Hyprland.toplevels.values.includes(toplevel)
    }

    function openOverview(targetScreen): void {
        const selectedScreen = targetScreen ?? Quickshell.screens.find(candidate =>
            Hyprland.monitorFor(candidate) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        overviewScreenName = selectedScreen?.name ?? ""
        overviewOpen = true
    }

    function toggleOverview(targetScreen): void {
        if (overviewOpen)
            closeOverview()
        else
            openOverview(targetScreen)
    }

    function closeOverview(): void {
        overviewOpen = false
    }

    function activateWorkspace(workspace): void {
        if (!workspace)
            return
        const selector = "name:" + workspace.name
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + JSON.stringify(selector) + " })")
        else
            Hyprland.dispatch("workspace " + selector)
    }

    function openWindowSwitcher(reverse): void {
        const selectedScreen = Quickshell.screens.find(candidate =>
            Hyprland.monitorFor(candidate) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        const active = Hyprland.activeToplevel
        const activeWorkspace = active?.workspace ?? null
        const windows = Hyprland.toplevels.values.filter(toplevel =>
            toplevel.wayland && toplevel.workspace === activeWorkspace)
        windows.sort((left, right) => left === active ? -1 : right === active ? 1 : 0)
        windowSwitcherScreenName = selectedScreen?.name ?? ""
        windowSwitcherWindows = windows
        windowSwitcherIndex = windows.length < 2 ? 0 : reverse ? windows.length - 1 : 1
        windowSwitcherOpen = windows.length > 0
    }

    function cycleWindowSwitcher(reverse): void {
        if (!windowSwitcherOpen) {
            openWindowSwitcher(reverse)
            return
        }
        const count = windowSwitcherWindows.length
        if (count > 0)
            windowSwitcherIndex = (windowSwitcherIndex + (reverse ? count - 1 : 1)) % count
    }

    function acceptWindowSwitcher(): void {
        if (!windowSwitcherOpen || windowSwitcherWindows.length === 0)
            return
        const selected = windowSwitcherWindows[windowSwitcherIndex]
        windowSwitcherOpen = false
        if (selected.wayland)
            selected.wayland.activate()
    }

    function closeWindowSwitcher(): void {
        windowSwitcherOpen = false
    }

    function toggleControlCenter(targetScreen): void {
        controlCenterScreenName = targetScreen?.name ?? ""
        clockCenterOpen = false
        controlCenterOpen = !controlCenterOpen
    }

    function toggleClockCenter(targetScreen): void {
        clockCenterScreenName = targetScreen?.name ?? ""
        controlCenterOpen = false
        wifiExpanded = false
        bluetoothExpanded = false
        outputExpanded = false
        if (!clockCenterOpen) {
            calendarYear = clock.date.getFullYear()
            calendarMonth = clock.date.getMonth()
            if (!worldClockRefresh.running)
                worldClockRefresh.running = true
        }
        clockCenterOpen = !clockCenterOpen
    }

    function changeCalendarMonth(delta): void {
        const changed = new Date(calendarYear, calendarMonth + delta, 1)
        calendarYear = changed.getFullYear()
        calendarMonth = changed.getMonth()
    }

    function calendarCells(): var {
        const first = new Date(calendarYear, calendarMonth, 1)
        const mondayOffset = (first.getDay() + 6) % 7
        const start = new Date(calendarYear, calendarMonth, 1 - mondayOffset)
        const today = clock.date
        const cells = []
        for (let index = 0; index < 42; ++index) {
            const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index)
            cells.push({
                day: date.getDate(),
                currentMonth: date.getMonth() === calendarMonth,
                today: date.getFullYear() === today.getFullYear()
                       && date.getMonth() === today.getMonth()
                       && date.getDate() === today.getDate()
            })
        }
        return cells
    }

    function worldClockCommand(): string {
        return worldClocks.map((entry, index) =>
            "printf '" + index + "|'; TZ='" + entry.timezone
            + "' date '+%H:%M|%a, %d %b'").join("; ")
    }

    function formatDuration(seconds): string {
        if (!Number.isFinite(seconds))
            return "unknown"
        let remaining = Math.max(0, Math.round(seconds))
        const days = Math.floor(remaining / 86400)
        remaining %= 86400
        const hours = Math.floor(remaining / 3600)
        remaining %= 3600
        const minutes = Math.floor(remaining / 60)
        if (days > 0)
            return days + "d " + hours + "h"
        if (hours > 0)
            return hours + "h " + minutes + "m"
        return minutes + "m"
    }

    function scrollUsageProvider(wheel): void {
        const delta = wheel.angleDelta.y || wheel.angleDelta.x
        wheel.accepted = delta !== 0
        if (delta === 0)
            return

        // Accumulate high-resolution wheel events into full notches.
        usageWheelDelta += delta
        const steps = Math.trunc(usageWheelDelta / 120)
        usageWheelDelta -= steps * 120
        if (Math.abs(steps) % 2 === 0)
            return

        codexUsageOpen = false
        usageProvider = usageProvider === "codex" ? "claude" : "codex"
    }

    function parseCodexUsage(payload): void {
        try {
            const provider = JSON.parse(payload)[0]
            const usage = provider?.usage
            const weekly = usage?.secondary
            if (!weekly || typeof weekly.usedPercent !== "number")
                throw new Error("Codex usage data unavailable")

            const usedPercent = Math.max(0, Math.min(100, weekly.usedPercent))
            const resetAt = Date.parse(weekly.resetsAt || "")
            const resetSeconds = Number.isFinite(resetAt)
                                 ? Math.max(0, (resetAt - Date.now()) / 1000)
                                 : NaN
            codexUsageLeft = 1 - (usedPercent / 100)
            codexUsageResetLabel = Number.isFinite(resetSeconds)
                                   ? root.formatDuration(resetSeconds)
                                   : (weekly.resetDescription || "unknown")
            codexUsagePaceSummary = provider?.pace?.secondary?.summary
                                     ? provider.pace.secondary.summary.split(" | ").join(" · ")
                                     : "pace data unavailable"
            codexUsagePlan = usage.loginMethod
                              ? usage.loginMethod.charAt(0).toUpperCase()
                                + usage.loginMethod.slice(1)
                              : ""
            codexUsageCredits = typeof usage.credits?.remaining === "number"
                                ? usage.credits.remaining + " left" : ""
            codexUsageStatus = "ok"
            codexUsageTooltip = "Codex weekly quota: "
                                + Math.round(codexUsageLeft * 100)
                                + "% remaining · resets in "
                                + codexUsageResetLabel
        } catch (error) {
            codexUsageLeft = -1
            codexUsageStatus = "error"
            codexUsageResetLabel = "unknown"
            codexUsagePaceSummary = ""
            codexUsagePlan = ""
            codexUsageCredits = ""
            codexUsageTooltip = "Codex usage unavailable"
            console.warn("Could not load Codex usage:", error)
        }
    }

    function saveWorldClocks(): void {
        worldClockSettings.setText(JSON.stringify({ clocks: worldClocks }, null, 2) + "\n")
        if (!worldClockRefresh.running)
            worldClockRefresh.running = true
    }

    function addWorldClock(entry): void {
        if (worldClocks.some(clockEntry => clockEntry.timezone === entry.timezone))
            return
        worldClocks = worldClocks.concat([{ label: entry.label, timezone: entry.timezone }])
        saveWorldClocks()
    }

    function removeWorldClock(index): void {
        const changed = worldClocks.slice()
        changed.splice(index, 1)
        worldClocks = changed
        saveWorldClocks()
    }

    function runControl(command): void {
        Quickshell.execDetached(["bash", "-lc", command])
    }

    function toggleWifiList(): void {
        wifiExpanded = !wifiExpanded
        bluetoothExpanded = false
        if (wifiExpanded && wifiNetworks.length === 0 && !wifiScan.running)
            wifiScan.running = true
    }

    function toggleBluetoothList(): void {
        bluetoothExpanded = !bluetoothExpanded
        wifiExpanded = false
        if (bluetoothExpanded && bluetoothDevices.length === 0 && !bluetoothScan.running)
            bluetoothScan.running = true
    }

    function indexWifi(entries): void {
        const index = {}
        entries.forEach((name, position) => index[name] = position)
        wifiNetworkIndex = index
        wifiNetworks = entries
    }

    function indexBluetooth(entries): void {
        const index = {}
        entries.forEach((device, position) => index[device.address] = position)
        bluetoothDeviceIndex = index
        bluetoothDevices = entries
    }

    function toggleWifi(): void {
        runControl(wifiEnabled ? "rfkill block wifi" : "rfkill unblock wifi")
        wifiEnabled = !wifiEnabled
        delayedStatusRefresh.restart()
    }

    function toggleBluetooth(): void {
        runControl(bluetoothEnabled ? "bluetoothctl power off" : "bluetoothctl power on")
        bluetoothEnabled = !bluetoothEnabled
        delayedStatusRefresh.restart()
    }

    function setBrightness(level): void {
        if (!brightnessAvailable)
            return
        brightnessLevel = Math.max(0.05, Math.min(1, level))
        brightnessWriteTimer.restart()
    }

    function setVolume(level): void {
        volumeLevel = Math.max(0, Math.min(1, level))
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@",
                                Math.round(volumeLevel * 100) + "%"])
    }

    function toggleOutputList(): void {
        outputExpanded = !outputExpanded
        if (outputExpanded && !audioOutputScan.running)
            audioOutputScan.running = true
    }

    function selectAudioOutput(name): void {
        Quickshell.execDetached(["bash", "-lc",
            "pactl set-default-sink \"$1\"; pactl list short sink-inputs | cut -f1 | while read -r id; do pactl move-sink-input \"$id\" \"$1\"; done",
            "select-output", name])
        defaultAudioOutput = name
        outputExpanded = false
        delayedOutputRefresh.restart()
    }

    readonly property color background: "#ad242527"
    readonly property color surface: "#33ffffff"
    readonly property color text: "#f2f2f4"
    readonly property color muted: "#aeb0b4"
    readonly property color accent: "#dedfe2"
    readonly property color activeText: "#242527"
    readonly property color urgent: "#ff6961"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FileView {
        id: worldClockSettings
        path: Quickshell.env("HOME") + "/.config/quickshell/world-clocks.json"
        preload: true
        watchChanges: true
        atomicWrites: true

        function loadSettings(): void {
            try {
                const parsed = JSON.parse(text())
                if (parsed.clocks instanceof Array)
                    root.worldClocks = parsed.clocks.filter(entry => entry.label && entry.timezone)
            } catch (error) {
                console.warn("Could not load world clocks:", error)
            }
        }

        onLoaded: loadSettings()
        onFileChanged: reload()
    }

    Process {
        id: timezoneScan
        running: true
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: {
                const zones = text.trim().split("\n").filter(zone => zone.length > 0)
                root.availableWorldClocks = zones.map(zone => {
                    const parts = zone.split("/")
                    return {
                        label: parts[parts.length - 1].split("_").join(" "),
                        timezone: zone
                    }
                })
            }
        }
    }

    Process {
        id: worldClockRefresh
        command: ["bash", "-lc", root.worldClockCommand()]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = []
                text.trim().split("\n").filter(line => line.length > 0).forEach(line => {
                    const parts = line.split("|")
                    values[parseInt(parts[0])] = { time: parts[1], date: parts.slice(2).join("|") }
                })
                root.worldClockValues = values
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!worldClockRefresh.running) worldClockRefresh.running = true
    }

    ClaudeUsage {
        id: claudeUsage
    }

    Process {
        id: codexUsageRefresh
        command: ["bash", "-lc", "/usr/bin/codexbar usage --provider codex --format json --no-color"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parseCodexUsage(text.trim())
        }
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: if (!codexUsageRefresh.running) codexUsageRefresh.running = true
    }

    Process {
        id: wifiScan
        command: ["bash", "-lc", "iwctl station wlan0 scan; sleep 1; iwctl station wlan0 get-networks | sed -E 's/\\x1B\\[[0-9;]*[mK]//g' | tail -n +5 | sed -E 's/^[[:space:]>]+//' | awk '{for(i=1;i<=NF;i++) if ($i==\"psk\" || $i==\"open\" || $i==\"8021x\") {name=$1; for(j=2;j<i;j++) name=name \" \" $j; print name; break}}' | head -6"]
        stdout: StdioCollector {
            onStreamFinished: root.indexWifi(text.trim()
                ? text.trim().split("\n").filter(name => name.length > 0) : [])
        }
    }

    Process {
        id: bluetoothScan
        command: ["bash", "-lc", "bluetoothctl devices | sed 's/^Device //' | head -6"]
        stdout: StdioCollector {
            onStreamFinished: root.indexBluetooth(text.trim()
                ? text.trim().split("\n").map(line => ({ address: line.substring(0, 17), name: line.substring(18) })) : [])
        }
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!wifiScan.running) wifiScan.running = true
            if (!bluetoothScan.running) bluetoothScan.running = true
            if (!audioOutputScan.running) audioOutputScan.running = true
        }
    }

    Process {
        id: wifiStatus
        command: ["bash", "-lc", "if rfkill list wifi | grep -q 'Soft blocked: no'; then enabled=1; else enabled=0; fi; name=$(iwctl station wlan0 show 2>/dev/null | sed -E 's/\\x1B\\[[0-9;]*[mK]//g' | sed -n 's/^[[:space:]]*Connected network[[:space:]]*//p' | sed 's/[[:space:]]*$//'); printf '%s|%s' \"$enabled\" \"$name\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                root.wifiEnabled = parts[0] === "1"
                root.wifiConnectedName = parts.slice(1).join("|")
            }
        }
    }

    Process {
        id: bluetoothStatus
        command: ["bash", "-lc", "if bluetoothctl show | grep -q 'Powered: yes'; then enabled=1; else enabled=0; fi; name=$(bluetoothctl devices Connected | head -1 | cut -d' ' -f3-); printf '%s|%s' \"$enabled\" \"$name\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                root.bluetoothEnabled = parts[0] === "1"
                root.bluetoothConnectedName = parts.slice(1).join("|")
            }
        }
    }

    Process {
        id: volumeStatus
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseFloat(text.trim())
                if (!isNaN(value)) root.volumeLevel = Math.max(0, Math.min(1, value))
            }
        }
    }

    Process {
        id: brightnessStatus
        command: ["bash", "-lc", "value=$(brightnessctl --class=backlight -m 2>/dev/null | head -1 | awk -F, '{gsub(/%/,\"\",$4); print $4}'); if [ -n \"$value\" ]; then printf '%s' \"$value\"; else ddcutil getvcp 10 --terse 2>/dev/null | awk '$1==\"VCP\" && $2==\"10\" {print ($4/$5)*100}'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseFloat(text.trim())
                root.brightnessAvailable = !isNaN(value)
                if (!isNaN(value)) root.brightnessLevel = Math.max(0, Math.min(1, value / 100))
            }
        }
    }

    Process {
        id: audioOutputScan
        command: ["bash", "-lc", "default=$(pactl get-default-sink); printf '%s\\n' \"$default\"; pactl -f json list sinks | jq -r '.[] | [.name,.description] | @tsv'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.defaultAudioOutput = lines.shift() || ""
                root.audioOutputs = lines.filter(line => line.length > 0).map(line => {
                    const split = line.indexOf("\t")
                    return { name: line.substring(0, split), description: line.substring(split + 1) }
                })
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!wifiStatus.running) wifiStatus.running = true
            if (!bluetoothStatus.running) bluetoothStatus.running = true
            if (!volumeStatus.running) volumeStatus.running = true
            if (!brightnessStatus.running) brightnessStatus.running = true
        }
    }

    Timer {
        id: delayedStatusRefresh
        interval: 650
        onTriggered: {
            if (!wifiStatus.running) wifiStatus.running = true
            if (!bluetoothStatus.running) bluetoothStatus.running = true
        }
    }

    Timer {
        id: delayedOutputRefresh
        interval: 650
        onTriggered: if (!audioOutputScan.running) audioOutputScan.running = true
    }

    Timer {
        id: brightnessWriteTimer
        interval: 90
        onTriggered: root.runControl(
            "if brightnessctl --class=backlight --list >/dev/null 2>&1; then brightnessctl --class=backlight set "
            + Math.round(root.brightnessLevel * 100) + "% >/dev/null; else ddcutil setvcp 10 "
            + Math.round(root.brightnessLevel * 100) + " >/dev/null; fi")
    }

    IpcHandler {
        target: "overview"

        function toggle(): void { root.toggleOverview(null) }
        function open(): void { root.openOverview(null) }
        function close(): void { root.closeOverview() }
        function activate(name: string): void {
            root.activateWorkspace(Hyprland.workspaces.values.find(workspace =>
                workspace.name === name) ?? null)
        }
    }

    IpcHandler {
        target: "windowSwitcher"

        function next(): void { root.cycleWindowSwitcher(false) }
        function previous(): void { root.cycleWindowSwitcher(true) }
        function accept(): void { root.acceptWindowSwitcher() }
        function close(): void { root.closeWindowSwitcher() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: controlCenterDismiss
            required property var modelData
            screen: modelData
            visible: root.controlCenterOpen
                     && modelData.name === root.controlCenterScreenName
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-control-center-dismiss"

            mask: Region {
                width: controlCenterDismiss.width
                height: controlCenterDismiss.height

                Region {
                    x: controlCenterDismiss.width - 321
                    y: 38
                    width: 311
                    height: 520
                    intersection: Intersection.Subtract
                }
            }

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.controlCenterOpen = false
                    root.wifiExpanded = false
                    root.bluetoothExpanded = false
                    root.outputExpanded = false
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: clockCenterDismiss
            required property var modelData
            screen: modelData
            visible: root.clockCenterOpen
                     && modelData.name === root.clockCenterScreenName
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-clock-center-dismiss"

            mask: Region {
                width: clockCenterDismiss.width
                height: clockCenterDismiss.height

                Region {
                    x: clockCenterDismiss.width - 370
                    y: 38
                    width: 360
                    height: 700
                    intersection: Intersection.Subtract
                }
            }

            anchors { top: true; right: true; bottom: true; left: true }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.clockCenterOpen = false
                    root.clockPickerOpen = false
                    root.worldClockEditing = false
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 28
            color: "transparent"
            WlrLayershell.namespace: "quickshell"

            Rectangle {
                anchors.fill: parent
                color: root.background

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 20
                        radius: 6
                        color: overviewMouse.containsMouse || root.overviewOpen
                               ? root.surface : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "▦"
                            color: root.overviewOpen ? root.accent : root.text
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: overviewMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleOverview(bar.screen)
                        }
                    }

                    Row {
                        spacing: 4

                        Repeater {
                            model: ScriptModel {
                                values: Hyprland.workspaces.values.filter(workspace =>
                                    workspace.id > 0 && workspace.monitor === Hyprland.monitorFor(bar.screen))
                            }

                            Rectangle {
                                required property var modelData
                                width: 24
                                height: 20
                                radius: 6
                                color: modelData.active ? root.accent
                                      : workspaceMouse.containsMouse ? root.surface
                                      : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: modelData.active ? root.activeText
                                         : modelData.urgent ? root.urgent
                                         : root.text
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 12
                                    font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    id: workspaceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activateWorkspace(modelData)
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        text: Hyprland.activeToplevel?.title ?? "Desktop"
                        color: root.muted
                        elide: Text.ElideRight
                        font.family: "SF Pro Text"
                        font.pixelSize: 12
                    }

                    Row {
                        spacing: 3

                        Repeater {
                            model: SystemTray.items

                            Rectangle {
                                id: trayItem
                                required property SystemTrayItem modelData
                                width: 22
                                height: 22
                                radius: 6
                                color: trayMouse.containsMouse ? root.surface : "transparent"

                                IconImage {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: trayItem.modelData.icon
                                    asynchronous: true
                                }

                                QsMenuOpener {
                                    id: trayMenuModel
                                    menu: trayItem.modelData.menu
                                }

                                PopupWindow {
                                    id: trayMenu
                                    anchor.window: bar
                                    anchor.item: trayItem
                                    anchor.rect.x: trayItem.width - width
                                    anchor.rect.y: trayItem.height + 3
                                    implicitWidth: 220
                                    implicitHeight: trayMenuColumn.implicitHeight + 12
                                    visible: false
                                    color: "transparent"
                                    grabFocus: true

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: "#ed242527"
                                        border.width: 1
                                        border.color: "#35ffffff"

                                        Column {
                                            id: trayMenuColumn
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 6

                                            Repeater {
                                                model: trayMenuModel.children

                                                Item {
                                                    id: menuEntry
                                                    required property QsMenuEntry modelData
                                                    width: trayMenuColumn.width
                                                    height: modelData.isSeparator ? 9 : 32

                                                    Rectangle {
                                                        visible: menuEntry.modelData.isSeparator
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.leftMargin: 6
                                                        anchors.rightMargin: 6
                                                        height: 1
                                                        color: "#28ffffff"
                                                    }

                                                    Rectangle {
                                                        visible: !menuEntry.modelData.isSeparator
                                                        anchors.fill: parent
                                                        radius: 7
                                                        color: menuEntryMouse.containsMouse
                                                               ? root.surface : "transparent"

                                                        RowLayout {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 8
                                                            anchors.rightMargin: 8
                                                            spacing: 8

                                                            IconImage {
                                                                visible: menuEntry.modelData.icon !== ""
                                                                Layout.preferredWidth: 16
                                                                Layout.preferredHeight: 16
                                                                source: menuEntry.modelData.icon
                                                            }

                                                            Text {
                                                                Layout.fillWidth: true
                                                                text: menuEntry.modelData.text
                                                                color: menuEntry.modelData.enabled
                                                                       ? root.text : root.muted
                                                                elide: Text.ElideRight
                                                                font.family: "SF Pro Text"
                                                                font.pixelSize: 12
                                                            }

                                                            Text {
                                                                visible: menuEntry.modelData.buttonType
                                                                         !== QsMenuButtonType.None
                                                                text: menuEntry.modelData.checkState === Qt.Checked
                                                                      ? "✓" : ""
                                                                color: root.accent
                                                                font.pixelSize: 12
                                                            }

                                                            Text {
                                                                visible: menuEntry.modelData.hasChildren
                                                                text: "›"
                                                                color: root.muted
                                                                font.pixelSize: 15
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: menuEntryMouse
                                                            anchors.fill: parent
                                                            enabled: menuEntry.modelData.enabled
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (menuEntry.modelData.hasChildren)
                                                                    menuEntry.modelData.display(trayMenu,
                                                                        trayMenu.width, menuEntry.y)
                                                                else {
                                                                    menuEntry.modelData.triggered()
                                                                    trayMenu.visible = false
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: trayMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                                            trayMenu.visible = !trayMenu.visible
                                        else if (mouse.button === Qt.MiddleButton)
                                            trayItem.modelData.secondaryActivate()
                                        else if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu)
                                            trayMenu.visible = !trayMenu.visible
                                        else
                                            trayItem.modelData.activate()
                                    }

                                    onWheel: wheel => trayItem.modelData.scroll(
                                        wheel.angleDelta.y || wheel.angleDelta.x,
                                        wheel.angleDelta.x !== 0)
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: codexUsageItem
                        visible: root.usageProvider === "codex"
                        // Keep the hit area in place when switching providers.
                        implicitWidth: Math.max(codexUsageText.implicitWidth, claudeUsageText.implicitWidth) + 16
                        implicitHeight: 22
                        radius: 7
                        color: codexUsageMouse.containsMouse ? root.surface : "transparent"

                        Text {
                            id: codexUsageText
                            anchors.centerIn: parent
                            text: root.codexUsageLabel
                            color: root.codexUsageColor
                            font.family: "SF Pro Text"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: codexUsageMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onWheel: wheel => root.scrollUsageProvider(wheel)
                            onClicked: {
                                if (!codexUsageRefresh.running)
                                    codexUsageRefresh.running = true
                                root.codexUsageOpen = !root.codexUsageOpen
                            }
                        }

                        PopupWindow {
                            id: codexUsagePopup
                            anchor.window: bar
                            anchor.item: codexUsageItem
                            anchor.rect.x: codexUsageItem.width - width
                            anchor.rect.y: codexUsageItem.height + 3
                            implicitWidth: 340
                            implicitHeight: codexUsageColumn.implicitHeight + 28
                            visible: codexUsageItem.visible && root.codexUsageOpen
                            color: "transparent"
                            grabFocus: true

                            Rectangle {
                                id: codexUsageCard
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 12
                                color: "#ed242527"
                                border.width: 1
                                border.color: "#35ffffff"

                                Column {
                                    id: codexUsageColumn
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 14
                                    spacing: 10

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Text {
                                            text: "Codex"
                                            color: root.text
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 20
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width - 100
                                            text: root.codexUsageStatus === "ok" ? "Updated just now" : "Unavailable"
                                            horizontalAlignment: Text.AlignRight
                                            color: root.muted
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#28ffffff"
                                    }

                                    Text {
                                        text: "Weekly"
                                        color: root.text
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 17
                                        font.weight: Font.Medium
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 8
                                        radius: 4
                                        color: "#30ffffff"

                                        Rectangle {
                                            width: root.codexUsageStatus === "ok"
                                                   ? parent.width * Math.max(0, Math.min(1, 1 - root.codexUsageLeft))
                                                   : 0
                                            height: parent.height
                                            radius: 4
                                            color: root.codexUsageStatus === "ok" ? "#d19a66" : root.urgent
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        Text {
                                            text: root.codexUsageStatus === "ok"
                                                  ? Math.round((1 - root.codexUsageLeft) * 100) + "% used"
                                                  : "Unavailable"
                                            color: root.text
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            width: parent.width - 90
                                            text: root.codexUsageStatus === "ok"
                                                  ? root.codexUsageTooltip.replace("Codex weekly quota: ", "").replace(" · ", "  ·  ")
                                                  : "Check codexbar-cli or Codex login"
                                            horizontalAlignment: Text.AlignRight
                                            color: root.muted
                                            elide: Text.ElideRight
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.codexUsagePaceText
                                        color: root.muted
                                        wrapMode: Text.Wrap
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        width: parent.width
                                        visible: root.codexUsagePlan.length > 0 || root.codexUsageCredits.length > 0
                                        text: (root.codexUsagePlan.length > 0 ? "Plan: " + root.codexUsagePlan : "")
                                              + (root.codexUsageCredits.length > 0 ? "  ·  Credits: " + root.codexUsageCredits : "")
                                        color: root.muted
                                        wrapMode: Text.Wrap
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 10
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#28ffffff"
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Rectangle {
                                            width: (parent.width - 8) / 2
                                            height: 32
                                            radius: 7
                                            color: refreshUsageMouse.containsMouse ? root.surface : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "↻  Refresh"
                                                color: root.text
                                                font.family: "SF Pro Text"
                                                font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: refreshUsageMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!codexUsageRefresh.running)
                                                        codexUsageRefresh.running = true
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - 8) / 2
                                            height: 32
                                            radius: 7
                                            color: dashboardMouse.containsMouse ? root.surface : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "⌁  Dashboard"
                                                color: root.text
                                                font.family: "SF Pro Text"
                                                font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: dashboardMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.runControl("xdg-open https://chatgpt.com/codex/settings/usage")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: claudeUsageItem
                        property bool open: false
                        visible: root.usageProvider === "claude"
                        onVisibleChanged: if (!visible) open = false
                        readonly property color usageColor: claudeUsage.status !== "ok"
                                                            ? root.urgent
                                                            : claudeUsage.remaining < 0.2
                                                              ? root.urgent
                                                              : claudeUsage.remaining < 0.5
                                                                ? "#e5c07b" : "#98c379"
                        implicitWidth: Math.max(codexUsageText.implicitWidth, claudeUsageText.implicitWidth) + 16
                        implicitHeight: 22
                        radius: 7
                        color: claudeUsageMouse.containsMouse || open ? root.surface : "transparent"

                        Text {
                            id: claudeUsageText
                            anchors.centerIn: parent
                            text: claudeUsage.label
                            color: claudeUsageItem.usageColor
                            font.family: "SF Pro Text"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        Connections {
                            target: root
                            function onCodexUsageOpenChanged() {
                                if (root.codexUsageOpen)
                                    claudeUsageItem.open = false
                            }
                        }

                        MouseArea {
                            id: claudeUsageMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onWheel: wheel => root.scrollUsageProvider(wheel)
                            onClicked: {
                                root.codexUsageOpen = false
                                claudeUsageItem.open = !claudeUsageItem.open
                                if (claudeUsageItem.open)
                                    claudeUsage.refresh()
                            }
                        }

                        PopupWindow {
                            anchor.window: bar
                            anchor.item: claudeUsageItem
                            anchor.rect.x: claudeUsageItem.width - width
                            anchor.rect.y: claudeUsageItem.height + 3
                            implicitWidth: 340
                            implicitHeight: claudeUsageColumn.implicitHeight + 28
                            visible: claudeUsageItem.visible && claudeUsageItem.open
                            color: "transparent"
                            grabFocus: true

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 12
                                color: "#ed242527"
                                border.width: 1
                                border.color: "#35ffffff"
                                focus: true
                                Keys.onEscapePressed: claudeUsageItem.open = false

                                Column {
                                    id: claudeUsageColumn
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 14
                                    spacing: 10

                                    RowLayout {
                                        width: parent.width
                                        Text {
                                            text: "Claude"
                                            color: root.text
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 20
                                            font.weight: Font.DemiBold
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: claudeUsage.updateLabel
                                            horizontalAlignment: Text.AlignRight
                                            color: root.muted
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#28ffffff"
                                    }

                                    Text {
                                        width: parent.width
                                        visible: claudeUsage.status !== "ok"
                                        text: claudeUsage.refreshing ? "Loading Claude usage…"
                                              : "Usage unavailable. Check your connection and Claude Code login, then refresh."
                                        color: root.muted
                                        wrapMode: Text.Wrap
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 12
                                    }

                                    Repeater {
                                        model: claudeUsage.windows

                                        Column {
                                            id: claudeWindow
                                            required property var modelData
                                            width: claudeUsageColumn.width
                                            spacing: 8

                                            Text {
                                                text: claudeWindow.modelData.label
                                                color: root.text
                                                font.family: "SF Pro Text"
                                                font.pixelSize: 17
                                                font.weight: Font.Medium
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 8
                                                radius: 4
                                                color: "#30ffffff"

                                                Rectangle {
                                                    width: parent.width * (1 - claudeWindow.modelData.left)
                                                    height: parent.height
                                                    radius: 4
                                                    color: claudeWindow.modelData.left < 0.2 ? root.urgent : "#d19a66"
                                                }
                                            }

                                            RowLayout {
                                                width: parent.width
                                                Text {
                                                    text: Math.round((1 - claudeWindow.modelData.left) * 100) + "% used"
                                                    color: root.text
                                                    font.family: "SF Pro Text"
                                                    font.pixelSize: 13
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: Math.round(claudeWindow.modelData.left * 100) + "% remaining"
                                                    horizontalAlignment: Text.AlignRight
                                                    color: root.muted
                                                    font.family: "SF Pro Text"
                                                    font.pixelSize: 12
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                text: claudeUsage.resetLabel(claudeWindow.modelData)
                                                color: root.muted
                                                wrapMode: Text.Wrap
                                                font.family: "SF Pro Text"
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                width: parent.width
                                                visible: claudeWindow.modelData.pace.length > 0
                                                text: "Pace: " + claudeWindow.modelData.pace
                                                color: root.muted
                                                wrapMode: Text.Wrap
                                                font.family: "SF Pro Text"
                                                font.pixelSize: 12
                                            }
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        visible: claudeUsage.plan.length > 0
                                        text: "Plan: " + claudeUsage.plan
                                        color: root.muted
                                        wrapMode: Text.Wrap
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 10
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#28ffffff"
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Repeater {
                                            model: ["↻  Refresh", "⌁  Dashboard"]
                                            Rectangle {
                                                id: claudeAction
                                                required property int index
                                                required property string modelData
                                                width: (claudeUsageColumn.width - 8) / 2
                                                height: 32
                                                radius: 7
                                                color: claudeActionMouse.containsMouse ? root.surface : "transparent"
                                                opacity: index === 0 && claudeUsage.refreshing ? 0.5 : 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: claudeAction.modelData
                                                    color: root.text
                                                    font.family: "SF Pro Text"
                                                    font.pixelSize: 12
                                                }

                                                MouseArea {
                                                    id: claudeActionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: claudeAction.index !== 0 || !claudeUsage.refreshing
                                                    onClicked: {
                                                        if (claudeAction.index === 0) {
                                                            claudeUsage.refresh()
                                                        } else {
                                                            claudeUsageItem.open = false
                                                            Quickshell.execDetached(["xdg-open", "https://claude.ai/settings/usage"])
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 22
                        radius: 7
                        color: controlCenterMouse.containsMouse || root.controlCenterOpen
                               ? root.surface : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "≡"
                            color: root.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: controlCenterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleControlCenter(bar.screen)
                        }
                    }

                    Rectangle {
                        implicitWidth: timeText.implicitWidth + 16
                        implicitHeight: 22
                        radius: 7
                        color: clockMouse.containsMouse || root.clockCenterOpen
                               ? root.surface : "transparent"

                        Text {
                            id: timeText
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.date, "ddd, d MMM  HH:mm")
                            color: root.text
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: clockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleClockCenter(bar.screen)
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: clockCenter
            required property var modelData
            screen: modelData
            visible: root.clockCenterOpen
                     && modelData.name === root.clockCenterScreenName
            implicitWidth: 360
            implicitHeight: 700
            color: "transparent"
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-clock-center"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors { top: true; right: true }
            margins { top: 38; right: 10 }

            Rectangle {
                anchors.fill: parent
                radius: 28
                color: "#e6242527"
                border.width: 1
                border.color: "#35ffffff"
                clip: true
                transformOrigin: Item.TopRight
                scale: root.clockCenterOpen ? 1 : 0.72
                opacity: root.clockCenterOpen ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                }

                Keys.onEscapePressed: root.clockCenterOpen = false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52

                        ColumnLayout {
                            spacing: -2
                            Text {
                                text: Qt.formatDateTime(clock.date, "HH:mm")
                                color: root.text
                                font.family: "SF Pro Display"
                                font.pixelSize: 28
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                                color: root.muted
                                font.family: "SF Pro Text"
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: calendarTodayMouse.containsMouse ? root.surface : "transparent"
                            Text { anchors.centerIn: parent; text: "●"; color: root.text; font.pixelSize: 9 }
                            MouseArea {
                                id: calendarTodayMouse
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.calendarYear = clock.date.getFullYear()
                                    root.calendarMonth = clock.date.getMonth()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 278
                        radius: 22
                        color: "#1a808080"
                        border.width: 1
                        border.color: "#25ffffff"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 7

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                Text {
                                    Layout.fillWidth: true
                                    text: Qt.formatDateTime(new Date(root.calendarYear,
                                                                     root.calendarMonth, 1),
                                                            "MMMM yyyy")
                                    color: root.text
                                    font.family: "SF Pro Display"
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }

                                Repeater {
                                    model: [ { glyph: "‹", delta: -1 }, { glyph: "›", delta: 1 } ]
                                    Rectangle {
                                        required property var modelData
                                        width: 30; height: 30; radius: 15
                                        color: monthNavMouse.containsMouse ? root.surface : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.glyph
                                            color: root.text
                                            font.pixelSize: 20
                                        }
                                        MouseArea {
                                            id: monthNavMouse
                                            anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.changeCalendarMonth(modelData.delta)
                                        }
                                    }
                                }
                            }

                            Grid {
                                Layout.fillWidth: true
                                columns: 7
                                columnSpacing: 4
                                Repeater {
                                    model: ["M", "T", "W", "T", "F", "S", "S"]
                                    Text {
                                        required property string modelData
                                        width: 40; height: 20
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                        color: root.muted
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Grid {
                                id: calendarGrid
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 7
                                columnSpacing: 4
                                rowSpacing: 2

                                Repeater {
                                    model: root.calendarCells()
                                    Rectangle {
                                        required property var modelData
                                        width: 40; height: 28; radius: 14
                                        color: modelData.today ? root.accent : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            color: modelData.today ? root.activeText
                                                   : modelData.currentMonth ? root.text : "#65676d"
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 11
                                            font.weight: modelData.today ? Font.DemiBold : Font.Normal
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "World Clocks"
                            color: root.text
                            font.family: "SF Pro Display"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: addClockLabel.implicitWidth + 18
                            implicitHeight: 26
                            radius: 13
                            color: addClockMouse.containsMouse ? root.surface : "#20808080"
                            Text {
                                id: addClockLabel
                                anchors.centerIn: parent
                                text: "+ Add"
                                color: root.text
                                font.family: "SF Pro Text"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                id: addClockMouse
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockSearch = ""
                                    root.clockPickerOpen = true
                                    root.worldClockEditing = false
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: editClockLabel.implicitWidth + 18
                            implicitHeight: 26
                            radius: 13
                            color: root.worldClockEditing ? root.accent
                                  : editClockMouse.containsMouse ? root.surface : "transparent"
                            Text {
                                id: editClockLabel
                                anchors.centerIn: parent
                                text: root.worldClockEditing ? "Done" : "Edit"
                                color: root.worldClockEditing ? root.activeText : root.muted
                                font.family: "SF Pro Text"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                id: editClockMouse
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockPickerOpen = false
                                    root.worldClockEditing = !root.worldClockEditing
                                }
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: worldClockGrid.implicitHeight
                        clip: true

                        GridLayout {
                            id: worldClockGrid
                            width: parent.width
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: root.worldClocks
                                Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 17
                                color: "#1a808080"
                                border.width: 1
                                border.color: "#20ffffff"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 11
                                    spacing: 0
                                    Text {
                                        text: root.worldClockValues[index]?.time || "--:--"
                                        color: root.text
                                        font.family: "SF Pro Display"
                                        font.pixelSize: 20
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        color: root.text
                                        elide: Text.ElideRight
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.worldClockValues[index]?.date || modelData.timezone
                                        color: root.muted
                                        elide: Text.ElideRight
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 9
                                    }
                                }

                                Rectangle {
                                    visible: root.worldClockEditing
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 7
                                    width: 22; height: 22; radius: 11
                                    color: removeClockMouse.containsMouse ? "#ccff6961" : "#80ff6961"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: "white"
                                        font.pixelSize: 14
                                    }
                                    MouseArea {
                                        id: removeClockMouse
                                        anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.removeWorldClock(index)
                                    }
                                }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.clockPickerOpen
                    anchors.fill: parent
                    anchors.margins: 18
                    radius: 22
                    color: "#f2242527"
                    border.width: 1
                    border.color: "#40ffffff"
                    z: 20

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Add World Clock"
                                color: root.text
                                font.family: "SF Pro Display"
                                font.pixelSize: 19
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 30; height: 30; radius: 15
                                color: closePickerMouse.containsMouse ? root.surface : "transparent"
                                Text { anchors.centerIn: parent; text: "×"; color: root.text; font.pixelSize: 18 }
                                MouseArea {
                                    id: closePickerMouse
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.clockPickerOpen = false
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 14
                            color: "#25808080"
                            border.width: clockSearchInput.activeFocus ? 1 : 0
                            border.color: root.accent
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                visible: clockSearchInput.text.length === 0
                                text: "Search cities or time zones"
                                color: root.muted
                                font.family: "SF Pro Text"
                                font.pixelSize: 11
                            }
                            TextInput {
                                id: clockSearchInput
                                anchors.fill: parent
                                anchors.leftMargin: 13
                                anchors.rightMargin: 13
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.clockSearch
                                color: root.text
                                selectionColor: root.accent
                                selectedTextColor: root.activeText
                                font.family: "SF Pro Text"
                                font.pixelSize: 12
                                onTextChanged: root.clockSearch = text
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: clockSearchInput.forceActiveFocus()
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: timezoneList.implicitHeight
                            clip: true

                            Column {
                                id: timezoneList
                                width: parent.width
                                spacing: 5

                                Repeater {
                                    model: root.availableWorldClocks.filter(entry => {
                                        const query = root.clockSearch.toLowerCase()
                                        return query.length === 0
                                               || entry.label.toLowerCase().includes(query)
                                               || entry.timezone.toLowerCase().includes(query)
                                    })

                                    Rectangle {
                                        required property var modelData
                                        width: timezoneList.width
                                        height: 48
                                        radius: 14
                                        readonly property bool added: root.worldClocks.some(
                                            entry => entry.timezone === modelData.timezone)
                                        color: timezoneMouse.containsMouse ? root.surface : "#14808080"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 13
                                            anchors.rightMargin: 13
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: -1
                                                Text {
                                                    text: modelData.label
                                                    color: root.text
                                                    font.family: "SF Pro Text"
                                                    font.pixelSize: 12
                                                    font.weight: Font.Medium
                                                }
                                                Text {
                                                    text: modelData.timezone
                                                    color: root.muted
                                                    font.family: "SF Pro Text"
                                                    font.pixelSize: 9
                                                }
                                            }
                                            Text {
                                                text: parent.parent.added ? "Added" : "+"
                                                color: parent.parent.added ? root.muted : root.text
                                                font.family: "SF Pro Text"
                                                font.pixelSize: parent.parent.added ? 10 : 18
                                            }
                                        }

                                        MouseArea {
                                            id: timezoneMouse
                                            anchors.fill: parent
                                            enabled: !parent.added
                                            hoverEnabled: true
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: root.addWorldClock(parent.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: controlCenter
            required property var modelData
            screen: modelData
            visible: root.controlCenterOpen
                     && modelData.name === root.controlCenterScreenName
            implicitWidth: 311
            implicitHeight: 520
            color: "transparent"
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-control-center"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            onVisibleChanged: {
                if (visible)
                    requestActivate()
            }

            anchors {
                top: true
                right: true
            }

            margins {
                top: 38
                right: 10
            }

            Item {
                anchors.fill: parent
                transformOrigin: Item.TopRight
                scale: root.controlCenterOpen ? 1 : 0.72
                opacity: root.controlCenterOpen ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                }

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    onClicked: {
                        root.controlCenterOpen = false
                        root.wifiExpanded = false
                        root.bluetoothExpanded = false
                    }
                }

                Item {
                    width: 160
                    height: parent.height
                    anchors.left: parent.left
                    anchors.top: parent.top
                    z: 2
                    opacity: root.connectivityDetailsOpen ? 0 : 1
                    enabled: !root.connectivityDetailsOpen
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

                    Rectangle {
                    width: parent.width
                    height: implicitHeight
                    x: 0
                    y: 0
                    implicitHeight: 68
                    radius: 34
                    color: "#1a808080"
                    border.width: 1
                    border.color: "#25ffffff"
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 5
                        RowLayout {
                            Layout.fillWidth: true; implicitHeight: 52; spacing: 8
                            Rectangle {
                                width: 52; height: 52; radius: 26
                                color: root.wifiEnabled ? "#d8e2e3e6"
                                      : wifiSwitchMouse.containsMouse ? "#50ffffff" : "#28ffffff"
                                Text { anchors.centerIn: parent; text: "⌁"; color: root.wifiEnabled ? root.activeText : root.muted; font.pixelSize: 27 }
                                MouseArea {
                                    id: wifiSwitchMouse; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleWifi()
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Wi‑Fi"; color: root.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                                Text { Layout.maximumWidth: 81; text: root.wifiSubtitle; color: root.muted; elide: Text.ElideRight; font.pixelSize: 10 }
                            }
                            Item { Layout.fillWidth: true }
                            MouseArea { anchors.fill: parent; anchors.leftMargin: 46; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleWifiList() }
                        }
                        Repeater {
                            model: []
                            Rectangle {
                                required property string modelData
                                Layout.fillWidth: true; implicitHeight: 30; radius: 15
                                color: wifiNetworkMouse.containsMouse ? "#35ffffff" : "transparent"
                                Text { anchors.fill: parent; anchors.leftMargin: 12; verticalAlignment: Text.AlignVCenter; text: modelData; color: root.text; elide: Text.ElideRight; font.pixelSize: 12 }
                                MouseArea { id: wifiNetworkMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["iwctl", "station", "wlan0", "connect", modelData]) }
                            }
                        }
                    }
                }

                    Rectangle {
                    width: parent.width
                    height: implicitHeight
                    x: 0
                    y: 78
                    implicitHeight: 68
                    radius: 34
                    color: "#1a808080"
                    border.width: 1
                    border.color: "#25ffffff"
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 5
                        RowLayout {
                            Layout.fillWidth: true; implicitHeight: 52; spacing: 8
                            Rectangle {
                                width: 52; height: 52; radius: 26
                                color: root.bluetoothEnabled ? "#d8e2e3e6"
                                      : bluetoothSwitchMouse.containsMouse ? "#50ffffff" : "#28ffffff"
                                Text { anchors.centerIn: parent; text: "ᛒ"; color: root.bluetoothEnabled ? root.activeText : root.muted; font.pixelSize: 23 }
                                MouseArea {
                                    id: bluetoothSwitchMouse; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleBluetooth()
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Bluetooth"; color: root.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { Layout.maximumWidth: 81; text: root.bluetoothSubtitle; color: root.muted; elide: Text.ElideRight; font.pixelSize: 10 }
                            }
                            Item { Layout.fillWidth: true }
                            MouseArea { anchors.fill: parent; anchors.leftMargin: 46; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleBluetoothList() }
                        }
                        Repeater {
                            model: []
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 30; radius: 15
                                color: bluetoothDeviceMouse.containsMouse ? "#35ffffff" : "transparent"
                                Text { anchors.fill: parent; anchors.leftMargin: 12; verticalAlignment: Text.AlignVCenter; text: modelData.name; color: root.text; elide: Text.ElideRight; font.pixelSize: 12 }
                                MouseArea { id: bluetoothDeviceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bluetoothctl", "connect", modelData.address]) }
                            }
                        }
                    }
                    }
                }

                Rectangle {
                    width: 140
                    height: 146
                    anchors.top: parent.top
                    anchors.right: parent.right
                    radius: 29
                    color: "#1a808080"
                    border.width: 1
                    border.color: "#25ffffff"
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 140
                            height: 146
                            radius: 29
                        }
                    }
                    z: 1
                    opacity: root.connectivityDetailsOpen ? 0 : 1
                    enabled: !root.connectivityDetailsOpen
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 29
                        color: "#20ffffff"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.mediaPlayer?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: root.mediaPlayer?.trackArtUrl ? "#78000000" : "transparent"
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 3

                            Text {
                            Layout.fillWidth: true
                            text: root.mediaPlayer?.trackTitle || "Nothing playing"
                            color: root.text
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                            Text {
                            Layout.fillWidth: true
                            text: root.mediaPlayer?.trackArtist || "Media"
                            color: root.muted
                            elide: Text.ElideRight
                            font.pixelSize: 11
                        }

                            Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 7

                            Text {
                                text: "‹"
                                color: root.mediaPlayer?.canGoPrevious ? root.text : root.muted
                                font.pixelSize: 20
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mediaPlayer?.canGoPrevious) root.mediaPlayer.previous() }
                            }
                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: mediaPlayMouse.containsMouse ? "#65ffffff" : "#40ffffff"
                                Text {
                                    anchors.centerIn: parent
                                    text: root.mediaPlayer?.isPlaying ? "Ⅱ" : "▶"
                                    color: root.text
                                    font.pixelSize: root.mediaPlayer?.isPlaying ? 12 : 11
                                }
                                MouseArea {
                                    id: mediaPlayMouse; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.mediaPlayer?.canTogglePlaying) root.mediaPlayer.togglePlaying()
                                }
                            }
                            Text {
                                text: "›"
                                color: root.mediaPlayer?.canGoNext ? root.text : root.muted
                                font.pixelSize: 20
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mediaPlayer?.canGoNext) root.mediaPlayer.next() }
                            }
                            }
                        }
                    }
                }

                Rectangle {
                    x: 0; y: 156
                    width: 311; height: 58
                    radius: 20
                    color: "#1a808080"
                    z: 3
                    opacity: root.connectivityDetailsOpen ? 0 : 1
                    enabled: !root.connectivityDetailsOpen
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 10
                        Text { text: "☀"; color: root.text; font.pixelSize: 18 }
                        Rectangle {
                            Layout.fillWidth: true; height: 8; radius: 4; color: "#33808080"
                            Rectangle { width: parent.width * root.brightnessLevel; height: parent.height; radius: 4; color: root.text }
                            Rectangle { x: Math.max(0, parent.width * root.brightnessLevel - 7); anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: root.text }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                                function updateLevel(px): void { root.setBrightness(Math.max(0, Math.min(1, px / width))) }
                                onPressed: mouse => updateLevel(mouse.x)
                                onPositionChanged: mouse => { if (pressed) updateLevel(mouse.x) }
                            }
                        }
                        Text {
                            text: root.brightnessAvailable
                                  ? Math.round(root.brightnessLevel * 100) + "%" : "No display"
                            color: root.muted
                            font.pixelSize: 9
                        }
                    }
                }

                Rectangle {
                    x: 0; y: 224
                    width: 311
                    height: root.outputExpanded ? 70 + root.audioOutputs.length * 42 : 58
                    radius: 20
                    color: "#1a808080"
                    clip: true
                    z: 4
                    opacity: root.connectivityDetailsOpen ? 0 : 1
                    enabled: !root.connectivityDetailsOpen
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }
                    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 6
                        RowLayout {
                            Layout.fillWidth: true; implicitHeight: 38; spacing: 10
                            Text { text: "◖"; color: root.text; font.pixelSize: 18 }
                            Rectangle {
                                Layout.fillWidth: true; height: 8; radius: 4; color: "#33808080"
                                Rectangle { width: parent.width * root.volumeLevel; height: parent.height; radius: 4; color: root.text }
                                Rectangle { x: Math.max(0, parent.width * root.volumeLevel - 7); anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: root.text }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                                    function updateLevel(px): void { root.setVolume(Math.max(0, Math.min(1, px / width))) }
                                    onPressed: mouse => updateLevel(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) updateLevel(mouse.x) }
                                }
                            }
                            Rectangle {
                                width: 112; height: 38; radius: 13
                                color: outputMouse.containsMouse ? "#33808080" : "transparent"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    spacing: 5
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.currentAudioOutputLabel
                                        color: root.text
                                        elide: Text.ElideRight
                                        font.pixelSize: 9
                                    }
                                    Text { text: "›"; color: root.muted; font.pixelSize: 17 }
                                }
                                MouseArea { id: outputMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleOutputList() }
                            }
                        }

                        Repeater {
                            model: root.outputExpanded ? root.audioOutputs : []
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 36; radius: 13
                                color: modelData.name === root.defaultAudioOutput ? "#33808080"
                                      : outputEntryMouse.containsMouse ? "#24808080" : "#1a808080"
                                Text { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; verticalAlignment: Text.AlignVCenter; text: modelData.description; color: root.text; elide: Text.ElideRight; font.pixelSize: 11 }
                                MouseArea { id: outputEntryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAudioOutput(modelData.name) }
                            }
                        }
                    }
                }

                Repeater {
                    model: [
                        { kind: "wifi", label: "Wi‑Fi", icon: "⌁" },
                        { kind: "bluetooth", label: "Bluetooth", icon: "ᛒ" }
                    ]

                    Rectangle {
                        id: detailOverlay
                        required property var modelData
                        readonly property bool expanded: modelData.kind === "wifi"
                                                         ? root.wifiExpanded : root.bluetoothExpanded
                        readonly property var entries: modelData.kind === "wifi"
                                                       ? root.wifiNetworks : root.bluetoothDevices
                        readonly property string connectedName: modelData.kind === "wifi"
                                                                ? root.wifiConnectedName
                                                                : root.bluetoothConnectedName
                        readonly property var connectedEntries: entries.filter(entry =>
                            (typeof entry === "string" ? entry : entry.name) === connectedName)
                        readonly property var discoveredEntries: entries.filter(entry =>
                            (typeof entry === "string" ? entry : entry.name) !== connectedName)
                        x: 0
                        y: expanded ? 0 : (modelData.kind === "wifi" ? 0 : 78)
                        width: expanded ? 311 : 52
                        height: expanded ? 170 + Math.max(1, connectedEntries.length) * 36
                                           + discoveredEntries.length * 47 : 52
                        radius: expanded ? 31 : 26
                        color: "#1a808080"
                        border.width: 1
                        border.color: "#30ffffff"
                        opacity: expanded ? 1 : 0
                        enabled: expanded
                        clip: true
                        z: 10

                        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                        Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8
                            opacity: detailOverlay.expanded ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

                            RowLayout {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                spacing: 9

                                Rectangle {
                                    width: 52; height: 52; radius: 26
                                    color: modelData.kind === "wifi"
                                           ? (root.wifiEnabled ? "#d8e2e3e6" : "#28ffffff")
                                           : (root.bluetoothEnabled ? "#d8e2e3e6" : "#28ffffff")
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        color: modelData.kind === "wifi"
                                               ? (root.wifiEnabled ? root.activeText : root.muted)
                                               : (root.bluetoothEnabled ? root.activeText : root.muted)
                                        font.pixelSize: modelData.kind === "wifi" ? 27 : 23
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.kind === "wifi" ? root.toggleWifi() : root.toggleBluetooth()
                                    }
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Text { text: modelData.label; color: root.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text {
                                        text: modelData.kind === "wifi" ? root.wifiSubtitle : root.bluetoothSubtitle
                                        color: root.muted
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 150
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.leftMargin: 46
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.kind === "wifi"
                                               ? root.toggleWifiList() : root.toggleBluetoothList()
                                }
                            }

                            Text {
                                Layout.leftMargin: 12
                                text: "Connected"
                                color: root.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                visible: detailOverlay.expanded
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 12
                                Layout.preferredHeight: 30
                                verticalAlignment: Text.AlignVCenter
                                text: detailOverlay.connectedName || "Not connected"
                                color: detailOverlay.connectedName ? root.text : root.muted
                                elide: Text.ElideRight
                                font.pixelSize: 12
                                visible: detailOverlay.expanded
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                implicitHeight: 1
                                color: "#28ffffff"
                                visible: detailOverlay.expanded
                            }

                            Text {
                                Layout.leftMargin: 12
                                text: detailOverlay.modelData.kind === "wifi" ? "Available Networks" : "Discovered Devices"
                                color: root.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                visible: detailOverlay.expanded
                            }

                            Repeater {
                                model: detailOverlay.discoveredEntries
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 39
                                    radius: 20
                                    color: detailEntryMouse.containsMouse ? "#33808080" : "#1a808080"
                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        verticalAlignment: Text.AlignVCenter
                                        text: typeof modelData === "string" ? modelData : modelData.name
                                        color: root.text
                                        elide: Text.ElideRight
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: detailEntryMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (detailOverlay.modelData.kind === "wifi")
                                                Quickshell.execDetached(["iwctl", "station", "wlan0", "connect", modelData])
                                            else
                                                Quickshell.execDetached(["bluetoothctl", "connect", modelData.address])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: windowSwitcher
            required property var modelData
            screen: modelData
            visible: root.windowSwitcherOpen
                     && modelData.name === root.windowSwitcherScreenName
            color: "transparent"
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-window-switcher"

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            Rectangle {
                id: windowSwitcherSurface
                anchors.fill: parent
                color: "transparent"
                focus: windowSwitcher.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab) {
                        root.cycleWindowSwitcher((event.modifiers & Qt.ShiftModifier) !== 0)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.acceptWindowSwitcher()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.closeWindowSwitcher()
                        event.accepted = true
                    }
                }

                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L
                            || event.key === Qt.Key_Super_R) {
                        root.acceptWindowSwitcher()
                        event.accepted = true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeWindowSwitcher()
                }

                Rectangle {
                    id: switcherContainer
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 80,
                                    Math.max(300, switcherRow.implicitWidth + 40))
                    height: 226
                    radius: 26
                    color: "#9c242527"
                    border.width: 1
                    border.color: "#38ffffff"

                    Row {
                        id: switcherRow
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: root.windowSwitcherWindows

                            Rectangle {
                                id: switcherCard
                                required property var modelData
                                required property int index
                                width: Math.min(230, Math.max(150,
                                    (windowSwitcher.width - 128) /
                                    Math.max(1, root.windowSwitcherWindows.length)))
                                height: 178
                                radius: 22
                                color: index === root.windowSwitcherIndex
                                       ? "#703b4261" : "#2411111a"
                                border.width: index === root.windowSwitcherIndex ? 3 : 0
                                border.color: index === root.windowSwitcherIndex
                                              ? root.accent : "transparent"
                                scale: index === root.windowSwitcherIndex ? 1.0 : 0.94
                                opacity: index === root.windowSwitcherIndex ? 1.0 : 0.72
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Behavior on opacity { NumberAnimation { duration: 100 } }

                                Item {
                                    id: roundedPreview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 7
                                    height: parent.height - 50
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: roundedPreview.width
                                            height: roundedPreview.height
                                            radius: 16
                                        }
                                    }

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: root.windowSwitcherOpen
                                                       && root.screenIsCaptureable(root.windowSwitcherScreenName)
                                                       && root.toplevelIsCaptureable(switcherCard.modelData)
                                                       ? switcherCard.modelData.wayland : null
                                        live: root.windowSwitcherOpen
                                        paintCursor: false
                                        constraintSize.width: roundedPreview.width
                                        constraintSize.height: roundedPreview.height
                                    }
                                }

                                Item {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 43

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        verticalAlignment: Text.AlignVCenter
                                        text: switcherCard.modelData.title || "Untitled"
                                        color: index === root.windowSwitcherIndex
                                               ? root.text : root.muted
                                        elide: Text.ElideRight
                                        font.family: "SF Pro Text"
                                        font.pixelSize: index === root.windowSwitcherIndex ? 14 : 13
                                        font.weight: index === root.windowSwitcherIndex
                                                     ? Font.DemiBold : Font.Normal
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.windowSwitcherIndex = index
                                    onClicked: mouse => {
                                        mouse.accepted = true
                                        root.windowSwitcherIndex = index
                                        root.acceptWindowSwitcher()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overview
            required property var modelData
            property var focusedWorkspace: null
            readonly property var activeWorkspace: Hyprland.workspaces.values.find(workspace =>
                workspace.id > 0
                && workspace.monitor === Hyprland.monitorFor(overview.screen)
                && workspace.active) ?? null
            screen: modelData
            visible: root.overviewOpen && modelData.name === root.overviewScreenName
            color: "#1a808080"
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"

            onVisibleChanged: {
                if (visible) {
                    focusedWorkspace = activeWorkspace
                }
            }

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            Rectangle {
                id: overviewSurface
                anchors.fill: parent
                color: "transparent"
                focus: overview.visible

                Keys.onEscapePressed: root.closeOverview()

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeOverview()
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 18

                        Rectangle {
                            id: workspaceRail
                            Layout.preferredWidth: 268
                            Layout.fillHeight: true
                            radius: 18
                            color: "transparent"
                            border.width: 0
                            z: 10
                            transform: [
                                Rotation {
                                    origin.x: 0
                                    origin.y: workspaceRail.height / 2
                                    angle: -1.6
                                }
                            ]

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 0

                                ListView {
                                    id: workspaceList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 10
                                    clip: true
                                    model: ScriptModel {
                                        values: Hyprland.workspaces.values.filter(workspace =>
                                            workspace.id > 0
                                            && workspace.monitor === Hyprland.monitorFor(overview.screen))
                                    }

                                    delegate: Rectangle {
                                        id: workspaceCard
                                        required property var modelData
                                        readonly property int windowCount:
                                            modelData.toplevels?.values?.length ?? 0
                                        width: workspaceList.width
                                        height: 148
                                        radius: 15
                                        color: overview.focusedWorkspace === modelData
                                               ? "#b52a4057" : "#7a182336"
                                        border.width: overview.focusedWorkspace === modelData ? 2 : 0
                                        border.color: overview.focusedWorkspace === modelData
                                                      ? root.accent : "transparent"
                                        scale: overview.focusedWorkspace === modelData ? 1.0 : 0.95
                                        opacity: overview.focusedWorkspace === modelData ? 1.0 : 0.78

                                        Behavior on scale { NumberAnimation { duration: 150 } }
                                        Behavior on opacity { NumberAnimation { duration: 150 } }

                                        Item {
                                            id: workspaceThumb
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 7
                                            height: 106
                                            clip: true

                                            Grid {
                                                anchors.fill: parent
                                                anchors.margins: 3
                                                columns: Math.min(2, workspaceCard.windowCount || 1)
                                                columnSpacing: 4
                                                rowSpacing: 4

                                                Repeater {
                                                    model: ScriptModel {
                                                        values: workspaceCard.modelData.toplevels?.values ?? []
                                                    }

                                                    Rectangle {
                                                        required property var modelData
                                                        width: Math.max(64, (workspaceThumb.width - 18
                                                               - Math.min(1, workspaceCard.windowCount - 1) * 4)
                                                               / Math.min(2, workspaceCard.windowCount || 1))
                                                        height: workspaceCard.windowCount > 2 ? 45 : 82
                                                        radius: 6
                                                        color: "#0c111d"
                                                        border.width: 0
                                                        border.color: "transparent"
                                                        clip: true

                                                        ScreencopyView {
                                                            id: workspacePreviewSource
                                                            anchors.fill: parent
                                                            captureSource: root.overviewOpen
                                                                           && root.screenIsCaptureable(root.overviewScreenName)
                                                                           && root.toplevelIsCaptureable(parent.modelData)
                                                                           ? parent.modelData.wayland : null
                                                            live: root.overviewOpen
                                                            paintCursor: false
                                                            constraintSize.width: parent.width
                                                            constraintSize.height: parent.height
                                                        }

                                                        FastBlur {
                                                            anchors.fill: workspacePreviewSource
                                                            source: workspacePreviewSource
                                                            radius: 7
                                                            opacity: 0.22
                                                            transparentBorder: false
                                                        }
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: workspaceCard.windowCount === 0
                                                text: "Empty space"
                                                color: root.muted
                                                font.pixelSize: 11
                                            }
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            anchors.bottomMargin: 8
                                            text: "Desktop " + workspaceCard.modelData.name
                                            color: root.text
                                            elide: Text.ElideRight
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: overview.focusedWorkspace = workspaceCard.modelData
                                            onClicked: {
                                                overview.focusedWorkspace = workspaceCard.modelData
                                                root.activateWorkspace(workspaceCard.modelData)
                                                root.closeOverview()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: focusedWorkspacePane
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 22
                            color: "transparent"
                            border.width: 0
                            border.color: overview.focusedWorkspace?.active
                                          ? root.accent : "#30455f"

                            readonly property var focusedWindows:
                                overview.focusedWorkspace?.toplevels?.values ?? []
                            readonly property int windowCount: focusedWindows.length
                            readonly property var sourceMonitor:
                                Hyprland.monitorFor(overview.screen)
                            readonly property real sourceScale:
                                Math.max(1, sourceMonitor?.scale ?? 1)
                            readonly property real sourceWidth:
                                sourceMonitor ? sourceMonitor.width / sourceScale : width
                            readonly property real sourceHeight:
                                sourceMonitor ? sourceMonitor.height / sourceScale : height
                            readonly property real sourceX: sourceMonitor?.x ?? 0
                            readonly property real sourceY: sourceMonitor?.y ?? 0

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 0

                                Item {
                                    id: workspaceCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    readonly property real previewScale: Math.max(0.1,
                                        Math.min((width - 96) / focusedWorkspacePane.sourceWidth,
                                                 (height - 76) / focusedWorkspacePane.sourceHeight)
                                        * 0.84)

                                    Item {
                                        id: windowStage
                                        anchors.centerIn: parent
                                        width: focusedWorkspacePane.sourceWidth
                                               * workspaceCanvas.previewScale
                                        height: focusedWorkspacePane.sourceHeight
                                                * workspaceCanvas.previewScale

                                        Repeater {
                                            model: ScriptModel {
                                                values: focusedWorkspacePane.focusedWindows.filter(window =>
                                                    window.wayland !== null)
                                            }

                                            delegate: Item {
                                                id: floatingWindow
                                                required property var modelData
                                                required property int index
                                                readonly property var ipc:
                                                    modelData.lastIpcObject ?? ({})
                                                readonly property var windowPosition:
                                                    ipc.at ?? [focusedWorkspacePane.sourceX,
                                                               focusedWorkspacePane.sourceY]
                                                readonly property var windowSize:
                                                    ipc.size ?? [focusedWorkspacePane.sourceWidth,
                                                                 focusedWorkspacePane.sourceHeight]
                                                x: (windowPosition[0] - focusedWorkspacePane.sourceX)
                                                   * workspaceCanvas.previewScale
                                                y: (windowPosition[1] - focusedWorkspacePane.sourceY)
                                                   * workspaceCanvas.previewScale
                                                width: Math.max(48, windowSize[0]
                                                       * workspaceCanvas.previewScale)
                                                height: Math.max(36, windowSize[1]
                                                        * workspaceCanvas.previewScale)
                                                scale: floatingWindowMouse.containsMouse ? 1.018 : 1.0
                                                z: modelData.activated ? 100 : floatingWindow.index + 1

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 150
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }

                                                RectangularGlow {
                                                    anchors.fill: floatingWindowCard
                                                    glowRadius: 22
                                                    spread: 0.10
                                                    color: "#9e000000"
                                                    cornerRadius: floatingWindowCard.radius + glowRadius
                                                }

                                                Rectangle {
                                                    id: floatingWindowCard
                                                    anchors.fill: parent
                                                    radius: 14
                                                    color: "#101824"
                                                    border.width: floatingWindowMouse.containsMouse ? 2 : 0
                                                    border.color: floatingWindowMouse.containsMouse
                                                                  ? root.accent : "transparent"
                                                    clip: true

                                                    ScreencopyView {
                                                        anchors.fill: parent
                                                        captureSource: root.overviewOpen
                                                                       && root.screenIsCaptureable(root.overviewScreenName)
                                                                       && root.toplevelIsCaptureable(floatingWindow.modelData)
                                                                       ? floatingWindow.modelData.wayland : null
                                                        live: root.overviewOpen
                                                        paintCursor: false
                                                        constraintSize.width: floatingWindow.width
                                                        constraintSize.height: floatingWindow.height
                                                    }

                                                    Rectangle {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        anchors.bottom: parent.bottom
                                                        anchors.bottomMargin: 10
                                                        width: Math.min(parent.width - 18,
                                                                        floatingWindowTitle.implicitWidth + 24)
                                                        height: 30
                                                        radius: 15
                                                        visible: floatingWindowMouse.containsMouse
                                                        color: "#d91a2637"

                                                        Text {
                                                            id: floatingWindowTitle
                                                            anchors.centerIn: parent
                                                            width: parent.width - 20
                                                            text: floatingWindow.modelData.title || "Untitled"
                                                            color: root.text
                                                            elide: Text.ElideRight
                                                            horizontalAlignment: Text.AlignHCenter
                                                            font.family: "SF Pro Text"
                                                            font.pixelSize: 12
                                                            font.weight: Font.Medium
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: floatingWindowMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.activateWorkspace(overview.focusedWorkspace)
                                                        if (floatingWindow.modelData.wayland)
                                                            floatingWindow.modelData.wayland.activate()
                                                        root.closeOverview()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: focusedWorkspacePane.windowCount === 0
                                        text: "No windows in this space"
                                        color: root.muted
                                        font.family: "SF Pro Text"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
