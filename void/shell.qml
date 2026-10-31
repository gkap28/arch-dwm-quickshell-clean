import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
    id: root
    property var monitors: []
    property string status: ""
    readonly property string normal: "#2E3440"
    readonly property string active: "#434C5E"
    readonly property string foreground: "#D8DEE9"
    readonly property string accent: "#88C0D0"
    readonly property string home: Quickshell.env("HOME") + "/.local/share/dwm-void/"
    Process {
        command: [root.home + "bar-bridge", "watch"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try { const state = JSON.parse(data); root.monitors = state.monitors; root.status = state.status; }
                catch (error) { console.warn("Void bar state:", error); }
            }
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: true
            anchors { top: true; left: true; right: true }
            implicitHeight: 28
            exclusiveZone: -1
            aboveWindows: true
            color: root.normal
            readonly property var monitor: root.monitors.find(m => m.x === screen.x && m.y === screen.y)
            Row {
                id: workspaces
                anchors.left: parent.left
                height: parent.height
                Item {
                    width: 28; height: 28
                    Image { anchors.centerIn: parent; width: 22; height: 22; source: "logo.svg" }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([root.home + "power-menu", "--control"]) }
                }
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        width: 28; height: 28
                        color: panel.monitor && panel.monitor.desktop === index ? root.active : root.normal
                        Text { anchors.centerIn: parent; text: index + 1; color: root.foreground; font.family: "monospace"; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached([root.home + "bar-bridge", "view", index.toString(), panel.screen.x.toString(), panel.screen.y.toString()])
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                width: Math.max(0, parent.width - 2 * workspaces.width - 16)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.status
                color: root.foreground
                font.family: "monospace"; font.pixelSize: 14
            }
            Item {
                anchors.right: parent.right
                width: 28; height: 28
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const c = getContext("2d"); c.reset(); c.strokeStyle = root.foreground; c.lineWidth = 2; c.lineCap = "round";
                        c.beginPath(); c.arc(14, 15, 7, -Math.PI / 4, Math.PI * 1.25); c.stroke();
                        c.beginPath(); c.moveTo(14, 5); c.lineTo(14, 14); c.stroke();
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([root.home + "power-menu"]) }
            }
        }
    }
}
