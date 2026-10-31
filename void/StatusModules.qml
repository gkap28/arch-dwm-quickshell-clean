import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
    property var outputs: []
    property var activeConnections: []
    property var wifiNetworks: []
    property var savedProfiles: []
    property string defaultOutput: ""
    property string micState: "Nicht verfügbar"
    property string mediaPlayer: ""
    property string mediaText: "Keine Wiedergabe"
    property bool nmAvailable: false
    property bool busy: false
    property string message: ""
    property var selectedWifi: null
    function splitEscaped(text) {
        const parts = []; let part = ""; let escaped = false;
        for (const c of text) {
            if (escaped) { part += c; escaped = false; }
            else if (c === "\\") escaped = true;
            else if (c === ":") { parts.push(part); part = ""; }
            else part += c;
        }
        parts.push(part); return parts;
    }
    function detailsAction(name, args, password) {
        if (busy) return;
        busy = true; message = "";
        operation.command = ["sh", home + "module-details.sh", name].concat(args || []);
        operation.pendingPassword = password === undefined ? "" : password;
        operation.running = true;
    }
    function loadDetails() { if (!details.running) details.running = true; }
    onOpenedChanged: { selectedWifi = null; message = ""; if (opened !== "") loadDetails(); }
    Process {
        id: operation
        property string pendingPassword: ""
        stdinEnabled: true
        onStarted: { if (pendingPassword !== "") { write(pendingPassword + "\n"); pendingPassword = ""; } closeWriteChannel(); }
        onExited: (code, status) => { root.busy = false; if (code !== 0) root.message = "Aktion fehlgeschlagen — bitte Verbindung oder Dienst prüfen."; root.loadDetails(); refresh.restart(); }
    }
    Process {
        id: details
        command: ["sh", root.home + "module-details.sh", "read"]
        stdout: StdioCollector {
            onStreamFinished: {
                const outputs = [], active = [], wifi = [], saved = [];
                root.defaultOutput = ""; root.micState = "Nicht verfügbar"; root.mediaPlayer = ""; root.mediaText = "Keine Wiedergabe"; root.nmAvailable = false;
                for (const line of text.trim().split("\n")) {
                    const p = line.split("\t");
                    if (p[0] === "default") root.defaultOutput = p[1] || "";
                    else if (p[0] === "output") outputs.push({name:p[1], description:p.slice(2).join(" ")});
                    else if (p[0] === "mic") root.micState = p[1].indexOf("yes") >= 0 ? "Stumm" : p[1].indexOf("no") >= 0 ? "Aktiv" : "Nicht verfügbar";
                    else if (p[0] === "media") { root.mediaPlayer = p[1]; root.mediaText = p[2]; }
                    else if (p[0] === "nm") root.nmAvailable = p[1] === "available";
                    else {
                        const row = root.splitEscaped(p.slice(1).join("\t"));
                        if (p[0] === "active") active.push({name:row[0], uuid:row[1], type:row[2], device:row[3]});
                        else if (p[0] === "wifi" && row[1]) wifi.push({active:row[0] === "*", ssid:row[1], signal:row[2], security:row[3], bssid:row[4]});
                        else if (p[0] === "saved") saved.push({name:row[0], uuid:row[1], type:row[2]});
                    }
                }
                root.outputs = outputs; root.activeConnections = active; root.wifiNetworks = wifi; root.savedProfiles = saved;
            }
        }
    }
    Timer { interval: 3000; running: root.opened !== ""; repeat: true; onTriggered: root.loadDetails() }
    component Label: Text { color: root.foreground; font.family: "monospace"; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
    component Section: Label { color: root.accent; font.pixelSize: 13; font.bold: true; Layout.topMargin: 8 }
    component ActionButton: Button {
        id: control
        font.family: "monospace"; font.pixelSize: 12
        implicitHeight: 34; implicitWidth: Math.max(64, contentItem.implicitWidth + 20)
        enabled: !root.busy
        contentItem: Text { text: control.text; color: root.foreground; font: control.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; opacity: control.enabled ? 1 : 0.45 }
        background: Rectangle { radius: 6; color: control.hovered ? root.surface : root.background; border.width: 1; border.color: control.activeFocus ? root.accent : root.surface }
    }
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
        anchor.rect.x: 0
        anchor.rect.y: root.panel.height
        implicitWidth: root.panel.width
        implicitHeight: root.panel.screen ? Math.max(0, root.panel.screen.height - root.panel.height) : 700
        visible: root.opened !== ""
        grabFocus: true
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: root.opened = "" }
        Flickable {
            id: viewport
            readonly property int cardWidth: root.opened === "audio" ? 360 : 620
            readonly property int cardHeight: root.opened === "audio" ? Math.max(560, audioContent.implicitHeight + 32) : 680
            x: Math.max(0, parent.width - width - 8)
            width: Math.min(cardWidth, parent.width)
            height: Math.min(cardHeight, parent.height)
            contentWidth: cardWidth; contentHeight: cardHeight; clip: true
            boundsBehavior: Flickable.StopAtBounds
            Rectangle {
                width: viewport.cardWidth; height: viewport.cardHeight
                color: root.background; border.width: 1; border.color: root.accent; radius: 8
                focus: true
                Keys.onEscapePressed: { if (root.selectedWifi) root.selectedWifi = null; else root.opened = ""; }
                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    id: audioContent
                    visible: root.opened === "audio"
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "Audio"; font.pixelSize: 22; font.bold: true }
                            Label { text: root.volume < 0 ? "Ton nicht verfügbar (pactl)" : root.muted ? "Stumm" : root.volume + "%" }
                        }
                        ActionButton { text: "Aktualisieren"; onClicked: {root.loadDetails(); refresh.restart();} }
                    }
                    Label { visible: root.message !== ""; text: root.message; wrapMode: Text.Wrap }
                    Rectangle { Layout.fillWidth: true; height: 1; color: root.surface }
                    Section { text: "Lautstärke" }
                    RowLayout {
                        Layout.fillWidth: true
                        Slider {
                            id: volumeSlider
                            Layout.fillWidth: true; Layout.preferredHeight: 46
                            enabled: root.volume >= 0 && !root.busy
                            from: 0; to: 100; stepSize: 1; value: Math.min(100, Math.max(0, root.volume))
                            onPressedChanged: if (!pressed) root.action("volume", Math.round(value))
                            background: Rectangle { x: volumeSlider.leftPadding; y: volumeSlider.height / 2 - 2; width: volumeSlider.availableWidth; height: 4; radius: 2; color: root.surface; Rectangle { width: parent.width * volumeSlider.visualPosition; height: 4; radius: 2; color: root.accent } }
                            handle: Rectangle { x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width); y: volumeSlider.height / 2 - 8; width: 16; height: 16; radius: 8; color: root.accent }
                        }
                        Label { Layout.fillWidth: false; Layout.preferredWidth: 42; text: Math.round(volumeSlider.value) + "%"; font.bold: true }
                        ActionButton { Layout.preferredWidth: 84; Layout.preferredHeight: 46; text: root.muted ? "Ton an" : "Stumm"; enabled: root.volume >= 0; onClicked: root.action("mute") }
                    }
                    Section { text: "Ausgabe" }
                    Label { visible: root.outputs.length === 0; text: "Keine Ausgabegeräte verfügbar" }
                    Repeater {
                        model: root.outputs
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 34; radius: 6
                            color: modelData.name === root.defaultOutput ? root.surface : root.background
                            border.width: 1; border.color: modelData.name === root.defaultOutput ? root.accent : root.surface
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Label { text: modelData.description; font.bold: modelData.name === root.defaultOutput }
                                Label { Layout.fillWidth: false; text: modelData.name === root.defaultOutput ? "Standard" : "Wählen"; color: root.accent; font.pixelSize: 12 }
                            }
                            MouseArea { anchors.fill: parent; enabled: !root.busy; cursorShape: Qt.PointingHandCursor; onClicked: root.detailsAction("output", [modelData.name]) }
                        }
                    }
                    RowLayout { Layout.fillWidth: true; Section { text: "Mikrofon" } Label { Layout.fillWidth: false; text: root.micState } ActionButton { text: root.micState === "Stumm" ? "Ton an" : "Stumm"; enabled: root.micState !== "Nicht verfügbar"; onClicked: root.detailsAction("mic-mute") } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: root.surface }
                    Section { text: "Medien" }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 54; radius: 6; color: root.surface
                        ColumnLayout { anchors.fill: parent; anchors.margins: 10; spacing: 2; Label { text: root.mediaText; font.bold: true } Label { text: root.mediaPlayer; font.pixelSize: 12 } }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton { Layout.fillWidth: true; text: "Zurück"; enabled: root.mediaPlayer !== ""; onClicked: root.detailsAction("previous") }
                        ActionButton { Layout.fillWidth: true; text: "Play/Pause"; enabled: root.mediaPlayer !== ""; onClicked: root.detailsAction("play-pause") }
                        ActionButton { Layout.fillWidth: true; text: "Weiter"; enabled: root.mediaPlayer !== ""; onClicked: root.detailsAction("next") }
                    }
                }
                ColumnLayout {
                    visible: root.opened === "network" && !root.selectedWifi
                    anchors.fill: parent; anchors.margins: 16; spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { Layout.fillWidth: true; Label { text: "Netzwerk"; font.pixelSize: 22; font.bold: true } Label { text: !root.nmAvailable ? "NetworkManager nicht verfügbar" : root.network === "wifi" ? "WLAN verbunden" : root.network === "ethernet" ? "Kabel verbunden" : "Nicht verbunden" } }
                        ActionButton { text: "Suchen"; enabled: root.nmAvailable && !root.busy; onClicked: root.detailsAction("scan") }
                    }
                    Label { visible: root.message !== ""; text: root.message; wrapMode: Text.Wrap }
                    Rectangle { Layout.fillWidth: true; height: 1; color: root.surface }
                    Section { text: "Aktiv" }
                    ListView {
                        Layout.fillWidth: true; Layout.preferredHeight: Math.min(150, Math.max(42, contentHeight)); clip: true; spacing: 4; model: root.activeConnections
                        delegate: RowLayout {
                            required property var modelData
                            width: ListView.view.width; height: 42
                            Label { text: modelData.name + " · " + modelData.device }
                            ActionButton { text: "Trennen"; onClicked: root.detailsAction("disconnect", [modelData.device]) }
                        }
                    }
                    Label { visible: root.activeConnections.length === 0; text: "Keine aktiven Verbindungen" }
                    Section { text: "WLAN" }
                    ListView {
                        Layout.fillWidth: true; Layout.preferredHeight: Math.min(220, Math.max(64, contentHeight)); clip: true; spacing: 4; model: root.wifiNetworks
                        delegate: RowLayout {
                            required property var modelData
                            width: ListView.view.width; height: 46
                            Label { text: modelData.ssid + " · " + modelData.signal + "% · " + modelData.security; font.bold: modelData.active }
                            ActionButton {
                                text: modelData.active ? "Verbunden" : "Verbinden"; enabled: !modelData.active && !root.busy
                                onClicked: { if (modelData.security && modelData.security !== "--") { root.selectedWifi = modelData; password.text = ""; password.forceActiveFocus(); } else root.detailsAction("wifi", [modelData.ssid, modelData.bssid]); }
                            }
                        }
                    }
                    Label { visible: root.wifiNetworks.length === 0; text: "Keine sichtbaren WLAN-Netze" }
                    Section { text: "Gespeichert" }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4; model: root.savedProfiles
                        delegate: RowLayout {
                            required property var modelData
                            width: ListView.view.width; height: 42
                            Label { text: modelData.name + " · " + modelData.type }
                            ActionButton { text: "Verbinden"; onClicked: root.detailsAction("connect-profile", [modelData.uuid]) }
                        }
                    }
                    Label { visible: root.savedProfiles.length === 0; text: "Keine gespeicherten Verbindungen" }
                    ActionButton { Layout.fillWidth: true; text: "Verbindungen bearbeiten"; onClicked: root.action("network-settings") }
                }
                ColumnLayout {
                    visible: root.selectedWifi !== null && root.opened === "network"
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    Label { text: root.selectedWifi ? root.selectedWifi.ssid : ""; font.pixelSize: 22; font.bold: true }
                    Label { text: "WLAN-Passwort" }
                    TextField { id: password; Layout.fillWidth: true; echoMode: TextInput.Password; color: root.foreground; background: Rectangle { color: root.surface; radius: 6; border.width: 1; border.color: root.accent } onAccepted: connectWifi.clicked() }
                    RowLayout {
                        ActionButton { text: "Abbrechen"; onClicked: { root.selectedWifi = null; password.text = ""; } }
                        ActionButton { id: connectWifi; text: "Verbinden"; enabled: !root.busy && password.text.length > 0; onClicked: { if (!root.selectedWifi) return; root.detailsAction("wifi", [root.selectedWifi.ssid, root.selectedWifi.bssid], password.text); password.text = ""; root.selectedWifi = null; } }
                    }
                }
            }
        }
    }
}
