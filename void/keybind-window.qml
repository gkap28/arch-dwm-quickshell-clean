import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root
    title: "dwm control center utility"
    implicitWidth: 680
    implicitHeight: 500
    color: CenterTheme.background
    visible: true
    onVisibleChanged: if (!visible) Qt.quit()

    property var rows: []

    Process {
        id: reader
        command: ["sh", Quickshell.env("HOME") + "/.local/share/dwm-void/keybinds.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.rows = text.trim().split("\n").filter(l => l.length > 0).map(l => {
                    const parts = l.split("|");
                    return { keys: parts[0], description: parts[1] || "" };
                });
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: CenterTheme.background
        border.width: 1; border.color: CenterTheme.border
        focus: true
        Keys.onEscapePressed: Qt.quit()

        ColumnLayout {
            anchors { fill: parent; margins: 12 }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Keybinds"; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 15; font.bold: true }
                Text { text: "×"; color: CenterTheme.foreground; font.pixelSize: 18; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.quit() } }
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 4
                model: root.rows
                delegate: RowLayout {
                    required property var modelData
                    width: ListView.view.width
                    Text { Layout.preferredWidth: 220; text: modelData.keys; color: CenterTheme.border; font.family: Typography.family; font.pixelSize: 13 }
                    Text { Layout.fillWidth: true; text: modelData.description; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 13; elide: Text.ElideRight }
                }
            }
        }
    }
}
