-- Personal monitor setup, ported from the pre-quattro monitors.conf.
-- Omarchy's generic catch-all monitor rule (scale 1.25) stays active for
-- any other output; these two explicit rules override it.

hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@99.95", position = "1920x0", scale = 1 })
