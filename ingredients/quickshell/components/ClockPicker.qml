pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: clockPicker
    required property ClockService clocks
    required property Theme theme

    visible: clockPicker.clocks.clockPickerOpen
    anchors.fill: parent
    anchors.margins: 18
    radius: 22
    color: "#f2242527"
    border.width: 1
    border.color: "#40ffffff"
    z: 20

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Add World Clock"
                color: clockPicker.theme.text
                font.family: "SF Pro Display"
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 30; height: 30; radius: 15
                color: closePickerMouse.containsMouse ? clockPicker.theme.surface : "transparent"
                Text { anchors.centerIn: parent; text: "×"; color: clockPicker.theme.text; font.pixelSize: 18 }
                MouseArea {
                    id: closePickerMouse
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clockPicker.clocks.clockPickerOpen = false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 14
            color: "#25808080"
            border.width: clockSearchInput.activeFocus ? 1 : 0
            border.color: clockPicker.theme.accent
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                visible: clockSearchInput.text.length === 0
                text: "Search cities or time zones"
                color: clockPicker.theme.muted
                font.family: "SF Pro Text"
                font.pixelSize: 11
            }
            TextInput {
                id: clockSearchInput
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                verticalAlignment: TextInput.AlignVCenter
                text: clockPicker.clocks.clockSearch
                color: clockPicker.theme.text
                selectionColor: clockPicker.theme.accent
                selectedTextColor: clockPicker.theme.activeText
                font.family: "SF Pro Text"
                font.pixelSize: 12
                onTextChanged: clockPicker.clocks.clockSearch = text
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: clockSearchInput.forceActiveFocus()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: timezoneList.implicitHeight
            clip: true

            Column {
                id: timezoneList
                width: parent.width
                spacing: 5

                Repeater {
                    model: clockPicker.clocks.availableWorldClocks.filter(entry => {
                        const query = clockPicker.clocks.clockSearch.toLowerCase()
                        return query.length === 0
                               || entry.label.toLowerCase().includes(query)
                               || entry.timezone.toLowerCase().includes(query)
                    })

                    Rectangle {
                        required property var modelData
                        width: timezoneList.width
                        height: 48
                        radius: 14
                        readonly property bool added: clockPicker.clocks.worldClocks.some(
                            entry => entry.timezone === modelData.timezone)
                        color: timezoneMouse.containsMouse ? clockPicker.theme.surface : "#14808080"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 13
                            anchors.rightMargin: 13
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -1
                                Text {
                                    text: modelData.label
                                    color: clockPicker.theme.text
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: modelData.timezone
                                    color: clockPicker.theme.muted
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 9
                                }
                            }
                            Text {
                                text: parent.parent.added ? "Added" : "+"
                                color: parent.parent.added ? clockPicker.theme.muted : clockPicker.theme.text
                                font.family: "SF Pro Text"
                                font.pixelSize: parent.parent.added ? 10 : 18
                            }
                        }

                        MouseArea {
                            id: timezoneMouse
                            anchors.fill: parent
                            enabled: !parent.added
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: clockPicker.clocks.addWorldClock(parent.modelData)
                        }
                    }
                }
            }
        }
    }
}
