pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"

PanelWindow {
    required property ShellState state
    required property ClockService clocks
    required property Theme theme

    required property UsageService usage

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
        color: bar.theme.background

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Rectangle {
                implicitWidth: 24
                implicitHeight: 20
                radius: 6
                color: overviewMouse.containsMouse || bar.state.overviewOpen
                       ? bar.theme.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "▦"
                    color: bar.state.overviewOpen ? bar.theme.accent : bar.theme.text
                    font.pixelSize: 14
                }

                MouseArea {
                    id: overviewMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.state.toggleOverview(bar.screen)
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
                        color: modelData.active ? bar.theme.accent
                              : workspaceMouse.containsMouse ? bar.theme.surface
                              : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: modelData.active ? bar.theme.activeText
                                 : modelData.urgent ? bar.theme.urgent
                                 : bar.theme.text
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                            font.weight: modelData.active ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            id: workspaceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.state.activateWorkspace(modelData)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                text: Hyprland.activeToplevel?.title ?? "Desktop"
                color: bar.theme.muted
                elide: Text.ElideRight
                font.family: "SF Pro Text"
                font.pixelSize: 12
            }

            SystemTrayWidget {
                theme: bar.theme
                panelWindow: bar
            }

            UsageWidget {
                usage: bar.usage
                theme: bar.theme
                panelWindow: bar
            }

            Rectangle {
                implicitWidth: 26
                implicitHeight: 22
                radius: 7
                color: controlCenterMouse.containsMouse || bar.state.controlCenterOpen
                       ? bar.theme.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "≡"
                    color: bar.theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: controlCenterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.state.toggleControlCenter(bar.screen)
                }
            }

            Rectangle {
                implicitWidth: timeText.implicitWidth + 16
                implicitHeight: 22
                radius: 7
                color: clockMouse.containsMouse || bar.state.clockCenterOpen
                       ? bar.theme.surface : "transparent"

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(bar.clocks.clock.date, "ddd, d MMM  HH:mm")
                    color: bar.theme.text
                    font.family: "SF Pro Text"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.state.toggleClockCenter(bar.screen)
                }
            }
        }
    }
}
