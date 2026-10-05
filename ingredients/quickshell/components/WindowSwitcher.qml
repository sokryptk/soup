pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

PanelWindow {
    required property ShellState state
    required property Theme theme

    id: windowSwitcher
    required property var modelData
    screen: modelData
    visible: windowSwitcher.state.windowSwitcherOpen
             && modelData.name === windowSwitcher.state.windowSwitcherScreenName
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-window-switcher"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    Rectangle {
        id: windowSwitcherSurface
        anchors.fill: parent
        color: "transparent"
        focus: windowSwitcher.visible

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab) {
                windowSwitcher.state.cycleWindowSwitcher((event.modifiers & Qt.ShiftModifier) !== 0)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                windowSwitcher.state.acceptWindowSwitcher()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                windowSwitcher.state.closeWindowSwitcher()
                event.accepted = true
            }
        }

        Keys.onReleased: event => {
            if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L
                    || event.key === Qt.Key_Super_R) {
                windowSwitcher.state.acceptWindowSwitcher()
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: windowSwitcher.state.closeWindowSwitcher()
        }

        Rectangle {
            id: switcherContainer
            anchors.centerIn: parent
            width: Math.min(parent.width - 80,
                            Math.max(300, switcherRow.implicitWidth + 40))
            height: 226
            radius: 26
            color: "#9c242527"
            border.width: 1
            border.color: "#38ffffff"

            Row {
                id: switcherRow
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: windowSwitcher.state.windowSwitcherWindows

                    Rectangle {
                        id: switcherCard
                        required property var modelData
                        required property int index
                        width: Math.min(230, Math.max(150,
                            (windowSwitcher.width - 128) /
                            Math.max(1, windowSwitcher.state.windowSwitcherWindows.length)))
                        height: 178
                        radius: 22
                        color: index === windowSwitcher.state.windowSwitcherIndex
                               ? "#703b4261" : "#2411111a"
                        border.width: index === windowSwitcher.state.windowSwitcherIndex ? 3 : 0
                        border.color: index === windowSwitcher.state.windowSwitcherIndex
                                      ? windowSwitcher.theme.accent : "transparent"
                        scale: index === windowSwitcher.state.windowSwitcherIndex ? 1.0 : 0.94
                        opacity: index === windowSwitcher.state.windowSwitcherIndex ? 1.0 : 0.72
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        Item {
                            id: roundedPreview
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 7
                            height: parent.height - 50
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: roundedPreview.width
                                    height: roundedPreview.height
                                    radius: 16
                                }
                            }

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: windowSwitcher.state.windowSwitcherOpen
                                               && windowSwitcher.state.screenIsCaptureable(windowSwitcher.state.windowSwitcherScreenName)
                                               && windowSwitcher.state.toplevelIsCaptureable(switcherCard.modelData)
                                               ? switcherCard.modelData.wayland : null
                                live: windowSwitcher.state.windowSwitcherOpen
                                paintCursor: false
                                constraintSize.width: roundedPreview.width
                                constraintSize.height: roundedPreview.height
                            }
                        }

                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 43

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: switcherCard.modelData.title || "Untitled"
                                color: index === windowSwitcher.state.windowSwitcherIndex
                                       ? windowSwitcher.theme.text : windowSwitcher.theme.muted
                                elide: Text.ElideRight
                                font.family: "SF Pro Text"
                                font.pixelSize: index === windowSwitcher.state.windowSwitcherIndex ? 14 : 13
                                font.weight: index === windowSwitcher.state.windowSwitcherIndex
                                             ? Font.DemiBold : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: windowSwitcher.state.windowSwitcherIndex = index
                            onClicked: mouse => {
                                mouse.accepted = true
                                windowSwitcher.state.windowSwitcherIndex = index
                                windowSwitcher.state.acceptWindowSwitcher()
                            }
                        }
                    }
                }
            }
        }
    }
}
