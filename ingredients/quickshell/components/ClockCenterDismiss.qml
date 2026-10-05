pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    required property ShellState state
    required property ClockService clocks

    id: clockCenterDismiss
    required property var modelData
    screen: modelData
    visible: clockCenterDismiss.state.clockCenterOpen
             && modelData.name === clockCenterDismiss.state.clockCenterScreenName
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clock-center-dismiss"

    mask: Region {
        width: clockCenterDismiss.width
        height: clockCenterDismiss.height

        Region {
            x: clockCenterDismiss.width - 370
            y: 38
            width: 360
            height: 700
            intersection: Intersection.Subtract
        }
    }

    anchors { top: true; right: true; bottom: true; left: true }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            clockCenterDismiss.state.clockCenterOpen = false
            clockCenterDismiss.clocks.clockPickerOpen = false
            clockCenterDismiss.clocks.worldClockEditing = false
        }
    }
}
