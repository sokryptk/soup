import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    required property Theme theme

    id: root

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
                                              ? theme.urgent
                                              : codexUsageLeft < 0.2
                                                ? theme.urgent
                                                : codexUsageLeft < 0.5
                                                  ? "#e5c07b" : "#98c379"
    readonly property string codexUsagePaceText: codexUsageStatus === "ok"
                                                  ? "Pace: " + codexUsagePaceSummary
                                                  : "Pace: waiting for usage data"

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

    readonly property var codexRefresh: codexUsageRefresh
    readonly property var claude: claudeUsage

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
}
