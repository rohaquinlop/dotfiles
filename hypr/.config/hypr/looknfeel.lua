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

-- Fully opaque windows (ported from windows.conf; performance preference).
-- Overrides Omarchy's default 0.985 opacity for the default-opacity tag.
o.window({ tag = "default-opacity" }, { opacity = "1 1" })
