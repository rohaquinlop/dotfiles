// CachyOS login screen for SDDM.
//
// Minimal greeter in the spirit of Omarchy's: the distro's own boot wordmark,
// a padlock and a single password box — no user list, no session picker, no
// clock, no username label. The QML is adapted from Omarchy's SDDM theme
// (MIT, (c) David Heinemeier Hansson, https://github.com/basecamp/omarchy,
// default/sddm/omarchy); the artwork is CachyOS's own. Failures are shown by
// turning the padlock and the box red, the way Omarchy does.
//
// Install: copied to /usr/share/sddm/themes/cachyos by install.sh.
// Preview without rebooting:
//   sddm-greeter-qt6 --test-mode --theme system/sddm/themes/cachyos
import QtQuick 2.0
import QtQuick.Window 2.2
import SddmComponents 2.0

Rectangle {
    id: root

    // Colours follow the Akane theme's own lock screen recipe, the variables in
    // its hyprlock.conf: $color (background) #12101c, $outer_color (field
    // outline) #e15a48, $font_color (text and dots) #f0c4a8. The field fill is
    // $inner_color, the same colour as the background, so it stays transparent
    // here. Failures use the palette's red, plus a faint fill, because the
    // accent itself is already vermillion.
    readonly property color bgColor: "#12101c"      // akane $color
    readonly property color accentColor: "#e15a48"  // akane $outer_color
    readonly property color textColor: "#f0c4a8"    // akane $font_color
    readonly property color dangerColor: "#d6453d"  // akane red

    // The layout is designed for 1920x1200. Screen.height is in logical pixels,
    // so on a HiDPI panel SDDM's scale factor cancels out and every element
    // keeps the same physical size (and the wordmark its exact pixel grid).
    readonly property real s: (Screen.height > 0 ? Screen.height : 1200) / 1200

    // sddm exposes the item-model roles to QML as bare numbers only
    // (UserModel::NameRole, SessionModel::NameRole in sddm/src/greeter).
    readonly property int userNameRole: 257
    readonly property int sessionNameRole: 260

    width: Screen.width
    height: Screen.height
    color: bgColor
    clip: true

    // Wallpaper background, made by system/sddm/make-background.sh from the
    // current Noctalia wallpaper — the Akane theme puts its own lock screen on
    // the wallpaper too. The flat colour above stays as the fallback.
    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    property bool loginFailed: false

    // Normally SDDM remembers the last user (RememberLastUser=true).
    property string currentUser: userModel.lastUser !== "" ? userModel.lastUser
                                                           : (userModel.data(userModel.index(0, 0), userNameRole) || "").toString()

    // niri is the only session installed; SDDM's own last-used index is the
    // fallback.
    property int sessionIndex: {
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            var name = (sessionModel.data(sessionModel.index(i, 0), sessionNameRole) || "").toString()
            if (name.indexOf("niri") !== -1)
                return i
        }
        return sessionModel.lastIndex
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.loginFailed = true
            password.text = ""
            password.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.loginFailed = false
        }
    }

    // Input row geometry at the design size (see the 1920x1200 reference).
    // The padlock hangs to the left of the box, and an empty spacer of the same
    // width balances the row on the right: the password box then sits on the
    // screen's centre line, the same line the wordmark is centred on.
    readonly property real padlockWidth: 35 * s
    readonly property real padlockHeight: 40 * s
    readonly property real rowGap: 13 * s
    readonly property real boxWidth: 240 * s
    readonly property real boxHeight: 40 * s

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 26 * root.s
        opacity: 0

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "wordmark.png"
            // White mark built from the vector emblem plus the terminal font's
            // heavy cut: 773x145 native, smooth art, so it stays sharp at any
            // scale instead of showing the old bitmap's pixel blocks.
            width: 773 * root.s
            height: 145 * root.s
            smooth: true
            fillMode: Image.PreserveAspectFit
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.rowGap

            // Padlock: a ring whose lower half is covered by the body. Sized to
            // the password box height (35x40 vs the box's 240x40) so the row
            // stays quiet under the small native wordmark.
            Item {
                id: padlock
                anchors.verticalCenter: parent.verticalCenter
                width: root.padlockWidth
                height: root.padlockHeight

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 21 * root.s
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 5 * root.s
                    border.color: root.loginFailed ? root.dangerColor : root.accentColor
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 25 * root.s
                    radius: 5 * root.s
                    color: root.loginFailed ? root.dangerColor : root.accentColor

                    Rectangle {
                        anchors.centerIn: parent
                        width: 7 * root.s
                        height: 12 * root.s
                        radius: width / 2
                        color: root.bgColor
                    }
                }
            }

            // Password box.
            Item {
                id: entry
                anchors.verticalCenter: parent.verticalCenter
                width: root.boxWidth
                height: root.boxHeight

                Rectangle {
                    anchors.fill: parent
                    // $inner_color in the theme's hyprlock.conf: the background
                    // colour at 80%, which keeps the field readable over the
                    // wallpaper.
                    color: "#cc12101c"
                }

                // Failure tint, stacked on top of that fill rather than replacing
                // it - otherwise the field would become see-through exactly when
                // the error needs to be clear.
                Rectangle {
                    anchors.fill: parent
                    color: "#66d6453d"
                    visible: root.loginFailed
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2 * root.s
                    border.color: root.loginFailed ? root.dangerColor : root.accentColor
                }

                // Bullets are drawn by hand (21 fits the box exactly), so the
                // password never depends on the greeter's fonts.
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 17 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4 * root.s

                    Repeater {
                        model: Math.min(password.text.length, 21)

                        Rectangle {
                            width: 6 * root.s
                            height: width
                            radius: width / 2
                            color: root.textColor // dots use the theme's font colour
                        }
                    }
                }

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 17 * root.s
                    anchors.rightMargin: 17 * root.s
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    font.pixelSize: 20 * root.s
                    color: "transparent"
                    selectionColor: "transparent"
                    selectedTextColor: "transparent"
                    cursorDelegate: Item {}
                    focus: true

                    onTextChanged: root.loginFailed = false

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(root.currentUser, password.text, root.sessionIndex)
                            event.accepted = true
                        }
                    }
                }
            }

            // Balances the padlock (same width, plus the row gap) so the box
            // above stays on the centre line of the screen.
            Item {
                width: root.padlockWidth
                height: 1
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: column
        property: "opacity"
        from: 0
        to: 1
        duration: 220
        easing.type: Easing.OutCubic
    }

    Component.onCompleted: {
        password.forceActiveFocus()
        fadeIn.start()
    }
}
