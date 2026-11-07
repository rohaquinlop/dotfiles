-- ThinkPad: Caps Lock sends Backspace.
--
-- Omarchy maps Caps Lock to the compose key (compose:caps) in
-- default/hypr/input.lua. Setting kb_options here replaces that value for the
-- session: Caps Lock produces Backspace, and the Caps Lock compose sequences
-- (fcitx5 + ~/.XCompose) stop working. The layout still comes from
-- /etc/vconsole.conf, which Omarchy's default input config reads.
hl.config({
  input = {
    kb_options = "caps:backspace",
  },
})
