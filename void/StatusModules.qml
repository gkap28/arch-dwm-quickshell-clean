import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Row {
    id: root
    required property var panel
    required property string home
    required property string background
    required property string foreground
    required property string surface
    required property string accent
    spacing: 4
    height: 28
    property int volume: -1
    property bool muted: false
    property string network: "offline"
    property string opened: ""
    function action(name, value) {
        const args = ["sh", home + "modules.sh", name];
        if (value !== undefined) args.push(value.toString());
        Quickshell.execDetached(args);
        refresh.restart();
    }
    Timer { id: refresh; interval: 250; onTriggered: { if (!state.running) state.running = true; } }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: { if (!state.running) state.running = true; } }
    Process {
        id: state
        command: ["sh", root.home + "modules.sh", "status"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("\t");
                if (parts.length !== 3) return;
                root.volume = Number(parts[0]); root.muted = parts[1] === "1"; root.network = parts[2];
            }
        }
    }
    Repeater {
        model: ["network", "audio"]
        Rectangle {
            id: pill
            required property string modelData
            readonly property bool audio: modelData === "audio"
            width: audio ? 80 : 66
            height: 26
            y: 1; radius: 6
            color: mouse.containsMouse || root.opened === modelData ? root.surface : root.background
            border.width: 1; border.color: root.opened === modelData ? root.accent : root.surface
            Canvas {
                id: symbol
                anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20
                property string stateKey: root.network + root.muted + root.volume
                onStateKeyChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"); c.reset(); c.strokeStyle = root.foreground; c.fillStyle = root.foreground; c.lineWidth = 1.6; c.lineCap = "round";
                    if (pill.audio) {
                        c.beginPath(); c.moveTo(3,8); c.lineTo(7,8); c.lineTo(11,4); c.lineTo(11,16); c.lineTo(7,12); c.lineTo(3,12); c.closePath(); c.stroke();
                        if (root.muted || root.volume < 0) { c.beginPath(); c.moveTo(14,7); c.lineTo(18,13); c.moveTo(18,7); c.lineTo(14,13); c.stroke(); }
                        else { c.beginPath(); c.arc(11,10,6,-0.8,0.8); c.stroke(); }
                    } else if (root.network === "wifi") {
                        for (let r of [4,8,12]) { c.beginPath(); c.arc(10,17,r,-2.35,-0.79); c.stroke(); }
                        c.beginPath(); c.arc(10,17,1,0,Math.PI*2); c.fill();
                    } else {
                        c.strokeRect(2,3,16,11); c.beginPath(); c.moveTo(10,14); c.lineTo(10,18); c.moveTo(6,18); c.lineTo(14,18); c.stroke();
                        if (root.network === "offline") { c.beginPath(); c.moveTo(5,6); c.lineTo(15,11); c.moveTo(15,6); c.lineTo(5,11); c.stroke(); }
                    }
                }
            }
            Text {
                anchors.left: symbol.right; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                text: pill.audio ? (root.volume < 0 ? "—" : root.volume + "%") : "NET"
                color: root.foreground; font.family: "monospace"; font.pixelSize: 14
            }
            MouseArea {
                id: mouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.opened = root.opened === pill.modelData ? "" : pill.modelData
                onWheel: wheel => { if (pill.audio) { root.action(wheel.angleDelta.y > 0 ? "up" : "down"); wheel.accepted = true; } }
            }
            ToolTip.visible: mouse.containsMouse && root.opened === ""
            ToolTip.delay: 700
            ToolTip.text: audio ? (root.volume < 0 ? "Ton nicht verfügbar" : root.muted ? "Stumm" : "Lautstärke") : root.network === "wifi" ? "WLAN verbunden" : root.network === "ethernet" ? "Kabel verbunden" : "Nicht verbunden"
        }
    }
    PopupWindow {
        id: popup
        anchor.window: root.panel
        anchor.rect.x: Math.max(0, root.panel.width - 310)
        anchor.rect.y: 30
        implicitWidth: 280
        implicitHeight: root.opened === "audio" ? 184 : 144
        visible: root.opened !== ""
        color: root.background
        Rectangle {
            anchors.fill: parent; border.width: 1; border.color: root.accent; color: root.background
            Column {
                anchors.fill: parent; anchors.margins: 14; spacing: 12
                Text { text: root.opened === "audio" ? "Lautstärke" : "Netzwerk"; color: root.accent; font.family: "monospace"; font.pixelSize: 16; font.bold: true }
                Text {
                    text: root.opened === "audio" ? (root.volume < 0 ? "Ton nicht verfügbar" : root.muted ? "Stumm · " + root.volume + "%" : root.volume + "%") : root.network === "wifi" ? "WLAN verbunden" : root.network === "ethernet" ? "Kabel verbunden" : "Nicht verbunden"
                    color: root.foreground; font.family: "monospace"; font.pixelSize: 14
                }
                Slider {
                    visible: root.opened === "audio"; enabled: root.volume >= 0
                    width: parent.width; height: 24; from: 0; to: 100; stepSize: 1
                    value: Math.min(100, Math.max(0, root.volume))
                    onMoved: root.action("volume", Math.round(value))
                    background: Rectangle { x: 0; y: 10; width: parent.width; height: 4; radius: 2; color: root.surface; Rectangle { width: parent.width * parent.parent.visualPosition; height: 4; radius: 2; color: root.accent } }
                    handle: Rectangle { x: parent.visualPosition * (parent.width - width); y: 4; width: 16; height: 16; radius: 8; color: root.accent }
                }
                Row {
                    spacing: 8
                    Repeater {
                        model: root.opened === "audio" ? ["mute", "settings", "close"] : ["settings", "close"]
                        Rectangle {
                            required property string modelData
                            width: modelData === "settings" ? 112 : 58; height: 30; radius: 6
                            color: button.containsMouse ? root.surface : root.background
                            border.width: 1; border.color: root.surface
                            Text { anchors.centerIn: parent; text: parent.modelData === "mute" ? (root.muted ? "Ton" : "Stumm") : parent.modelData === "settings" ? "Einstellungen" : "×"; color: root.foreground; font.family: "monospace"; font.pixelSize: 12 }
                            MouseArea {
                                id: button
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData === "mute") root.action("mute");
                                    else { if (modelData === "settings") root.action(root.opened === "audio" ? "audio-settings" : "network-settings"); root.opened = ""; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
