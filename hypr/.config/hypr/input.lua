-- Personal input overrides, ported from the pre-quattro input.conf.

-- Caps Lock remapping is handled by keyd at evdev level, so Omarchy's
-- CapsLock-as-compose default is disabled here.
hl.config({
  input = {
    kb_options = "",

    -- Trackpad/mouse pointer sensitivity (default: 0).
    sensitivity = 0.25,

    touchpad = {
      -- Natural (inverse) scrolling.
      natural_scroll = true,
    },
  },
})

-- Realtek A5 Ultra mouse tweaks (scroll speed and sensitivity).
hl.device({ name = "realtek-a5-ultra", scroll_factor = 1.5, sensitivity = -0.75 })
