pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

PopupWindow {
    id: claudeUsagePopup
    required property UsageService usage
    required property Theme theme
    required property var panelWindow
    required property var anchorItem

    anchor.window: claudeUsagePopup.panelWindow
    anchor.item: claudeUsagePopup.anchorItem
    anchor.rect.x: claudeUsagePopup.anchorItem.width - width
    anchor.rect.y: claudeUsagePopup.anchorItem.height + 3
    implicitWidth: 340
    implicitHeight: claudeUsageColumn.implicitHeight + 28
    visible: claudeUsagePopup.anchorItem.visible && claudeUsagePopup.anchorItem.open
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
        Keys.onEscapePressed: claudeUsagePopup.anchorItem.open = false

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
                    color: claudeUsagePopup.theme.text
                    font.family: "SF Pro Text"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    text: claudeUsagePopup.usage.claude.updateLabel
                    horizontalAlignment: Text.AlignRight
                    color: claudeUsagePopup.theme.muted
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
                visible: claudeUsagePopup.usage.claude.status !== "ok"
                text: claudeUsagePopup.usage.claude.refreshing ? "Loading Claude usage…"
                      : "Usage unavailable. Check your connection and Claude Code login, then refresh."
                color: claudeUsagePopup.theme.muted
                wrapMode: Text.Wrap
                font.family: "SF Pro Text"
                font.pixelSize: 12
            }

            Repeater {
                model: claudeUsagePopup.usage.claude.windows

                Column {
                    id: claudeWindow
                    required property var modelData
                    width: claudeUsageColumn.width
                    spacing: 8

                    Text {
                        text: claudeWindow.modelData.label
                        color: claudeUsagePopup.theme.text
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
                            color: claudeWindow.modelData.left < 0.2 ? claudeUsagePopup.theme.urgent : "#d19a66"
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: Math.round((1 - claudeWindow.modelData.left) * 100) + "% used"
                            color: claudeUsagePopup.theme.text
                            font.family: "SF Pro Text"
                            font.pixelSize: 13
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Math.round(claudeWindow.modelData.left * 100) + "% remaining"
                            horizontalAlignment: Text.AlignRight
                            color: claudeUsagePopup.theme.muted
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        width: parent.width
                        text: claudeUsagePopup.usage.claude.resetLabel(claudeWindow.modelData)
                        color: claudeUsagePopup.theme.muted
                        wrapMode: Text.Wrap
                        font.family: "SF Pro Text"
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width
                        visible: claudeWindow.modelData.pace.length > 0
                        text: "Pace: " + claudeWindow.modelData.pace
                        color: claudeUsagePopup.theme.muted
                        wrapMode: Text.Wrap
                        font.family: "SF Pro Text"
                        font.pixelSize: 12
                    }
                }
            }

            Text {
                width: parent.width
                visible: claudeUsagePopup.usage.claude.plan.length > 0
                text: "Plan: " + claudeUsagePopup.usage.claude.plan
                color: claudeUsagePopup.theme.muted
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
                        color: claudeActionMouse.containsMouse ? claudeUsagePopup.theme.surface : "transparent"
                        opacity: index === 0 && claudeUsagePopup.usage.claude.refreshing ? 0.5 : 1

                        Text {
                            anchors.centerIn: parent
                            text: claudeAction.modelData
                            color: claudeUsagePopup.theme.text
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: claudeActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: claudeAction.index !== 0 || !claudeUsagePopup.usage.claude.refreshing
                            onClicked: {
                                if (claudeAction.index === 0) {
                                    claudeUsagePopup.usage.claude.refresh()
                                } else {
                                    claudeUsagePopup.anchorItem.open = false
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
