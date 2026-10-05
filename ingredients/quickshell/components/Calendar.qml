pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: calendar
    required property ClockService clocks
    required property Theme theme

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
                text: Qt.formatDateTime(new Date(calendar.clocks.calendarYear,
                                                 calendar.clocks.calendarMonth, 1),
                                        "MMMM yyyy")
                color: calendar.theme.text
                font.family: "SF Pro Display"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Repeater {
                model: [ { glyph: "‹", delta: -1 }, { glyph: "›", delta: 1 } ]
                Rectangle {
                    required property var modelData
                    width: 30; height: 30; radius: 15
                    color: monthNavMouse.containsMouse ? calendar.theme.surface : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        color: calendar.theme.text
                        font.pixelSize: 20
                    }
                    MouseArea {
                        id: monthNavMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendar.clocks.changeCalendarMonth(modelData.delta)
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
                    color: calendar.theme.muted
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
                model: calendar.clocks.calendarCells()
                Rectangle {
                    required property var modelData
                    width: 40; height: 28; radius: 14
                    color: modelData.today ? calendar.theme.accent : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: modelData.today ? calendar.theme.activeText
                               : modelData.currentMonth ? calendar.theme.text : "#65676d"
                        font.family: "SF Pro Text"
                        font.pixelSize: 11
                        font.weight: modelData.today ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
    }
}
