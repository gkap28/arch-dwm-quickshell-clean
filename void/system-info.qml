import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property var rows: []
    property string error: ""
    Process {
        id: reader
        command: ["sh", Quickshell.env("HOME") + "/.local/share/dwm-void/system-info.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const parts = line.split("\t");
                    if (!parts[0].startsWith("tool:")) result.push({label:parts[0],value:parts.slice(1).join(" ") || "Nicht verfügbar"});
                }
                root.rows = result;
            }
        }
        onExited: (code, status) => { root.error = code ? "Systemangaben konnten nicht vollständig gelesen werden." : ""; }
    }
    FloatingWindow {
        id: window
        title: "Void System Info"
        screen: Quickshell.screens.find(s => s.x === Number(Quickshell.env("DWM_VOID_LAUNCHER_X")) && s.y === Number(Quickshell.env("DWM_VOID_LAUNCHER_Y"))) || Quickshell.screens[0]
        implicitWidth: screen ? screen.width : 1280
        implicitHeight: screen ? screen.height : 800
        fullscreen: true
        color: CenterTheme.background
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()
        Rectangle {
            anchors.fill: parent; color: CenterTheme.background; border.width: 1; border.color: CenterTheme.border
            focus: true
            Keys.onEscapePressed: Qt.quit()
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "System Info"; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 18; font.bold: true }
                    CenterRow { text: "Aktualisieren"; implicitWidth: 130; enabled: !reader.running; onClicked: reader.running = true }
                    CenterRow { text: "Schließen ×"; implicitWidth: 120; onClicked: Qt.quit() }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: CenterTheme.border }
                Text { visible: root.error !== ""; text: root.error; color: CenterTheme.warning; font.family: Typography.family; font.pixelSize: 13 }
                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    ColumnLayout {
                        width: window.width - 48; spacing: 0
                        Repeater {
                            model: root.rows
                            Rectangle {
                                id: row
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true; implicitHeight: Math.max(44, values.implicitHeight + 20)
                                color: index % 2 ? CenterTheme.surface : CenterTheme.background
                                RowLayout {
                                    id: values
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                                    Text { Layout.preferredWidth: Math.min(240, window.width * 0.3); text: row.modelData.label; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 13; font.bold: true; wrapMode: Text.WordWrap }
                                    Text { Layout.fillWidth: true; text: row.modelData.value; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 13; wrapMode: Text.WordWrap }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}