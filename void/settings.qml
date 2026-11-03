import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Fullscreen Settings after Titus: section list on the left, Displays pane on the right.
ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME") + "/.local/share/dwm-void/"
    readonly property var sections: [
        { id: "displays", label: "Displays", description: "Resolution, refresh rate, and layouts" },
        { id: "input", label: "Input", description: "Keyboard, pointer, and touchpad" },
        { id: "network", label: "Network", description: "Connections and VPN providers" },
        { id: "bluetooth", label: "Bluetooth", description: "Adapters and devices" },
        { id: "audio", label: "Audio", description: "Outputs, inputs, and streams" },
        { id: "power", label: "Power", description: "DPMS, locking, and session policy" },
        { id: "defaults", label: "Defaults", description: "Applications and autostart" },
        { id: "appearance", label: "Appearance", description: "Themes and accessibility" },
        { id: "system", label: "System", description: "Desktop updates, Quickshell, health and administration" }
    ]
    property string section: "displays"
    property var outputs: []
    property var baseline: []
    property bool loading: false
    property bool preview: false
    property int countdown: 0
    property string message: ""

    // Automatic layouts after Titus: one saved layout for "undocked" (one screen) and one for "docked" (several screens).
    property var profiles: ({})
    property var draft: null
    readonly property string dockState: outputs.filter(o => o.connected !== false).length > 1 ? "docked" : "undocked"
    function dockLabel(state) { return state === "docked" ? "Docked - external monitors" : "Undocked - built-in only"; }
    function profileSaved(state) { return !!profiles[state] && JSON.stringify(profiles[state]) === JSON.stringify(specs(baseline)); }
    function createDraft() { draft = clone(outputs); message = "Entwurf aus aktueller Anordnung erstellt."; }
    function saveDraft(state) {
        if (!draft) return;
        const next = clone(profiles); next[state] = specs(draft); profiles = next;
        profileFile.setText(JSON.stringify(profiles, null, 1));
        if (state === dockState) runAction(["save"].concat(specs(draft)));
        message = "Gespeichert als " + (state === "docked" ? "docked" : "undocked") + ".";
        draft = null;
    }
    function removeProfile(state) { const next = clone(profiles); delete next[state]; profiles = next; profileFile.setText(JSON.stringify(profiles, null, 1)); }
    FileView {
        id: profileFile
        path: root.home + "config/display-profiles.json"
        onLoaded: { try { root.profiles = JSON.parse(text()) || {}; } catch (e) { root.profiles = {}; } }
        onLoadFailed: root.profiles = {}
    }
    function clone(list) { return JSON.parse(JSON.stringify(list)); }
    function specs(list) {
        return list.map(o => o.enabled
            ? [o.name, "on", o.primary ? 1 : 0, o.mode, o.rate, o.rotation, o.x, o.y].join(":")
            : o.name + ":off");
    }
    function size(o) {
        const p = o.mode.split("x").map(Number);
        return (o.rotation === "left" || o.rotation === "right") ? [p[1], p[0]] : p;
    }
    function resolutions(o) { return [...new Set(o.modes.map(m => m.split("@")[0]))]; }
    function rates(o) { return o.modes.filter(m => m.split("@")[0] === o.mode).map(m => m.split("@")[1]); }
    function normalize(list) {
        const on = list.filter(o => o.enabled);
        if (!on.length) return;
        const mx = Math.min(...on.map(o => o.x)), my = Math.min(...on.map(o => o.y));
        for (const o of on) { o.x -= mx; o.y -= my; }
    }
    function update(index, key, value) {
        const list = clone(outputs);
        const o = list[index];
        if (key === "primary") for (const other of list) other.primary = false;
        o[key] = value;
        if (key === "mode") { const r = rates(o); if (r.indexOf(o.rate) < 0) o.rate = r[0]; }
        normalize(list);
        outputs = list; message = "";
    }
    function cycleRotation(index) {
        const order = ["normal", "left", "inverted", "right"];
        update(index, "rotation", order[(order.indexOf(outputs[index].rotation) + 1) % 4]);
    }
    function place(index, direction) {
        const list = clone(outputs);
        const o = list[index];
        const ref = list.find((r, i) => i !== index && r.enabled);
        if (!ref) return;
        const a = size(o), b = size(ref);
        if (direction === "left") { o.x = ref.x - a[0]; o.y = ref.y; }
        else if (direction === "right") { o.x = ref.x + b[0]; o.y = ref.y; }
        else if (direction === "above") { o.x = ref.x; o.y = ref.y - a[1]; }
        else { o.x = ref.x; o.y = ref.y + b[1]; }
        normalize(list);
        outputs = list; message = "";
    }
    function placement(index) {
        const o = outputs[index], ref = outputs.find((r, i) => i !== index && r.enabled);
        if (!o || !ref || !o.enabled) return "";
        const a = size(o), b = size(ref);
        if (o.x + a[0] <= ref.x) return "left";
        if (o.x >= ref.x + b[0]) return "right";
        if (o.y + a[1] <= ref.y) return "above";
        if (o.y >= ref.y + b[1]) return "below";
        return "";
    }
    function changed() { return JSON.stringify(specs(outputs)) !== JSON.stringify(specs(baseline)); }
    function refresh() { if (!reader.running) { loading = true; reader.running = true; } }
    function runAction(args) { if (!action.running) { action.command = ["sh", home + "display-settings.sh"].concat(args); action.running = true; } }
    function applyChanges() { pendingPreview = true; runAction(["apply"].concat(specs(outputs))); }
    function keep() { preview = false; revertTimer.stop(); baseline = clone(outputs); message = "Änderungen behalten."; }
    function revert() { preview = false; revertTimer.stop(); outputs = clone(baseline); pendingRefresh = true; runAction(["apply"].concat(specs(baseline))); }
    property bool pendingPreview: false
    property bool pendingRefresh: false

    Process {
        id: reader
        command: ["sh", root.home + "display-settings.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.trim().split("\n")) {
                    const f = line.split("\t");
                    if (f.length < 9) continue;
                    list.push({ name: f[0], enabled: f[1] === "1", primary: f[2] === "1", x: Number(f[3]), y: Number(f[4]),
                        mode: f[5] || (f[8].split(",")[0] || "@").split("@")[0], rate: f[6] || (f[8].split(",")[0] || "@").split("@")[1],
                        rotation: f[7], modes: f[8] ? f[8].split(",") : [] });
                }
                root.outputs = list; root.baseline = root.clone(list);
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.message = text.trim() }
        onExited: root.loading = false
    }
    Process {
        id: action
        stdout: StdioCollector { onStreamFinished: if (text.trim()) root.message = text.trim() }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.message = text.trim() }
        onExited: (code, status) => {
            if (code !== 0) { if (!root.message) root.message = "Aktion fehlgeschlagen."; root.pendingPreview = false; }
            else if (root.pendingPreview) { root.preview = true; root.countdown = 15; revertTimer.start(); }
            root.pendingPreview = false;
            if (root.pendingRefresh) { root.pendingRefresh = false; root.refresh(); }
        }
    }
    Timer { id: revertTimer; interval: 1000; repeat: true; onTriggered: { root.countdown -= 1; if (root.countdown <= 0) root.revert(); } }

    component Button2: Rectangle {
        id: b
        property string label: ""
        property bool active: false
        property bool danger: false
        signal activated()
        implicitWidth: Math.max(76, t.implicitWidth + 22); implicitHeight: 30; radius: 6
        opacity: enabled ? 1 : 0.45
        color: active ? CenterTheme.surface : m.containsMouse ? CenterTheme.hover : CenterTheme.surface
        border.width: 1
        border.color: danger ? "#BF616A" : active || m.containsMouse ? CenterTheme.border : CenterTheme.mutedBorder
        Text { id: t; anchors.centerIn: parent; text: b.label; color: b.active ? CenterTheme.border : CenterTheme.strong; font.family: Typography.family; font.pixelSize: 12; font.bold: true }
        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; enabled: b.enabled; cursorShape: Qt.PointingHandCursor; onClicked: b.activated() }
    }

    FloatingWindow {
        id: window
        title: "Void Settings"
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
            RowLayout {
                anchors.fill: parent; anchors.margins: 1; spacing: 0
                // Section list
                Rectangle {
                    Layout.preferredWidth: 260; Layout.fillHeight: true; color: CenterTheme.background
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 16; spacing: 4
                        Text { text: "Settings"; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 18; font.bold: true; Layout.bottomMargin: 10 }
                        Repeater {
                            model: root.sections
                            Rectangle {
                                id: entry
                                required property var modelData
                                readonly property bool active: root.section === modelData.id
                                Layout.fillWidth: true; implicitHeight: 48; radius: 6
                                color: active ? CenterTheme.surface : em.containsMouse ? CenterTheme.hover : "transparent"
                                border.width: active ? 1 : 0; border.color: CenterTheme.border
                                Column {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 8 }
                                    Text { text: entry.modelData.label; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 13; font.bold: true }
                                    Text { width: parent.width; text: entry.modelData.description; elide: Text.ElideRight; color: CenterTheme.foreground; opacity: 0.75; font.family: Typography.family; font.pixelSize: 11 }
                                }
                                MouseArea { id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.section = entry.modelData.id }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
                Rectangle { Layout.fillHeight: true; width: 1; color: CenterTheme.mutedBorder }
                // Pane
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 24; spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Column {
                            Layout.fillWidth: true
                            Text { text: root.sections.find(s => s.id === root.section).label; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 18; font.bold: true }
                            Text { text: root.sections.find(s => s.id === root.section).description; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 12 }
                        }
                        Text { text: root.loading ? "Loading" : action.running ? "Working" : "Ready"; color: root.loading || action.running ? CenterTheme.warning : CenterTheme.success; font.family: Typography.family; font.pixelSize: 12; font.bold: true; Layout.rightMargin: 6 }
                        Button2 { label: "Refresh"; enabled: !root.loading && !root.preview; onActivated: root.refresh() }
                        Button2 { label: "Close"; onActivated: Qt.quit() }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: CenterTheme.border; opacity: 0.55 }
                    Text {
                        visible: root.section !== "displays"
                        text: "Noch nicht eingerichtet"; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 13
                    }
                    // Displays
                    RowLayout {
                        visible: root.section === "displays"; Layout.fillWidth: true; spacing: 8
                        Button2 { label: "Apply changes"; active: root.changed(); enabled: root.changed() && !root.preview && !action.running; onActivated: root.applyChanges() }
                        Item { Layout.fillWidth: true }
                        Button2 { label: "Use at next login"; enabled: !root.preview && !action.running && root.outputs.length > 0; onActivated: root.runAction(["save"].concat(root.specs(root.baseline))) }
                    }
                    Rectangle {
                        visible: root.section === "displays" && root.preview
                        Layout.fillWidth: true; implicitHeight: 48; radius: 6; color: CenterTheme.surface; border.width: 1; border.color: CenterTheme.warning
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 9; spacing: 8
                            Text { Layout.fillWidth: true; text: "Keep this layout? Reverting in " + root.countdown + "s"; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 13 }
                            Button2 { label: "Keep changes"; onActivated: root.keep() }
                            Button2 { label: "Revert"; danger: true; onActivated: root.revert() }
                        }
                    }
                    Text { visible: root.message !== ""; text: root.message; color: CenterTheme.warning; font.family: Typography.family; font.pixelSize: 12 }
                    ScrollView {
                        visible: root.section === "displays"
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        ColumnLayout {
                            width: window.width - 260 - 50; spacing: 10
                            Rectangle {
                                Layout.fillWidth: true; implicitHeight: auto.implicitHeight + 24
                                radius: 6; color: CenterTheme.surface; border.width: 1; border.color: CenterTheme.mutedBorder
                                ColumnLayout {
                                    id: auto
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                    spacing: 8
                                    Text { text: "Automatic layouts - login and dock connection"; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 13; font.bold: true }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Text { Layout.fillWidth: true; text: root.dockLabel(root.dockState); color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 12 }
                                        Text { text: root.profileSaved(root.dockState) ? "Saved" : "Not saved"; color: root.profileSaved(root.dockState) ? CenterTheme.success : CenterTheme.warning; font.family: Typography.family; font.pixelSize: 12; font.bold: true }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 6
                                        Button2 { label: "Create draft"; active: root.draft !== null; enabled: root.outputs.length > 0 && !root.preview; onActivated: root.createDraft() }
                                        Button2 { label: "Save draft as undocked"; enabled: root.draft !== null; onActivated: root.saveDraft("undocked") }
                                        Button2 { label: "Save draft as docked"; enabled: root.draft !== null; onActivated: root.saveDraft("docked") }
                                    }
                                    Text { text: "Saved monitors"; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 12; font.bold: true; Layout.topMargin: 4 }
                                    Text { visible: Object.keys(root.profiles).length === 0; text: "No saved layouts yet."; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 11 }
                                    Repeater {
                                        model: ["undocked", "docked"].filter(k => !!root.profiles[k])
                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true; spacing: 8
                                            Text { text: modelData === root.dockState ? "●" : "○"; color: CenterTheme.border; font.family: Typography.family; font.pixelSize: 12 }
                                            Text { Layout.preferredWidth: 190; elide: Text.ElideRight; text: root.dockLabel(modelData); color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 11 }
                                            // Small drawing of the saved layout, like Titus.
                                            Item {
                                                id: mini
                                                readonly property var boxes: root.profiles[parent.modelData].filter(x => !x.endsWith(":off")).map(x => { const p = x.split(":"); const m = p[3].split("x").map(Number); const turn = p[5] === "left" || p[5] === "right"; return { name: p[0], primary: p[2] === "1", w: turn ? m[1] : m[0], h: turn ? m[0] : m[1], x: Number(p[6]), y: Number(p[7]) }; })
                                                readonly property real tw: Math.max(1, ...boxes.map(b => b.x + b.w))
                                                readonly property real th: Math.max(1, ...boxes.map(b => b.y + b.h))
                                                readonly property real sc: Math.min(160 / tw, 44 / th)
                                                Layout.fillWidth: true; Layout.preferredHeight: 48
                                                Repeater {
                                                    model: mini.boxes
                                                    Rectangle {
                                                        required property var modelData
                                                        x: modelData.x * mini.sc + 1; y: modelData.y * mini.sc + 2
                                                        width: modelData.w * mini.sc - 2; height: modelData.h * mini.sc - 2
                                                        radius: 3; color: CenterTheme.hover
                                                        border.width: modelData.primary ? 1 : 0; border.color: CenterTheme.border
                                                        Text { anchors.centerIn: parent; width: parent.width - 4; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: parent.modelData.name; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 9 }
                                                    }
                                                }
                                            }
                                            Button2 { label: "Remove"; danger: true; onActivated: root.removeProfile(modelData) }
                                        }
                                    }
                                }
                            }
                            // Monitor drawing after Titus: every enabled output as a scaled screen with its label.
                            Rectangle {
                                id: arrangement
                                readonly property var shown: root.outputs.filter(o => o.enabled)
                                readonly property real totalW: Math.max(1, ...shown.map(o => o.x + root.size(o)[0]))
                                readonly property real totalH: Math.max(1, ...shown.map(o => o.y + root.size(o)[1]))
                                readonly property real scale: Math.min((width - 48) / totalW, (height - 40) / totalH)
                                Layout.fillWidth: true; implicitHeight: 240; radius: 6
                                color: CenterTheme.surface; border.width: 1; border.color: CenterTheme.mutedBorder
                                visible: shown.length > 0
                                Item {
                                    width: arrangement.totalW * arrangement.scale; height: arrangement.totalH * arrangement.scale
                                    anchors.centerIn: parent
                                    Repeater {
                                        model: root.outputs
                                        Rectangle {
                                            id: screenBox
                                            required property var modelData
                                            required property int index
                                            visible: modelData.enabled
                                            x: modelData.x * arrangement.scale + 3; y: modelData.y * arrangement.scale + 3
                                            width: root.size(modelData)[0] * arrangement.scale - 6; height: root.size(modelData)[1] * arrangement.scale - 6
                                            radius: 6; color: CenterTheme.hover
                                            border.width: modelData.primary ? 2 : 0
                                            border.color: CenterTheme.border
                                            Column {
                                                anchors.centerIn: parent; spacing: 2
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: String(screenBox.index + 1); color: CenterTheme.border; font.family: Typography.family; font.pixelSize: 26; font.bold: true }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: screenBox.modelData.name; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 13; font.bold: true }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: screenBox.modelData.mode + " @ " + screenBox.modelData.rate + " Hz"; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 11 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; visible: screenBox.modelData.primary; text: "Primary"; color: CenterTheme.border; font.family: Typography.family; font.pixelSize: 10 }
                                            }
                                        }
                                    }
                                }
                            }
                            Repeater {
                                model: root.outputs
                                Rectangle {
                                    id: card
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true; implicitHeight: body.implicitHeight + 24
                                    radius: 6; color: CenterTheme.surface; border.width: 1; border.color: CenterTheme.mutedBorder
                                    ColumnLayout {
                                        id: body
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                        spacing: 8
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 6
                                            Text { Layout.fillWidth: true; text: "Monitor " + (card.index + 1) + " - " + card.modelData.name; color: CenterTheme.strong; font.family: Typography.family; font.pixelSize: 13; font.bold: true }
                                            Text { text: card.modelData.enabled ? card.modelData.mode + " @ " + card.modelData.rate + " Hz, " + card.modelData.x + "," + card.modelData.y : "Off"; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 11 }
                                            Button2 { label: card.modelData.enabled ? "Enabled" : "Disabled"; active: card.modelData.enabled; onActivated: root.update(card.index, "enabled", !card.modelData.enabled) }
                                            Button2 { label: card.modelData.primary ? "Primary" : "Make primary"; active: card.modelData.primary; enabled: card.modelData.enabled; onActivated: root.update(card.index, "primary", true) }
                                        }
                                        Text { text: "Resolution"; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 12 }
                                        Flow {
                                            Layout.fillWidth: true; spacing: 6
                                            Repeater {
                                                model: root.resolutions(card.modelData)
                                                Button2 { required property var modelData; label: modelData; active: card.modelData.mode === modelData; enabled: card.modelData.enabled; onActivated: root.update(card.index, "mode", modelData) }
                                            }
                                        }
                                        Text { text: "Refresh rate"; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 12 }
                                        Flow {
                                            Layout.fillWidth: true; spacing: 6
                                            Repeater {
                                                model: root.rates(card.modelData)
                                                Button2 { required property var modelData; label: modelData + " Hz"; active: card.modelData.rate === modelData; enabled: card.modelData.enabled; onActivated: root.update(card.index, "rate", modelData) }
                                            }
                                        }
                                        Flow {
                                            Layout.fillWidth: true; spacing: 6
                                            Button2 { label: "Rotation: " + card.modelData.rotation; enabled: card.modelData.enabled; onActivated: root.cycleRotation(card.index) }
                                            Repeater {
                                                model: [{ d: "left", label: "Left of" }, { d: "right", label: "Right of" }, { d: "above", label: "Above" }, { d: "below", label: "Below" }]
                                                Button2 {
                                                    required property var modelData
                                                    visible: root.outputs.filter((o, i) => i !== card.index && o.enabled).length > 0
                                                    label: modelData.label + " " + (root.outputs.find((o, i) => i !== card.index && o.enabled) || { name: "" }).name
                                                    enabled: card.modelData.enabled
                                                    active: root.placement(card.index) === modelData.d
                                                    onActivated: root.place(card.index, modelData.d)
                                                }
                                            }
                                        }
                                        Text {
                                            visible: root.outputs.filter((o, i) => i !== card.index && o.enabled).length === 0 && root.outputs.length > 1
                                            text: "Enable another monitor to arrange it beside this one."; color: CenterTheme.foreground; font.family: Typography.family; font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item { visible: root.section !== "displays"; Layout.fillHeight: true }
                }
            }
        }
    }
}
