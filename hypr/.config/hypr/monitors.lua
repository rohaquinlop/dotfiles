-- Personal monitor setup, ported from the pre-quattro monitors.conf.
-- Omarchy's generic catch-all monitor rule (scale 1.25) stays active for
-- any other output; these two explicit rules override it.

-- eDP-1 is 1920x1200 on a 300x190 mm panel = 162 DPI, so scale 1 renders
-- everything far too small. 1.25 (~130 effective DPI) is what it has actually
-- been running at; declaring it here stops the config fighting the runtime.
-- hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1.25 })
-- ^ imported into the omarchy-display-settings block below

-- HDMI-A-1 is a 27" 1440p panel = 109 DPI. Scale 1.6 collapsed it to a
-- 1600x900 logical desktop, which is why it looked worse than the laptop.
-- Scale 1 gives back the full 2560x1440; comfort comes from font sizes.
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@59.95", position = "1920x0", scale = 1.25 })
-- ^ imported into the omarchy-display-settings block below

-- >>> omarchy-display-settings (generated) — do not edit inside this block >>>
-- eDP-1 · 1920x1200@60.00 · 14.0" · 162.0 PPI · scale 1.25 → 129.6 effective PPI
hl.monitor({ output = "eDP-1", mode = "1920x1200@60.00", position = "0x0", scale = 1.25, transform = 0 })

-- Primary display: where the pointer starts, and the home of workspace 1.
hl.config({ cursor = { default_monitor = "eDP-1" } })
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
-- <<< omarchy-display-settings <<<
