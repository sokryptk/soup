//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import Quickshell
import "services"
import "components"

ShellRoot {
    Theme { id: shellTheme }
    ClockService { id: clockService }
    ControlService { id: controlService }
    UsageService {
        id: usageService
        theme: shellTheme
    }
    ShellState {
        id: shellState
        clocks: clockService
        controls: controlService
    }

    Variants {
        model: Quickshell.screens

        ScreenShell {
            state: shellState
            clocks: clockService
            controls: controlService
            usage: usageService
            theme: shellTheme
        }
    }
}
