pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    required property ShellState state
    required property ControlService controls
    required property Theme theme

    id: controlCenter
    required property var modelData
    screen: modelData
    visible: controlCenter.state.controlCenterOpen
             && modelData.name === controlCenter.state.controlCenterScreenName
    implicitWidth: 311
    implicitHeight: 520
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: {
        if (visible)
            controlCenter.contentItem.Window.window?.requestActivate()
    }

    anchors {
        top: true
        right: true
    }

    margins {
        top: 38
        right: 10
    }

    Item {
        anchors.fill: parent
        transformOrigin: Item.TopRight
        scale: controlCenter.state.controlCenterOpen ? 1 : 0.72
        opacity: controlCenter.state.controlCenterOpen ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: {
                controlCenter.state.controlCenterOpen = false
                controlCenter.controls.wifiExpanded = false
                controlCenter.controls.bluetoothExpanded = false
            }
        }

        Item {
            width: 160
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top
            z: 2
            opacity: controlCenter.controls.connectivityDetailsOpen ? 0 : 1
            enabled: !controlCenter.controls.connectivityDetailsOpen
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

            Rectangle {
            width: parent.width
            height: implicitHeight
            x: 0
            y: 0
            implicitHeight: 68
            radius: 34
            color: "#1a808080"
            border.width: 1
            border.color: "#25ffffff"
            clip: true

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 5
                RowLayout {
                    Layout.fillWidth: true; implicitHeight: 52; spacing: 8
                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: controlCenter.controls.wifiEnabled ? "#d8e2e3e6"
                              : wifiSwitchMouse.containsMouse ? "#50ffffff" : "#28ffffff"
                        Text { anchors.centerIn: parent; text: "⌁"; color: controlCenter.controls.wifiEnabled ? controlCenter.theme.activeText : controlCenter.theme.muted; font.pixelSize: 27 }
                        MouseArea {
                            id: wifiSwitchMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenter.controls.toggleWifi()
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text { text: "Wi‑Fi"; color: controlCenter.theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text { Layout.maximumWidth: 81; text: controlCenter.controls.wifiSubtitle; color: controlCenter.theme.muted; elide: Text.ElideRight; font.pixelSize: 10 }
                    }
                    Item { Layout.fillWidth: true }
                    MouseArea { anchors.fill: parent; anchors.leftMargin: 46; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.controls.toggleWifiList() }
                }
                Repeater {
                    model: []
                    Rectangle {
                        required property string modelData
                        Layout.fillWidth: true; implicitHeight: 30; radius: 15
                        color: wifiNetworkMouse.containsMouse ? "#35ffffff" : "transparent"
                        Text { anchors.fill: parent; anchors.leftMargin: 12; verticalAlignment: Text.AlignVCenter; text: modelData; color: controlCenter.theme.text; elide: Text.ElideRight; font.pixelSize: 12 }
                        MouseArea { id: wifiNetworkMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["iwctl", "station", "wlan0", "connect", modelData]) }
                    }
                }
            }
        }

            Rectangle {
            width: parent.width
            height: implicitHeight
            x: 0
            y: 78
            implicitHeight: 68
            radius: 34
            color: "#1a808080"
            border.width: 1
            border.color: "#25ffffff"
            clip: true

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 5
                RowLayout {
                    Layout.fillWidth: true; implicitHeight: 52; spacing: 8
                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: controlCenter.controls.bluetoothEnabled ? "#d8e2e3e6"
                              : bluetoothSwitchMouse.containsMouse ? "#50ffffff" : "#28ffffff"
                        Text { anchors.centerIn: parent; text: "ᛒ"; color: controlCenter.controls.bluetoothEnabled ? controlCenter.theme.activeText : controlCenter.theme.muted; font.pixelSize: 23 }
                        MouseArea {
                            id: bluetoothSwitchMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenter.controls.toggleBluetooth()
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text { text: "Bluetooth"; color: controlCenter.theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { Layout.maximumWidth: 81; text: controlCenter.controls.bluetoothSubtitle; color: controlCenter.theme.muted; elide: Text.ElideRight; font.pixelSize: 10 }
                    }
                    Item { Layout.fillWidth: true }
                    MouseArea { anchors.fill: parent; anchors.leftMargin: 46; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.controls.toggleBluetoothList() }
                }
                Repeater {
                    model: []
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 30; radius: 15
                        color: bluetoothDeviceMouse.containsMouse ? "#35ffffff" : "transparent"
                        Text { anchors.fill: parent; anchors.leftMargin: 12; verticalAlignment: Text.AlignVCenter; text: modelData.name; color: controlCenter.theme.text; elide: Text.ElideRight; font.pixelSize: 12 }
                        MouseArea { id: bluetoothDeviceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bluetoothctl", "connect", modelData.address]) }
                    }
                }
            }
            }
        }

        Rectangle {
            width: 140
            height: 146
            anchors.top: parent.top
            anchors.right: parent.right
            radius: 29
            color: "#1a808080"
            border.width: 1
            border.color: "#25ffffff"
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: 140
                    height: 146
                    radius: 29
                }
            }
            z: 1
            opacity: controlCenter.controls.connectivityDetailsOpen ? 0 : 1
            enabled: !controlCenter.controls.connectivityDetailsOpen
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

            Rectangle {
                anchors.fill: parent
                radius: 29
                color: "#20ffffff"
                clip: true

                Image {
                    anchors.fill: parent
                    source: controlCenter.controls.mediaPlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    color: controlCenter.controls.mediaPlayer?.trackArtUrl ? "#78000000" : "transparent"
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 3

                    Text {
                    Layout.fillWidth: true
                    text: controlCenter.controls.mediaPlayer?.trackTitle || "Nothing playing"
                    color: controlCenter.theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                    Text {
                    Layout.fillWidth: true
                    text: controlCenter.controls.mediaPlayer?.trackArtist || "Media"
                    color: controlCenter.theme.muted
                    elide: Text.ElideRight
                    font.pixelSize: 11
                }

                    Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 7

                    Text {
                        text: "‹"
                        color: controlCenter.controls.mediaPlayer?.canGoPrevious ? controlCenter.theme.text : controlCenter.theme.muted
                        font.pixelSize: 20
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (controlCenter.controls.mediaPlayer?.canGoPrevious) controlCenter.controls.mediaPlayer.previous() }
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: mediaPlayMouse.containsMouse ? "#65ffffff" : "#40ffffff"
                        Text {
                            anchors.centerIn: parent
                            text: controlCenter.controls.mediaPlayer?.isPlaying ? "Ⅱ" : "▶"
                            color: controlCenter.theme.text
                            font.pixelSize: controlCenter.controls.mediaPlayer?.isPlaying ? 12 : 11
                        }
                        MouseArea {
                            id: mediaPlayMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (controlCenter.controls.mediaPlayer?.canTogglePlaying) controlCenter.controls.mediaPlayer.togglePlaying()
                        }
                    }
                    Text {
                        text: "›"
                        color: controlCenter.controls.mediaPlayer?.canGoNext ? controlCenter.theme.text : controlCenter.theme.muted
                        font.pixelSize: 20
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (controlCenter.controls.mediaPlayer?.canGoNext) controlCenter.controls.mediaPlayer.next() }
                    }
                    }
                }
            }
        }

        Rectangle {
            x: 0; y: 156
            width: 311; height: 58
            radius: 20
            color: "#1a808080"
            z: 3
            opacity: controlCenter.controls.connectivityDetailsOpen ? 0 : 1
            enabled: !controlCenter.controls.connectivityDetailsOpen
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 10
                Text { text: "☀"; color: controlCenter.theme.text; font.pixelSize: 18 }
                Rectangle {
                    Layout.fillWidth: true; height: 8; radius: 4; color: "#33808080"
                    Rectangle { width: parent.width * controlCenter.controls.brightnessLevel; height: parent.height; radius: 4; color: controlCenter.theme.text }
                    Rectangle { x: Math.max(0, parent.width * controlCenter.controls.brightnessLevel - 7); anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: controlCenter.theme.text }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                        function updateLevel(px): void { controlCenter.controls.setBrightness(Math.max(0, Math.min(1, px / width))) }
                        onPressed: mouse => updateLevel(mouse.x)
                        onPositionChanged: mouse => { if (pressed) updateLevel(mouse.x) }
                    }
                }
                Text {
                    text: controlCenter.controls.brightnessAvailable
                          ? Math.round(controlCenter.controls.brightnessLevel * 100) + "%" : "No display"
                    color: controlCenter.theme.muted
                    font.pixelSize: 9
                }
            }
        }

        Rectangle {
            x: 0; y: 224
            width: 311
            height: controlCenter.controls.outputExpanded ? 70 + controlCenter.controls.audioOutputs.length * 42 : 58
            radius: 20
            color: "#1a808080"
            clip: true
            z: 4
            opacity: controlCenter.controls.connectivityDetailsOpen ? 0 : 1
            enabled: !controlCenter.controls.connectivityDetailsOpen
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }
            Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 6
                RowLayout {
                    Layout.fillWidth: true; implicitHeight: 38; spacing: 10
                    Text { text: "◖"; color: controlCenter.theme.text; font.pixelSize: 18 }
                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4; color: "#33808080"
                        Rectangle { width: parent.width * controlCenter.controls.volumeLevel; height: parent.height; radius: 4; color: controlCenter.theme.text }
                        Rectangle { x: Math.max(0, parent.width * controlCenter.controls.volumeLevel - 7); anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: controlCenter.theme.text }
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                            function updateLevel(px): void { controlCenter.controls.setVolume(Math.max(0, Math.min(1, px / width))) }
                            onPressed: mouse => updateLevel(mouse.x)
                            onPositionChanged: mouse => { if (pressed) updateLevel(mouse.x) }
                        }
                    }
                    Rectangle {
                        width: 112; height: 38; radius: 13
                        color: outputMouse.containsMouse ? "#33808080" : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 5
                            Text {
                                Layout.fillWidth: true
                                text: controlCenter.controls.currentAudioOutputLabel
                                color: controlCenter.theme.text
                                elide: Text.ElideRight
                                font.pixelSize: 9
                            }
                            Text { text: "›"; color: controlCenter.theme.muted; font.pixelSize: 17 }
                        }
                        MouseArea { id: outputMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.controls.toggleOutputList() }
                    }
                }

                Repeater {
                    model: controlCenter.controls.outputExpanded ? controlCenter.controls.audioOutputs : []
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 36; radius: 13
                        color: modelData.name === controlCenter.controls.defaultAudioOutput ? "#33808080"
                              : outputEntryMouse.containsMouse ? "#24808080" : "#1a808080"
                        Text { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; verticalAlignment: Text.AlignVCenter; text: modelData.description; color: controlCenter.theme.text; elide: Text.ElideRight; font.pixelSize: 11 }
                        MouseArea { id: outputEntryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.controls.selectAudioOutput(modelData.name) }
                    }
                }
            }
        }

        Repeater {
            model: [
                { kind: "wifi", label: "Wi‑Fi", icon: "⌁" },
                { kind: "bluetooth", label: "Bluetooth", icon: "ᛒ" }
            ]

            ConnectivityDetails {
                controls: controlCenter.controls
                theme: controlCenter.theme
            }
        }
    }
}
