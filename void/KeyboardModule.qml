import QtQuick
import Quickshell.Io

Rectangle {
    id: root
    required property string home
    required property string foreground
    required property string surface
    required property string accent
    property string layout: "—"
    width: 36; height: 26; y: 1; radius: 6
    color: mouse.containsMouse ? surface : "transparent"
    border.width: 1; border.color: mouse.containsMouse ? accent : "transparent"
    Process {
        id: reader
        command: [root.home + "keyboard-bridge", "status"]
        running: true
        stdout: SplitParser { onRead: data => root.layout = data.trim() }
    }
    Process {
        id: change
        command: [root.home + "keyboard-bridge", "next"]
        stdout: SplitParser { onRead: data => root.layout = data.trim() }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: if (!reader.running && !change.running) reader.running = true }
    Text { anchors.centerIn: parent; text: root.layout; color: root.foreground; font.family: Typography.family; font.pixelSize: 14 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (!change.running) change.running = true }
}