pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    required property ShellState state
    required property ControlService controls

    id: controlCenterDismiss
    required property var modelData
    screen: modelData
    visible: controlCenterDismiss.state.controlCenterOpen
             && modelData.name === controlCenterDismiss.state.controlCenterScreenName
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center-dismiss"

    mask: Region {
        width: controlCenterDismiss.width
        height: controlCenterDismiss.height

        Region {
            x: controlCenterDismiss.width - 321
            y: 38
            width: 311
            height: 520
            intersection: Intersection.Subtract
        }
    }

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            controlCenterDismiss.state.controlCenterOpen = false
            controlCenterDismiss.controls.wifiExpanded = false
            controlCenterDismiss.controls.bluetoothExpanded = false
            controlCenterDismiss.controls.outputExpanded = false
        }
    }
}
