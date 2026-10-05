import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root

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
}
