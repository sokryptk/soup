-- Quickshell overview integration for the Lua-based Hyprland configuration.
-- Load this file from hyprland.lua after installing the Quickshell files.

hl.on("hyprland.start", function ()
    hl.exec_cmd("quickshell --no-duplicate --daemonize")
end)

hl.layer_rule({
    name = "frosted-workspace-overview",
    match = { namespace = "^quickshell-overview$" },
    order = 2,
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.0,
    xray = false,
})

hl.bind("XF86LaunchA", hl.dsp.exec_cmd("quickshell ipc call overview toggle"),
    { description = "Toggle workspace overview" })
hl.bind("mouse:277", hl.dsp.exec_cmd("quickshell ipc call overview toggle"),
    { description = "Toggle workspace overview" })
