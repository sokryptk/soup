import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property var clock: systemClock
    readonly property var refreshProcess: worldClockRefresh
    property int calendarYear: systemClock.date.getFullYear()
    property int calendarMonth: systemClock.date.getMonth()
    property var worldClocks: [
        { label: "San Francisco", timezone: "America/Los_Angeles" },
        { label: "London", timezone: "Europe/London" },
        { label: "Dubai", timezone: "Asia/Dubai" },
        { label: "Mumbai", timezone: "Asia/Kolkata" }
    ]
    property var worldClockValues: []
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

    function changeCalendarMonth(delta): void {
        const changed = new Date(calendarYear, calendarMonth + delta, 1)
        calendarYear = changed.getFullYear()
        calendarMonth = changed.getMonth()
    }

    function calendarCells(): var {
        const first = new Date(calendarYear, calendarMonth, 1)
        const mondayOffset = (first.getDay() + 6) % 7
        const start = new Date(calendarYear, calendarMonth, 1 - mondayOffset)
        const today = systemClock.date
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

    SystemClock {
        id: systemClock
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
}
