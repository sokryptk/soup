import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: service

    property var windows: []
    property string status: "loading"
    property string plan: ""
    property double updatedAt: 0
    readonly property bool refreshing: fetch.running
    // The bar shows the five-hour allowance; weekly usage stays in the popup.
    readonly property var summary: windows.find(window => window.key === "primary"
                                               && window.windowMinutes !== 10080) ?? null
    readonly property string label: summary
                                    ? "Claude " + Math.round(summary.left * 100) + "%"
                                    : "Claude --"
    readonly property real remaining: summary ? summary.left : -1
    readonly property string updateLabel: refreshing ? "Refreshing…"
                                         : status !== "ok" ? "Unavailable"
                                         : updatedAt > 0 && usageClock.date.getTime() - updatedAt >= 60000
                                           ? "Updated " + duration((usageClock.date.getTime() - updatedAt) / 1000) + " ago"
                                           : "Updated just now"

    function duration(seconds): string {
        const minutes = Math.max(0, Math.floor(seconds / 60))
        if (minutes >= 1440)
            return Math.floor(minutes / 1440) + "d " + Math.floor((minutes % 1440) / 60) + "h"
        if (minutes >= 60)
            return Math.floor(minutes / 60) + "h " + (minutes % 60) + "m"
        return minutes + "m"
    }

    function resetLabel(window): string {
        if (Number.isFinite(window.resetAt)) {
            const seconds = (window.resetAt - usageClock.date.getTime()) / 1000
            return seconds > 0 ? "Resets in " + duration(seconds) : "Reset due · refresh usage"
        }
        return window.resetDescription || "Reset time unavailable"
    }

    function unavailable(): void {
        windows = []
        plan = ""
        updatedAt = 0
        status = "error"
    }

    function parseUsage(payload): void {
        try {
            const providers = JSON.parse(payload)
            const provider = Array.isArray(providers)
                             ? providers.find(item => item?.provider === "claude") : null
            if (!provider?.usage || provider.error)
                throw new Error("Claude usage unavailable")

            const usage = provider.usage
            const entries = [
                { key: "primary", label: usage.primary?.windowMinutes === 10080 ? "Weekly" : "Session (5 hours)" },
                { key: "secondary", label: "Weekly · all models" },
                { key: "tertiary", label: "Weekly · model-specific" }
            ]
            const parsed = []
            entries.forEach(entry => {
                const window = usage[entry.key]
                if (!window || typeof window.usedPercent !== "number" || !Number.isFinite(window.usedPercent))
                    return
                parsed.push({
                    key: entry.key,
                    label: entry.label,
                    windowMinutes: window.windowMinutes,
                    left: 1 - Math.max(0, Math.min(100, window.usedPercent)) / 100,
                    resetAt: Date.parse(window.resetsAt || ""),
                    resetDescription: window.resetDescription || "",
                    pace: provider.pace?.[entry.key]?.summary?.split(" | ").join(" · ") || ""
                })
            })
            if (parsed.length === 0)
                throw new Error("Claude quota windows unavailable")

            windows = parsed
            plan = usage.loginMethod || ""
            const timestamp = Date.parse(usage.updatedAt || "")
            updatedAt = Number.isFinite(timestamp) ? timestamp : Date.now()
            status = "ok"
        } catch (error) {
            unavailable()
        }
    }

    function refresh(): void {
        if (!fetch.running)
            fetch.running = true
    }

    SystemClock {
        id: usageClock
        precision: SystemClock.Minutes
    }

    Process {
        id: fetch
        // OAuth reuses the existing Claude Code login without launching its TUI.
        command: ["/usr/bin/timeout", "--kill-after=5s", "40s", "/usr/bin/codexbar",
                  "usage", "--provider", "claude", "--source", "oauth", "--format", "json", "--no-color"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: service.parseUsage(text.trim())
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                service.unavailable()
        }
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: service.refresh()
    }
}
