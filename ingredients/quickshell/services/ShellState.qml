import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    required property ClockService clocks
    required property ControlService controls

    id: root

    property bool overviewOpen: false
    property string overviewScreenName: ""
    property bool windowSwitcherOpen: false
    property string windowSwitcherScreenName: ""
    property var windowSwitcherWindows: []
    property int windowSwitcherIndex: 0
    property bool controlCenterOpen: false
    property string controlCenterScreenName: ""
    property bool clockCenterOpen: false
    property string clockCenterScreenName: ""

    function screenIsCaptureable(screenName): bool {
        if (!screenName)
            return false

        return Quickshell.screens.some(screen =>
            screen.name === screenName && Hyprland.monitorFor(screen) !== null)
    }

    function toplevelIsCaptureable(toplevel): bool {
        return toplevel?.wayland
            && Hyprland.toplevels.values.includes(toplevel)
    }

    function openOverview(targetScreen): void {
        const selectedScreen = targetScreen ?? Quickshell.screens.find(candidate =>
            Hyprland.monitorFor(candidate) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        overviewScreenName = selectedScreen?.name ?? ""
        overviewOpen = true
    }

    function toggleOverview(targetScreen): void {
        if (overviewOpen)
            closeOverview()
        else
            openOverview(targetScreen)
    }

    function closeOverview(): void {
        overviewOpen = false
    }

    function activateWorkspace(workspace): void {
        if (!workspace)
            return
        const selector = "name:" + workspace.name
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + JSON.stringify(selector) + " })")
        else
            Hyprland.dispatch("workspace " + selector)
    }

    function openWindowSwitcher(reverse): void {
        const selectedScreen = Quickshell.screens.find(candidate =>
            Hyprland.monitorFor(candidate) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        const active = Hyprland.activeToplevel
        const activeWorkspace = active?.workspace ?? null
        const windows = Hyprland.toplevels.values.filter(toplevel =>
            toplevel.wayland && toplevel.workspace === activeWorkspace)
        windows.sort((left, right) => left === active ? -1 : right === active ? 1 : 0)
        windowSwitcherScreenName = selectedScreen?.name ?? ""
        windowSwitcherWindows = windows
        windowSwitcherIndex = windows.length < 2 ? 0 : reverse ? windows.length - 1 : 1
        windowSwitcherOpen = windows.length > 0
    }

    function cycleWindowSwitcher(reverse): void {
        if (!windowSwitcherOpen) {
            openWindowSwitcher(reverse)
            return
        }
        const count = windowSwitcherWindows.length
        if (count > 0)
            windowSwitcherIndex = (windowSwitcherIndex + (reverse ? count - 1 : 1)) % count
    }

    function acceptWindowSwitcher(): void {
        if (!windowSwitcherOpen || windowSwitcherWindows.length === 0)
            return
        const selected = windowSwitcherWindows[windowSwitcherIndex]
        windowSwitcherOpen = false
        if (selected.wayland)
            selected.wayland.activate()
    }

    function closeWindowSwitcher(): void {
        windowSwitcherOpen = false
    }

    function toggleControlCenter(targetScreen): void {
        controlCenterScreenName = targetScreen?.name ?? ""
        clockCenterOpen = false
        controlCenterOpen = !controlCenterOpen
    }

    function toggleClockCenter(targetScreen): void {
        clockCenterScreenName = targetScreen?.name ?? ""
        controlCenterOpen = false
        controls.wifiExpanded = false
        controls.bluetoothExpanded = false
        controls.outputExpanded = false
        if (!clockCenterOpen) {
            clocks.calendarYear = clocks.clock.date.getFullYear()
            clocks.calendarMonth = clocks.clock.date.getMonth()
            if (!clocks.refreshProcess.running)
                clocks.refreshProcess.running = true
        }
        clockCenterOpen = !clockCenterOpen
    }

    IpcHandler {
        target: "overview"

        function toggle(): void { root.toggleOverview(null) }
        function open(): void { root.openOverview(null) }
        function close(): void { root.closeOverview() }
        function activate(name: string): void {
            root.activateWorkspace(Hyprland.workspaces.values.find(workspace =>
                workspace.name === name) ?? null)
        }
    }

    IpcHandler {
        target: "windowSwitcher"

        function next(): void { root.cycleWindowSwitcher(false) }
        function previous(): void { root.cycleWindowSwitcher(true) }
        function accept(): void { root.acceptWindowSwitcher() }
        function close(): void { root.closeWindowSwitcher() }
    }
}
