pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../services"

PopupWindow {
    required property UsageService usage
    required property Theme theme
    required property var panelWindow
    required property var anchorItem

    id: codexUsagePopup
    anchor.window: codexUsagePopup.panelWindow
    anchor.item: codexUsagePopup.anchorItem
    anchor.rect.x: codexUsagePopup.anchorItem.width - width
    anchor.rect.y: codexUsagePopup.anchorItem.height + 3
    implicitWidth: 340
    implicitHeight: codexUsageColumn.implicitHeight + 28
    visible: codexUsagePopup.anchorItem.visible && codexUsagePopup.usage.codexUsageOpen
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
                    color: codexUsagePopup.theme.text
                    font.family: "SF Pro Text"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width - 100
                    text: codexUsagePopup.usage.codexUsageStatus === "ok" ? "Updated just now" : "Unavailable"
                    horizontalAlignment: Text.AlignRight
                    color: codexUsagePopup.theme.muted
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
                color: codexUsagePopup.theme.text
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
                    width: codexUsagePopup.usage.codexUsageStatus === "ok"
                           ? parent.width * Math.max(0, Math.min(1, 1 - codexUsagePopup.usage.codexUsageLeft))
                           : 0
                    height: parent.height
                    radius: 4
                    color: codexUsagePopup.usage.codexUsageStatus === "ok" ? "#d19a66" : codexUsagePopup.theme.urgent
                }
            }

            Row {
                width: parent.width
                Text {
                    text: codexUsagePopup.usage.codexUsageStatus === "ok"
                          ? Math.round((1 - codexUsagePopup.usage.codexUsageLeft) * 100) + "% used"
                          : "Unavailable"
                    color: codexUsagePopup.theme.text
                    font.family: "SF Pro Text"
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width - 90
                    text: codexUsagePopup.usage.codexUsageStatus === "ok"
                          ? codexUsagePopup.usage.codexUsageTooltip.replace("Codex weekly quota: ", "").replace(" · ", "  ·  ")
                          : "Check codexbar-cli or Codex login"
                    horizontalAlignment: Text.AlignRight
                    color: codexUsagePopup.theme.muted
                    elide: Text.ElideRight
                    font.family: "SF Pro Text"
                    font.pixelSize: 12
                }
            }

            Text {
                width: parent.width
                text: codexUsagePopup.usage.codexUsagePaceText
                color: codexUsagePopup.theme.muted
                wrapMode: Text.Wrap
                font.family: "SF Pro Text"
                font.pixelSize: 12
            }

            Text {
                width: parent.width
                visible: codexUsagePopup.usage.codexUsagePlan.length > 0 || codexUsagePopup.usage.codexUsageCredits.length > 0
                text: (codexUsagePopup.usage.codexUsagePlan.length > 0 ? "Plan: " + codexUsagePopup.usage.codexUsagePlan : "")
                      + (codexUsagePopup.usage.codexUsageCredits.length > 0 ? "  ·  Credits: " + codexUsagePopup.usage.codexUsageCredits : "")
                color: codexUsagePopup.theme.muted
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
                    color: refreshUsageMouse.containsMouse ? codexUsagePopup.theme.surface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "↻  Refresh"
                        color: codexUsagePopup.theme.text
                        font.family: "SF Pro Text"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: refreshUsageMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!codexUsagePopup.usage.codexRefresh.running)
                                codexUsagePopup.usage.codexRefresh.running = true
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32
                    radius: 7
                    color: dashboardMouse.containsMouse ? codexUsagePopup.theme.surface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⌁  Dashboard"
                        color: codexUsagePopup.theme.text
                        font.family: "SF Pro Text"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: dashboardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["xdg-open", "https://chatgpt.com/codex/settings/usage"])
                    }
                }
            }
        }
    }
}
