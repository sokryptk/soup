pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

PanelWindow {
    required property ShellState state
    required property Theme theme

    id: overview
    required property var modelData
    property var focusedWorkspace: null
    readonly property var activeWorkspace: Hyprland.workspaces.values.find(workspace =>
        workspace.id > 0
        && workspace.monitor === Hyprland.monitorFor(overview.screen)
        && workspace.active) ?? null
    screen: modelData
    visible: overview.state.overviewOpen && modelData.name === overview.state.overviewScreenName
    color: "#1a808080"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"

    onVisibleChanged: {
        if (visible) {
            focusedWorkspace = activeWorkspace
        }
    }

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    Rectangle {
        id: overviewSurface
        anchors.fill: parent
        color: "transparent"
        focus: overview.visible

        Keys.onEscapePressed: overview.state.closeOverview()

        MouseArea {
            anchors.fill: parent
            onClicked: overview.state.closeOverview()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18

                Rectangle {
                    id: workspaceRail
                    Layout.preferredWidth: 268
                    Layout.fillHeight: true
                    radius: 18
                    color: "transparent"
                    border.width: 0
                    z: 10
                    transform: [
                        Rotation {
                            origin.x: 0
                            origin.y: workspaceRail.height / 2
                            angle: -1.6
                        }
                    ]

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 0

                        ListView {
                            id: workspaceList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10
                            clip: true
                            model: ScriptModel {
                                values: Hyprland.workspaces.values.filter(workspace =>
                                    workspace.id > 0
                                    && workspace.monitor === Hyprland.monitorFor(overview.screen))
                            }

                            delegate: Rectangle {
                                id: workspaceCard
                                required property var modelData
                                readonly property int windowCount:
                                    modelData.toplevels?.values?.length ?? 0
                                width: workspaceList.width
                                height: 148
                                radius: 15
                                color: overview.focusedWorkspace === modelData
                                       ? "#b52a4057" : "#7a182336"
                                border.width: overview.focusedWorkspace === modelData ? 2 : 0
                                border.color: overview.focusedWorkspace === modelData
                                              ? overview.theme.accent : "transparent"
                                scale: overview.focusedWorkspace === modelData ? 1.0 : 0.95
                                opacity: overview.focusedWorkspace === modelData ? 1.0 : 0.78

                                Behavior on scale { NumberAnimation { duration: 150 } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                Item {
                                    id: workspaceThumb
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 7
                                    height: 106
                                    clip: true

                                    Grid {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        columns: Math.min(2, workspaceCard.windowCount || 1)
                                        columnSpacing: 4
                                        rowSpacing: 4

                                        Repeater {
                                            model: ScriptModel {
                                                values: workspaceCard.modelData.toplevels?.values ?? []
                                            }

                                            Rectangle {
                                                required property var modelData
                                                width: Math.max(64, (workspaceThumb.width - 18
                                                       - Math.min(1, workspaceCard.windowCount - 1) * 4)
                                                       / Math.min(2, workspaceCard.windowCount || 1))
                                                height: workspaceCard.windowCount > 2 ? 45 : 82
                                                radius: 6
                                                color: "#0c111d"
                                                border.width: 0
                                                border.color: "transparent"
                                                clip: true

                                                ScreencopyView {
                                                    id: workspacePreviewSource
                                                    anchors.fill: parent
                                                    captureSource: overview.state.overviewOpen
                                                                   && overview.state.screenIsCaptureable(overview.state.overviewScreenName)
                                                                   && overview.state.toplevelIsCaptureable(parent.modelData)
                                                                   ? parent.modelData.wayland : null
                                                    live: overview.state.overviewOpen
                                                    paintCursor: false
                                                    constraintSize.width: parent.width
                                                    constraintSize.height: parent.height
                                                }

                                                FastBlur {
                                                    anchors.fill: workspacePreviewSource
                                                    source: workspacePreviewSource
                                                    radius: 7
                                                    opacity: 0.22
                                                    transparentBorder: false
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: workspaceCard.windowCount === 0
                                        text: "Empty space"
                                        color: overview.theme.muted
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.bottomMargin: 8
                                    text: "Desktop " + workspaceCard.modelData.name
                                    color: overview.theme.text
                                    elide: Text.ElideRight
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: overview.focusedWorkspace = workspaceCard.modelData
                                    onClicked: {
                                        overview.focusedWorkspace = workspaceCard.modelData
                                        overview.state.activateWorkspace(workspaceCard.modelData)
                                        overview.state.closeOverview()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: focusedWorkspacePane
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 22
                    color: "transparent"
                    border.width: 0
                    border.color: overview.focusedWorkspace?.active
                                  ? overview.theme.accent : "#30455f"

                    readonly property var focusedWindows:
                        overview.focusedWorkspace?.toplevels?.values ?? []
                    readonly property int windowCount: focusedWindows.length
                    readonly property var sourceMonitor:
                        Hyprland.monitorFor(overview.screen)
                    readonly property real sourceScale:
                        Math.max(1, sourceMonitor?.scale ?? 1)
                    readonly property real sourceWidth:
                        sourceMonitor ? sourceMonitor.width / sourceScale : width
                    readonly property real sourceHeight:
                        sourceMonitor ? sourceMonitor.height / sourceScale : height
                    readonly property real sourceX: sourceMonitor?.x ?? 0
                    readonly property real sourceY: sourceMonitor?.y ?? 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 0

                        Item {
                            id: workspaceCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            readonly property real previewScale: Math.max(0.1,
                                Math.min((width - 96) / focusedWorkspacePane.sourceWidth,
                                         (height - 76) / focusedWorkspacePane.sourceHeight)
                                * 0.84)

                            Item {
                                id: windowStage
                                anchors.centerIn: parent
                                width: focusedWorkspacePane.sourceWidth
                                       * workspaceCanvas.previewScale
                                height: focusedWorkspacePane.sourceHeight
                                        * workspaceCanvas.previewScale

                                Repeater {
                                    model: ScriptModel {
                                        values: focusedWorkspacePane.focusedWindows.filter(window =>
                                            window.wayland !== null)
                                    }

                                    delegate: Item {
                                        id: floatingWindow
                                        required property var modelData
                                        required property int index
                                        readonly property var ipc:
                                            modelData.lastIpcObject ?? ({})
                                        readonly property var windowPosition:
                                            ipc.at ?? [focusedWorkspacePane.sourceX,
                                                       focusedWorkspacePane.sourceY]
                                        readonly property var windowSize:
                                            ipc.size ?? [focusedWorkspacePane.sourceWidth,
                                                         focusedWorkspacePane.sourceHeight]
                                        x: (windowPosition[0] - focusedWorkspacePane.sourceX)
                                           * workspaceCanvas.previewScale
                                        y: (windowPosition[1] - focusedWorkspacePane.sourceY)
                                           * workspaceCanvas.previewScale
                                        width: Math.max(48, windowSize[0]
                                               * workspaceCanvas.previewScale)
                                        height: Math.max(36, windowSize[1]
                                                * workspaceCanvas.previewScale)
                                        scale: floatingWindowMouse.containsMouse ? 1.018 : 1.0
                                        z: modelData.activated ? 100 : floatingWindow.index + 1

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        RectangularGlow {
                                            anchors.fill: floatingWindowCard
                                            glowRadius: 22
                                            spread: 0.10
                                            color: "#9e000000"
                                            cornerRadius: floatingWindowCard.radius + glowRadius
                                        }

                                        Rectangle {
                                            id: floatingWindowCard
                                            anchors.fill: parent
                                            radius: 14
                                            color: "#101824"
                                            border.width: floatingWindowMouse.containsMouse ? 2 : 0
                                            border.color: floatingWindowMouse.containsMouse
                                                          ? overview.theme.accent : "transparent"
                                            clip: true

                                            ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: overview.state.overviewOpen
                                                               && overview.state.screenIsCaptureable(overview.state.overviewScreenName)
                                                               && overview.state.toplevelIsCaptureable(floatingWindow.modelData)
                                                               ? floatingWindow.modelData.wayland : null
                                                live: overview.state.overviewOpen
                                                paintCursor: false
                                                constraintSize.width: floatingWindow.width
                                                constraintSize.height: floatingWindow.height
                                            }

                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 10
                                                width: Math.min(parent.width - 18,
                                                                floatingWindowTitle.implicitWidth + 24)
                                                height: 30
                                                radius: 15
                                                visible: floatingWindowMouse.containsMouse
                                                color: "#d91a2637"

                                                Text {
                                                    id: floatingWindowTitle
                                                    anchors.centerIn: parent
                                                    width: parent.width - 20
                                                    text: floatingWindow.modelData.title || "Untitled"
                                                    color: overview.theme.text
                                                    elide: Text.ElideRight
                                                    horizontalAlignment: Text.AlignHCenter
                                                    font.family: "SF Pro Text"
                                                    font.pixelSize: 12
                                                    font.weight: Font.Medium
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: floatingWindowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                overview.state.activateWorkspace(overview.focusedWorkspace)
                                                if (floatingWindow.modelData.wayland)
                                                    floatingWindow.modelData.wayland.activate()
                                                overview.state.closeOverview()
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: focusedWorkspacePane.windowCount === 0
                                text: "No windows in this space"
                                color: overview.theme.muted
                                font.family: "SF Pro Text"
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }
    }
}
