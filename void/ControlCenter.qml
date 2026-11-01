import QtQuick
import QtQuick.Layouts
import Quickshell

// Titus ControlCenterWindow presentation (276 px card at x=6 below the bar,
// Nord popup background, 1 px border, transparent rows with hover fill).
// Actions are dispatched only through the user-local control-action.sh.
Item {
    id: root
    required property var panel
    required property string home
    required property string background
    required property string foreground
    required property string accent
    property string hover: "#4C566A"
    property string strong: "#ECEFF4"
    property bool opened: false
    signal powerRequested()
    width: 0; height: 0

    function run(action) {
        root.opened = false;
        Quickshell.execDetached(["sh", root.home + "control-action.sh", action,
            root.panel.screen.x.toString(), root.panel.screen.y.toString()]);
    }

    component MenuRow: Rectangle {
        id: row
        required property string label
        property bool navigates: false
        signal activated()
        Layout.fillWidth: true
        implicitHeight: 28
        radius: 6
        color: rowMouse.containsMouse ? root.hover : "transparent"
        Text {
            anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
            text: row.label
            color: rowMouse.containsMouse ? root.strong : root.foreground
            font.family: Typography.family; font.pixelSize: 13
        }
        Text {
            anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
            text: row.navigates ? ">" : ""
            color: rowMouse.containsMouse ? root.strong : root.foreground
            font.family: Typography.family; font.pixelSize: 13
        }
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.activated()
        }
    }
    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2; Layout.bottomMargin: 2
        implicitHeight: 1
        color: root.accent; opacity: 0.55
    }

    PopupWindow {
        id: popup
        objectName: "voidControlCenter"
        anchor.window: root.panel
        anchor.rect.x: 6
        anchor.rect.y: root.panel.height
        implicitWidth: 276
        implicitHeight: column.implicitHeight + 36
        visible: root.opened
        grabFocus: true
        color: root.background
        onVisibleChanged: { if (visible) card.forceActiveFocus(); else root.opened = false; }
        Rectangle {
            id: card
            anchors.fill: parent
            color: root.background
            border.width: 1
            border.color: root.accent
            radius: 0
            focus: true
            Keys.onEscapePressed: root.opened = false
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: "Kontrollzentrum"
                        color: root.foreground
                        font.family: Typography.family; font.pixelSize: 13; font.letterSpacing: 2
                    }
                    Text {
                        text: "x"
                        color: closeMouse.containsMouse ? root.accent : root.foreground
                        font.family: Typography.family; font.pixelSize: 13
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.opened = false }
                    }
                }
                Separator {}
                MenuRow { label: "Programme"; onActivated: root.run("apps") }
                MenuRow { label: "Power"; navigates: true; onActivated: { root.opened = false; root.powerRequested(); } }
                Separator {}
                MenuRow { label: "Terminal"; onActivated: root.run("terminal") }
                MenuRow { label: "Dateien"; onActivated: root.run("files") }
                MenuRow { label: "Tastenbelegung"; onActivated: root.run("hotkeys") }
                MenuRow { label: "Bildschirme"; onActivated: root.run("displays") }
                Separator {}
                MenuRow { label: "Lautstärke"; onActivated: root.run("volume") }
                MenuRow { label: "Netzwerk"; onActivated: root.run("network") }
                MenuRow { label: "Hintergrund"; onActivated: root.run("wallpaper") }
            }
        }
    }
}
