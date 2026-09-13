// Palette for the login screen. Main.qml reads these four properties.
//
// This repo copy holds the Akane defaults: it is what
// `sddm-greeter-qt6 --test-mode --theme system/sddm/themes/cachyos` renders, and
// what the greeter uses until /usr/local/bin/sddm-theme-sync has run once (that
// script regenerates the *installed* copy from Noctalia's active palette on every
// wallpaper or palette change, so the login screen follows the desktop).
import QtQuick 2.0

QtObject {
    property color bgColor: "#12101c"      // surface, the theme's $color
    property color accentColor: "#e15a48"  // primary, the theme's $outer_color
    property color textColor: "#f0c4a8"    // on_surface, the theme's $font_color
    property color dangerColor: "#d6453d"  // error, the theme's red
}
