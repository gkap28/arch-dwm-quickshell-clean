import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    // Self report for remote diagnosis; visible in quickshell.log.
    Component.onCompleted: console.log(
        "VOID-BAR Quickshell " + (Quickshell.version || "?") +
        " Bildschirme=" + Quickshell.screens.length + " " +
        Quickshell.screens.map(s => s.name + "@" + s.x + "," + s.y + " " + s.width + "x" + s.height).join(" | "))
    property var monitors: []
    property string status: ""
    readonly property string normal: "#2E3440"
    readonly property string active: "#434C5E"
    readonly property string foreground: "#D8DEE9"
    readonly property string accent: "#88C0D0"
    // Same default-scale workspace geometry and state roles as Titus WorkspaceButton.
    readonly property int workspaceSize: 22
    readonly property int workspaceRadius: 6
    readonly property int workspaceBorderWidth: 1
    readonly property string workspaceHover: "#4C566A"
    readonly property string workspaceBorder: "#81A1C1"
    readonly property string workspaceSelectedText: "#FFFFFF"
    readonly property string transparent: "#00000000"
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
                    Image { anchors.centerIn: parent; width: 13; height: 13; source: "logo.svg" }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([root.home + "power-menu", "--control"]) }
                }
                Item {
                    width: workspaceRow.width + 8
                    height: parent.height
                    Row {
                        id: workspaceRow
                        anchors.centerIn: parent
                        spacing: 1
                        Repeater {
                            model: 9
                            Rectangle {
                                id: workspaceButton
                                required property int index
                                readonly property bool selected: !!panel.monitor && panel.monitor.desktop === index
                                width: root.workspaceSize; height: root.workspaceSize
                                radius: root.workspaceRadius
                                color: selected ? root.active : workspaceMouse.containsMouse ? root.workspaceHover : root.transparent
                                border.color: selected || workspaceMouse.containsMouse ? root.workspaceBorder : root.transparent
                                border.width: selected || workspaceMouse.containsMouse ? root.workspaceBorderWidth : 0
                                Text {
                                    anchors.centerIn: parent
                                    text: workspaceButton.index + 1
                                    color: workspaceButton.selected ? root.workspaceSelectedText : root.foreground
                                    font.family: "monospace"; font.pixelSize: 14
                                    font.bold: workspaceButton.selected
                                }
                                MouseArea {
                                    id: workspaceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached([root.home + "bar-bridge", "view", workspaceButton.index.toString(), panel.screen.x.toString(), panel.screen.y.toString()])
                                }
                            }
                        }
                    }
                }
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.max(0, panel.width - 2 * Math.max(workspaces.width, rightModules.width) - 90))
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.status
                    color: root.foreground
                    font.family: "monospace"; font.pixelSize: 14
                }
                UpdateModule {
                    panel: panel; home: root.home
                    background: root.normal; foreground: root.foreground
                    surface: root.active; accent: root.workspaceBorder
                }
            }
            Row {
                id: rightModules
                anchors.right: parent.right
                height: 28
                spacing: 4
                StatusModules {
                    panel: panel; home: root.home
                    background: root.normal; foreground: root.foreground
                    surface: root.active; accent: root.workspaceBorder
                }
                PowerMenu {
                    panel: panel; home: root.home
                    background: root.normal; foreground: root.foreground
                    surface: root.active; accent: root.workspaceBorder
                }
            }
        }
    }
}