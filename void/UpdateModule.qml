import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var panel
    required property string home
    required property string background
    required property string foreground
    required property string surface
    required property string accent
    width: 66; height: 28
    property bool opened: false
    property int xbpsCount: -1
    property int flatpakCount: -1
    property bool checked: false
    readonly property bool checking: status.running
    readonly property bool updating: action.running
    property string message: ""
    function refresh() { if (!status.running) status.running = true; }
    function countLabel(count) { return count < 0 ? "Nicht verfügbar" : count + " Updates"; }
    function update(kind) { if (action.running) return; message = ""; action.command = ["sh", home + "updates.sh", kind]; action.running = true; }
    Process {
        id: status
        command: ["sh", root.home + "updates.sh", "status"]
        running: true
        stdout: SplitParser { onRead: data => {
            const parts = data.trim().split("\t");
            if (parts.length === 2) { root.xbpsCount = Number(parts[0]); root.flatpakCount = Number(parts[1]); root.checked = true; }
        } }
    }
    Process {
        id: action
        onExited: (code, exitStatus) => { if (code !== 0) root.message = "Terminal oder Update-Programm nicht verfügbar."; root.refresh(); }
    }
    Timer { interval: 300000; repeat: true; running: true; onTriggered: root.refresh() }
    Timer { interval: 10000; repeat: true; running: root.opened; onTriggered: root.refresh() }
    Rectangle {
        anchors.centerIn: parent; width: parent.width; height: 26; radius: 6
        color: mouse.containsMouse || root.opened ? root.surface : root.background
        border.width: 1; border.color: root.opened ? root.accent : root.surface
        Row {
            anchors.centerIn: parent; spacing: 4
            Image { source: "update-symbol.svg"; width: 13; height: 13; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: !root.checked ? "…" : root.xbpsCount < 0 && root.flatpakCount < 0 ? "—" : (root.xbpsCount < 0 || root.flatpakCount < 0 ? "~" : "") + (Math.max(0,root.xbpsCount)+Math.max(0,root.flatpakCount))
                color: root.foreground; font.family: "monospace"; font.pixelSize: 14
            }
        }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.opened = !root.opened; if (root.opened) root.refresh(); } }
    }
    PopupWindow {
        anchor.window: root.panel; anchor.rect.x: Math.max(0, (root.panel.width - implicitWidth) / 2); anchor.rect.y: root.panel.height
        implicitWidth: Math.min(380, root.panel.width)
        implicitHeight: content.implicitHeight + 32
        visible: root.opened; grabFocus: true; color: root.background
        onVisibleChanged: if (visible) card.forceActiveFocus()
        MouseArea { anchors.fill: parent; onClicked: root.opened = false }
        Rectangle {
            id: card
            x: 0; width: parent.width
            height: content.implicitHeight+32
            color: root.background; border.width: 1; border.color: root.accent; radius: 0
            Keys.onEscapePressed: root.opened = false
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Updates"; color: root.foreground; font.family: "monospace"; font.pixelSize: 20; font.bold: true; Layout.fillWidth: true }
                    Text { text: "×"; color: root.foreground; font.pixelSize: 18; MouseArea { anchors.fill: parent; onClicked: root.opened = false } }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: root.surface }
                Repeater {
                    model: [{kind:"xbps",label:"XBPS",count:root.xbpsCount},{kind:"flatpak",label:"Flatpak",count:root.flatpakCount}]
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            Text { text: modelData.label; color: root.foreground; font.family: "monospace"; font.pixelSize: 14; font.bold: true }
                            Text { text: root.checking && !root.checked ? "Wird geprüft …" : root.countLabel(modelData.count); color: root.accent; font.family: "monospace"; font.pixelSize: 12 }
                        }
                        Button {
                            id: updateButton
                            text: modelData.label + " updaten"
                            enabled: modelData.count >= 0 && !root.updating
                            implicitHeight: 38; implicitWidth: 156
                            font.family: "monospace"; font.pixelSize: 12
                            onClicked: root.update(modelData.kind)
                            contentItem: Text { text: updateButton.text; color: root.foreground; font: updateButton.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; opacity: updateButton.enabled ? 1 : 0.45 }
                            background: Rectangle { color: updateButton.hovered ? root.surface : root.background; radius: 6; border.width: 1; border.color: root.accent }
                        }
                    }
                }
                Text { text: root.message; visible: text !== ""; color: root.accent; font.family: "monospace"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Button {
                    id: refreshButton
                    text: status.running ? "Prüfe …" : "Erneut prüfen"; enabled: !status.running
                    Layout.fillWidth: true; implicitHeight: 32
                    onClicked: root.refresh()
                    contentItem: Text { text: refreshButton.text; color: root.foreground; font.family: "monospace"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: refreshButton.hovered ? root.surface : root.background; radius: 6; border.width: 1; border.color: root.surface }
                }
            }
        }
    }
}