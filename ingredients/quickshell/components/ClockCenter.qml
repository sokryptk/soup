pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    required property ShellState state
    required property ClockService clocks
    required property Theme theme

    id: clockCenter
    required property var modelData
    screen: modelData
    visible: clockCenter.state.clockCenterOpen
             && modelData.name === clockCenter.state.clockCenterScreenName
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
        scale: clockCenter.state.clockCenterOpen ? 1 : 0.72
        opacity: clockCenter.state.clockCenterOpen ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        Keys.onEscapePressed: clockCenter.state.clockCenterOpen = false

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
                        text: Qt.formatDateTime(clockCenter.clocks.clock.date, "HH:mm")
                        color: clockCenter.theme.text
                        font.family: "SF Pro Display"
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Qt.formatDateTime(clockCenter.clocks.clock.date, "dddd, d MMMM yyyy")
                        color: clockCenter.theme.muted
                        font.family: "SF Pro Text"
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: calendarTodayMouse.containsMouse ? clockCenter.theme.surface : "transparent"
                    Text { anchors.centerIn: parent; text: "●"; color: clockCenter.theme.text; font.pixelSize: 9 }
                    MouseArea {
                        id: calendarTodayMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clockCenter.clocks.calendarYear = clockCenter.clocks.clock.date.getFullYear()
                            clockCenter.clocks.calendarMonth = clockCenter.clocks.clock.date.getMonth()
                        }
                    }
                }
            }

            Calendar {
                clocks: clockCenter.clocks
                theme: clockCenter.theme
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "World Clocks"
                    color: clockCenter.theme.text
                    font.family: "SF Pro Display"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: addClockLabel.implicitWidth + 18
                    implicitHeight: 26
                    radius: 13
                    color: addClockMouse.containsMouse ? clockCenter.theme.surface : "#20808080"
                    Text {
                        id: addClockLabel
                        anchors.centerIn: parent
                        text: "+ Add"
                        color: clockCenter.theme.text
                        font.family: "SF Pro Text"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: addClockMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clockCenter.clocks.clockSearch = ""
                            clockCenter.clocks.clockPickerOpen = true
                            clockCenter.clocks.worldClockEditing = false
                        }
                    }
                }

                Rectangle {
                    implicitWidth: editClockLabel.implicitWidth + 18
                    implicitHeight: 26
                    radius: 13
                    color: clockCenter.clocks.worldClockEditing ? clockCenter.theme.accent
                          : editClockMouse.containsMouse ? clockCenter.theme.surface : "transparent"
                    Text {
                        id: editClockLabel
                        anchors.centerIn: parent
                        text: clockCenter.clocks.worldClockEditing ? "Done" : "Edit"
                        color: clockCenter.clocks.worldClockEditing ? clockCenter.theme.activeText : clockCenter.theme.muted
                        font.family: "SF Pro Text"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: editClockMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clockCenter.clocks.clockPickerOpen = false
                            clockCenter.clocks.worldClockEditing = !clockCenter.clocks.worldClockEditing
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
                        model: clockCenter.clocks.worldClocks
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
                                text: clockCenter.clocks.worldClockValues[index]?.time || "--:--"
                                color: clockCenter.theme.text
                                font.family: "SF Pro Display"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: clockCenter.theme.text
                                elide: Text.ElideRight
                                font.family: "SF Pro Text"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.fillWidth: true
                                text: clockCenter.clocks.worldClockValues[index]?.date || modelData.timezone
                                color: clockCenter.theme.muted
                                elide: Text.ElideRight
                                font.family: "SF Pro Text"
                                font.pixelSize: 9
                            }
                        }

                        Rectangle {
                            visible: clockCenter.clocks.worldClockEditing
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
                                onClicked: clockCenter.clocks.removeWorldClock(index)
                            }
                        }
                        }
                    }
                }
            }
        }

        ClockPicker {
            clocks: clockCenter.clocks
            theme: clockCenter.theme
        }
    }
}
