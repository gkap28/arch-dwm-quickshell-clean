import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var panel
    required property string home
    required property string background
    required property string foreground
    required property string accent
    property bool opened: false
    property string page: ""
    property string message: ""
    signal powerRequested()
    width: 0; height: 0
    onOpenedChanged: { page = ""; message = ""; }
    function run(action) {
        root.opened = false;
        Quickshell.execDetached(["sh", home + "control-action.sh", action, panel.screen.x.toString(), panel.screen.y.toString()]);
    }
    function reload(action) {
        if (operation.running) return;
        message = ""; operation.command = ["sh", home + "center-action.sh", action]; operation.running = true;
    }
    Process {
        id: operation
        stdout: StdioCollector { onStreamFinished: root.message = text.trim() }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.message = text.trim() }
        onExited: (code, status) => { if (code !== 0 && !root.message) root.message = "Aktion fehlgeschlagen."; }
    }
    component Separator: Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4
        implicitHeight: 1; color: CenterTheme.border; opacity: 0.55
    }
    Process {
        command: [root.home + "bar-bridge", "outside",
            (root.panel.screen.x + 6).toString(), (root.panel.screen.y + root.panel.height).toString(),
            popup.implicitWidth.toString(), popup.implicitHeight.toString()]
        running: root.opened
        stdout: SplitParser { onRead: data => { if (data.trim() === "outside") root.opened = false; } }
    }
    PopupWindow {
        id: popup
        objectName: "voidControlCenter"
        anchor.window: root.panel
        anchor.rect.x: 6; anchor.rect.y: root.panel.height
        implicitWidth: 276
        implicitHeight: column.implicitHeight + 16
        visible: root.opened
        grabFocus: true
        color: root.background
        onVisibleChanged: { if (visible) card.forceActiveFocus(); else root.opened = false; }
        Rectangle {
            id: card
            anchors.fill: parent; color: root.background
            border.width: 1; border.color: root.accent
            focus: true
            Keys.onEscapePressed: root.opened = false
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 28
                    Text { visible: root.page !== ""; text: "< Back"; color: backMouse.containsMouse ? CenterTheme.strong : CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 13; MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.page = ""; root.message = ""; } } }
                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: root.page || "Kontrollzentrum"; color: root.foreground; font.family: Typography.family; font.pixelSize: 13 }
                    CenterRow { text: "×"; implicitWidth: 28; onClicked: root.opened = false }
                }
                Separator {}
                ColumnLayout {
                    visible: root.page === ""; Layout.fillWidth: true; spacing: 2
                    CenterRow { Layout.fillWidth: true; text: "Programme"; onClicked: root.run("apps") }
                    CenterRow { Layout.fillWidth: true; text: "Power"; onClicked: { root.opened = false; root.powerRequested(); } }
                    CenterRow { Layout.fillWidth: true; text: "Quick Actions"; navigates: true; onClicked: root.page = text }
                    Separator {}
                    CenterRow { Layout.fillWidth: true; text: "Quick Widgets"; navigates: true; onClicked: root.page = text }
                    CenterRow { Layout.fillWidth: true; text: "Power Settings"; navigates: true; onClicked: root.page = text }
                    Separator {}
                    CenterRow { Layout.fillWidth: true; text: "Settings"; onClicked: root.page = text }
                    CenterRow { Layout.fillWidth: true; text: "System Info"; onClicked: root.run("system-info") }
                    CenterRow { Layout.fillWidth: true; text: "Keybinds"; onClicked: root.run("keybinds") }
                    Separator {}
                }
                ColumnLayout {
                    visible: root.page === "Quick Actions"; Layout.fillWidth: true; spacing: 2
                    CenterRow { Layout.fillWidth: true; text: "Reload Quickshell"; enabled: !operation.running; onClicked: root.reload("reload-quickshell") }
                    CenterRow { Layout.fillWidth: true; text: "Reload dwm"; enabled: !operation.running; onClicked: root.reload("reload-dwm") }
                    CenterRow { Layout.fillWidth: true; text: "Restart Picom"; enabled: !operation.running; onClicked: root.reload("restart-picom") }
                    CenterRow { Layout.fillWidth: true; text: "Restart NetworkManager"; enabled: !operation.running; onClicked: root.reload("restart-networkmanager") }
                }
                ColumnLayout {
                    visible: root.page === "Quick Widgets"; Layout.fillWidth: true; spacing: 2
                    Repeater {
                        model: [{key:"power",label:"Powermenu"},{key:"volume",label:"Volume"},{key:"network",label:"Netzwerk"},{key:"layout",label:"Layout"},{key:"seconds",label:"Clock seconds"}]
                        CenterRow {
                            required property var modelData
                            Layout.fillWidth: true; text: modelData.label
                            selected: CenterPreferences[modelData.key]
                            detail: selected ? "ON" : "OFF"; enabled: !CenterPreferences.busy
                            onClicked: CenterPreferences.setValue(modelData.key, selected ? 0 : 1)
                        }
                    }
                    Separator {}
                }
                Text {
                    visible: root.page === "Power Settings" || root.page === "Settings"
                    Layout.fillWidth: true; text: "Noch nicht eingerichtet"; color: root.foreground
                    font.family: Typography.family; font.pixelSize: 13; wrapMode: Text.WordWrap
                }
                Text {
                    visible: text !== ""; Layout.fillWidth: true
                    text: root.message || CenterPreferences.message
                    color: CenterTheme.warning; font.family: Typography.family; font.pixelSize: 12; wrapMode: Text.WordWrap
                }
            }
        }
    }
}
