-- Personal look'n'feel overrides, ported from the pre-quattro looknfeel.conf.

-- Gaming: allow tearing for lower input lag in fullscreen games.
hl.config({
  general = {
    allow_tearing = true,
  },

  -- Gaming: allow fullscreen apps to bypass the compositor (direct scanout).
  render = {
    direct_scanout = 1,
  },
})

-- Soften the window chrome. Omarchy defaults to rounding 0 with no shadow,
-- which reads as harsh next to a macOS desktop; the depth cue here is what
-- that look is actually missing. Blur stays off deliberately -- it is the
-- expensive part, and the opaque-window preference below depends on it.
hl.config({
  decoration = {
    rounding = 10,

    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      color = "rgba(00000055)",
    },
  },
})

-- Fully opaque windows (ported from windows.conf; performance preference).
-- Overrides Omarchy's default 0.985 opacity for the default-opacity tag.
o.window({ tag = "default-opacity" }, { opacity = "1 1" })

-- Pin the cursor theme (Omarchy ships no cursor theme default of its own).
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
