pragma ComponentBehavior: Bound

import Quickshell
import "../services"

Scope {
    id: screenShell
    required property var modelData
    required property ShellState state
    required property ClockService clocks
    required property UsageService usage
    required property ControlService controls
    required property Theme theme

    Bar {
        modelData: screenShell.modelData
        state: screenShell.state
        clocks: screenShell.clocks
        theme: screenShell.theme
        usage: screenShell.usage
    }

    ControlCenterDismiss {
        modelData: screenShell.modelData
        state: screenShell.state
        controls: screenShell.controls
    }

    ClockCenterDismiss {
        modelData: screenShell.modelData
        state: screenShell.state
        clocks: screenShell.clocks
    }

    ClockCenter {
        modelData: screenShell.modelData
        state: screenShell.state
        clocks: screenShell.clocks
        theme: screenShell.theme
    }

    ControlCenter {
        modelData: screenShell.modelData
        state: screenShell.state
        controls: screenShell.controls
        theme: screenShell.theme
    }

    WindowSwitcher {
        modelData: screenShell.modelData
        state: screenShell.state
        theme: screenShell.theme
    }

    Overview {
        modelData: screenShell.modelData
        state: screenShell.state
        theme: screenShell.theme
    }

}
