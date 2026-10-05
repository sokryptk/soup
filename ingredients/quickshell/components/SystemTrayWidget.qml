pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../services"

Row {
    id: systemTrayWidget
    required property Theme theme
    required property var panelWindow

    spacing: 3

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: trayItem
            required property SystemTrayItem modelData
            width: 22
            height: 22
            radius: 6
            color: trayMouse.containsMouse ? systemTrayWidget.theme.surface : "transparent"

            IconImage {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: trayItem.modelData.icon
                asynchronous: true
            }

            QsMenuOpener {
                id: trayMenuModel
                menu: trayItem.modelData.menu
            }

            PopupWindow {
                id: trayMenu
                anchor.window: systemTrayWidget.panelWindow
                anchor.item: trayItem
                anchor.rect.x: trayItem.width - width
                anchor.rect.y: trayItem.height + 3
                implicitWidth: 220
                implicitHeight: trayMenuColumn.implicitHeight + 12
                visible: false
                color: "transparent"
                grabFocus: true

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "#ed242527"
                    border.width: 1
                    border.color: "#35ffffff"

                    Column {
                        id: trayMenuColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6

                        Repeater {
                            model: trayMenuModel.children

                            Item {
                                id: menuEntry
                                required property QsMenuEntry modelData
                                width: trayMenuColumn.width
                                height: modelData.isSeparator ? 9 : 32

                                Rectangle {
                                    visible: menuEntry.modelData.isSeparator
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    height: 1
                                    color: "#28ffffff"
                                }

                                Rectangle {
                                    visible: !menuEntry.modelData.isSeparator
                                    anchors.fill: parent
                                    radius: 7
                                    color: menuEntryMouse.containsMouse
                                           ? systemTrayWidget.theme.surface : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        IconImage {
                                            visible: menuEntry.modelData.icon !== ""
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            source: menuEntry.modelData.icon
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: menuEntry.modelData.text
                                            color: menuEntry.modelData.enabled
                                                   ? systemTrayWidget.theme.text : systemTrayWidget.theme.muted
                                            elide: Text.ElideRight
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            visible: menuEntry.modelData.buttonType
                                                     !== QsMenuButtonType.None
                                            text: menuEntry.modelData.checkState === Qt.Checked
                                                  ? "✓" : ""
                                            color: systemTrayWidget.theme.accent
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            visible: menuEntry.modelData.hasChildren
                                            text: "›"
                                            color: systemTrayWidget.theme.muted
                                            font.pixelSize: 15
                                        }
                                    }

                                    MouseArea {
                                        id: menuEntryMouse
                                        anchors.fill: parent
                                        enabled: menuEntry.modelData.enabled
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (menuEntry.modelData.hasChildren)
                                                menuEntry.modelData.display(trayMenu,
                                                    trayMenu.width, menuEntry.y)
                                            else {
                                                menuEntry.modelData.triggered()
                                                trayMenu.visible = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                        trayMenu.visible = !trayMenu.visible
                    else if (mouse.button === Qt.MiddleButton)
                        trayItem.modelData.secondaryActivate()
                    else if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu)
                        trayMenu.visible = !trayMenu.visible
                    else
                        trayItem.modelData.activate()
                }

                onWheel: wheel => trayItem.modelData.scroll(
                    wheel.angleDelta.y || wheel.angleDelta.x,
                    wheel.angleDelta.x !== 0)
            }
        }
    }
}
