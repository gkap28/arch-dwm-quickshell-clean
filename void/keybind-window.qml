import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root
    title: "dwm control center utility"
    screen: Quickshell.screens.find(s => s.x === Number(Quickshell.env("DWM_VOID_LAUNCHER_X")) && s.y === Number(Quickshell.env("DWM_VOID_LAUNCHER_Y"))) || Quickshell.screens[0]
    implicitWidth: 680
    implicitHeight: 500
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: "#2E3440"
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
        color: "#2E3440"
        border.width: 1; border.color: "#81A1C1"
        focus: true
        Keys.onEscapePressed: Qt.quit()

        ColumnLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Keybinds"; color: "#ECEFF4"; font.family: Typography.family; font.pixelSize: 18; font.bold: true }
                Text { text: "×"; color: "#D8DEE9"; font.pixelSize: 18; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.quit() } }
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 4
                model: root.rows
                delegate: RowLayout {
                    required property var modelData
                    width: ListView.view.width
                    Text { Layout.preferredWidth: 220; text: modelData.keys; color: "#81A1C1"; font.family: Typography.family; font.pixelSize: 13 }
                    Text { Layout.fillWidth: true; text: modelData.description; color: "#D8DEE9"; font.family: Typography.family; font.pixelSize: 13; elide: Text.ElideRight }
                }
            }
        }
    }
}
