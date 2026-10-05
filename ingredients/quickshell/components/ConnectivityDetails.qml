pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

Rectangle {
    required property ControlService controls
    required property Theme theme

    id: detailOverlay
    required property var modelData
    readonly property bool expanded: modelData.kind === "wifi"
                                     ? detailOverlay.controls.wifiExpanded : detailOverlay.controls.bluetoothExpanded
    readonly property var entries: modelData.kind === "wifi"
                                   ? detailOverlay.controls.wifiNetworks : detailOverlay.controls.bluetoothDevices
    readonly property string connectedName: modelData.kind === "wifi"
                                            ? detailOverlay.controls.wifiConnectedName
                                            : detailOverlay.controls.bluetoothConnectedName
    readonly property var connectedEntries: entries.filter(entry =>
        (typeof entry === "string" ? entry : entry.name) === connectedName)
    readonly property var discoveredEntries: entries.filter(entry =>
        (typeof entry === "string" ? entry : entry.name) !== connectedName)
    x: 0
    y: expanded ? 0 : (modelData.kind === "wifi" ? 0 : 78)
    width: expanded ? 311 : 52
    height: expanded ? 170 + Math.max(1, connectedEntries.length) * 36
                       + discoveredEntries.length * 47 : 52
    radius: expanded ? 31 : 26
    color: "#1a808080"
    border.width: 1
    border.color: "#30ffffff"
    opacity: expanded ? 1 : 0
    enabled: expanded
    clip: true
    z: 10

    Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        opacity: detailOverlay.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 52
            spacing: 9

            Rectangle {
                width: 52; height: 52; radius: 26
                color: modelData.kind === "wifi"
                       ? (detailOverlay.controls.wifiEnabled ? "#d8e2e3e6" : "#28ffffff")
                       : (detailOverlay.controls.bluetoothEnabled ? "#d8e2e3e6" : "#28ffffff")
                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: modelData.kind === "wifi"
                           ? (detailOverlay.controls.wifiEnabled ? detailOverlay.theme.activeText : detailOverlay.theme.muted)
                           : (detailOverlay.controls.bluetoothEnabled ? detailOverlay.theme.activeText : detailOverlay.theme.muted)
                    font.pixelSize: modelData.kind === "wifi" ? 27 : 23
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.kind === "wifi" ? detailOverlay.controls.toggleWifi() : detailOverlay.controls.toggleBluetooth()
                }
            }

            ColumnLayout {
                spacing: 0
                Text { text: modelData.label; color: detailOverlay.theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                Text {
                    text: modelData.kind === "wifi" ? detailOverlay.controls.wifiSubtitle : detailOverlay.controls.bluetoothSubtitle
                    color: detailOverlay.theme.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.maximumWidth: 150
                }
            }
            Item { Layout.fillWidth: true }
            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: 46
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.kind === "wifi"
                           ? detailOverlay.controls.toggleWifiList() : detailOverlay.controls.toggleBluetoothList()
            }
        }

        Text {
            Layout.leftMargin: 12
            text: "Connected"
            color: detailOverlay.theme.muted
            font.pixelSize: 10
            font.weight: Font.DemiBold
            visible: detailOverlay.expanded
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.preferredHeight: 30
            verticalAlignment: Text.AlignVCenter
            text: detailOverlay.connectedName || "Not connected"
            color: detailOverlay.connectedName ? detailOverlay.theme.text : detailOverlay.theme.muted
            elide: Text.ElideRight
            font.pixelSize: 12
            visible: detailOverlay.expanded
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            implicitHeight: 1
            color: "#28ffffff"
            visible: detailOverlay.expanded
        }

        Text {
            Layout.leftMargin: 12
            text: detailOverlay.modelData.kind === "wifi" ? "Available Networks" : "Discovered Devices"
            color: detailOverlay.theme.muted
            font.pixelSize: 10
            font.weight: Font.DemiBold
            visible: detailOverlay.expanded
        }

        Repeater {
            model: detailOverlay.discoveredEntries
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 39
                radius: 20
                color: detailEntryMouse.containsMouse ? "#33808080" : "#1a808080"
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: Text.AlignVCenter
                    text: typeof modelData === "string" ? modelData : modelData.name
                    color: detailOverlay.theme.text
                    elide: Text.ElideRight
                    font.pixelSize: 12
                }
                MouseArea {
                    id: detailEntryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (detailOverlay.modelData.kind === "wifi")
                            Quickshell.execDetached(["iwctl", "station", "wlan0", "connect", modelData])
                        else
                            Quickshell.execDetached(["bluetoothctl", "connect", modelData.address])
                    }
                }
            }
        }
    }
}
