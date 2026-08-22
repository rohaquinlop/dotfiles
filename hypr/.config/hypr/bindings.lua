-- Personal keybinding overrides, ported from the pre-quattro bindings.conf.
-- Omarchy's default bindings stay active; only differences are overridden here.

-- SUPER+Q: terminal (extra binding kept from the old config).
o.bind("SUPER + Q", "Terminal", { omarchy = "terminal" })

-- SUPER+SHIFT+W: Typora instead of Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Typora", { launch = "typora --enable-wayland-ime" })

-- SUPER+SHIFT+S: area screenshot instead of Google Maps.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Area screenshot", "omarchy-capture-screenshot region slurp")

-- SUPER+/ and SUPER+ALT+/ : freed for herdr (were: monitor scaling up/down).
hl.unbind("SUPER + SLASH")
hl.unbind("SUPER + ALT + SLASH")
