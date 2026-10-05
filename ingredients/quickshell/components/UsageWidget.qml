pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

RowLayout {
    required property UsageService usage
    required property Theme theme
    required property var panelWindow

    id: usageWidget
    spacing: 0

    Rectangle {
        id: codexUsageItem
        visible: usageWidget.usage.usageProvider === "codex"
        // Keep the hit area in place when switching providers.
        implicitWidth: Math.max(codexUsageText.implicitWidth, claudeUsageText.implicitWidth) + 16
        implicitHeight: 22
        radius: 7
        color: codexUsageMouse.containsMouse ? usageWidget.theme.surface : "transparent"

        Text {
            id: codexUsageText
            anchors.centerIn: parent
            text: usageWidget.usage.codexUsageLabel
            color: usageWidget.usage.codexUsageColor
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        MouseArea {
            id: codexUsageMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onWheel: wheel => usageWidget.usage.scrollUsageProvider(wheel)
            onClicked: {
                if (!usageWidget.usage.codexRefresh.running)
                    usageWidget.usage.codexRefresh.running = true
                usageWidget.usage.codexUsageOpen = !usageWidget.usage.codexUsageOpen
            }
        }

        CodexUsagePopup {
            usage: usageWidget.usage
            theme: usageWidget.theme
            panelWindow: usageWidget.panelWindow
            anchorItem: codexUsageItem
        }
    }

    Rectangle {
        id: claudeUsageItem
        property bool open: false
        visible: usageWidget.usage.usageProvider === "claude"
        onVisibleChanged: if (!visible) open = false
        readonly property color usageColor: usageWidget.usage.claude.status !== "ok"
                                            ? usageWidget.theme.urgent
                                            : usageWidget.usage.claude.remaining < 0.2
                                              ? usageWidget.theme.urgent
                                              : usageWidget.usage.claude.remaining < 0.5
                                                ? "#e5c07b" : "#98c379"
        implicitWidth: Math.max(codexUsageText.implicitWidth, claudeUsageText.implicitWidth) + 16
        implicitHeight: 22
        radius: 7
        color: claudeUsageMouse.containsMouse || open ? usageWidget.theme.surface : "transparent"

        Text {
            id: claudeUsageText
            anchors.centerIn: parent
            text: usageWidget.usage.claude.label
            color: claudeUsageItem.usageColor
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        Connections {
            target: usageWidget.usage
            function onCodexUsageOpenChanged() {
                if (usageWidget.usage.codexUsageOpen)
                    claudeUsageItem.open = false
            }
        }

        MouseArea {
            id: claudeUsageMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onWheel: wheel => usageWidget.usage.scrollUsageProvider(wheel)
            onClicked: {
                usageWidget.usage.codexUsageOpen = false
                claudeUsageItem.open = !claudeUsageItem.open
                if (claudeUsageItem.open)
                    usageWidget.usage.claude.refresh()
            }
        }

        ClaudeUsagePopup {
            usage: usageWidget.usage
            theme: usageWidget.theme
            panelWindow: usageWidget.panelWindow
            anchorItem: claudeUsageItem
        }
    }
}
