import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Titus UpdateCenterWindow presentation: 480 px card below the bar, title row
// with Refresh/Close buttons and one filled provider card per package source.
// Counts are read-only; updates run interactively through updates.sh.
Item {
    id: root
    required property var panel
    required property string home
    required property string background
    required property string foreground
    required property string surface
    required property string accent
    property string hover: "#4C566A"
    property string strong: "#ECEFF4"
    property string controlBorder: "#3B4252"
    property string success: "#A3BE8C"
    property string warning: "#EBCB8B"
    width: 58; height: 28
    property bool opened: false
    property int xbpsCount: -1
    property int flatpakCount: -1
    property bool checked: false
    readonly property bool checking: status.running
    readonly property bool updating: action.running
    property string message: ""
    function refresh() { if (!status.running) status.running = true; }
    function update(kind) { if (action.running) return; message = ""; action.command = ["sh", home + "updates.sh", kind]; action.running = true; }
    function statusLabel(count) {
        if (root.checking && !root.checked) return "Wird geprüft";
        if (count < 0) return "Nicht verfügbar";
        return count > 0 ? "Verfügbar" : "Aktuell";
    }
    function statusColor(count) {
        if (root.checking && !root.checked) return root.foreground;
        if (count < 0) return root.foreground;
        return count > 0 ? root.warning : root.success;
    }
    function summary(count) { const n = Math.max(0, count); return n + (n === 1 ? " Paket" : " Pakete"); }
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

    // Titus ShellButton: filled control, lighter on hover.
    component ShellButton: Rectangle {
        id: button
        required property string label
        signal activated()
        implicitWidth: buttonText.implicitWidth + 18
        implicitHeight: 30
        radius: 6
        color: !enabled ? root.surface : buttonMouse.containsMouse ? root.hover : root.surface
        border.width: 1
        border.color: enabled && buttonMouse.containsMouse ? root.accent : root.controlBorder
        Text {
            id: buttonText
            anchors.centerIn: parent
            text: button.label
            color: root.foreground
            opacity: button.enabled ? 1 : 0.45
            font.family: Typography.family; font.pixelSize: 13
        }
        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }

    // Bar pill: transparent at rest, Titus hover/selected fill.
    Rectangle {
        anchors.centerIn: parent; width: parent.width; height: 26; radius: 6
        color: root.opened ? root.surface : mouse.containsMouse ? root.hover : "transparent"
        border.width: 1; border.color: root.opened || mouse.containsMouse ? root.accent : "transparent"
        Row {
            anchors.centerIn: parent; spacing: 4
            Image { source: "update-symbol.svg"; width: 13; height: 13; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: !root.checked ? "…" : root.xbpsCount < 0 && root.flatpakCount < 0 ? "—" : (root.xbpsCount < 0 || root.flatpakCount < 0 ? "~" : "") + (Math.max(0,root.xbpsCount)+Math.max(0,root.flatpakCount))
                color: root.foreground; font.family: Typography.family; font.pixelSize: 14
            }
        }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.opened = !root.opened; if (root.opened) root.refresh(); } }
    }
    PopupWindow {
        objectName: "voidUpdateCenter"
        anchor.window: root.panel
        anchor.rect.x: Math.max(0, Math.round((root.panel.width - implicitWidth) / 2))
        anchor.rect.y: root.panel.height
        implicitWidth: Math.min(480, root.panel.width)
        implicitHeight: content.implicitHeight + 20
        visible: root.opened; grabFocus: true; color: root.background
        onVisibleChanged: { if (visible) card.forceActiveFocus(); else root.opened = false; }
        Rectangle {
            id: card
            anchors.fill: parent
            color: root.background; border.width: 1; border.color: root.accent; radius: 0
            focus: true
            Keys.onEscapePressed: root.opened = false
            Keys.onPressed: event => { if (event.key === Qt.Key_R) { root.refresh(); event.accepted = true; } }
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: "Update-Center"
                        color: root.foreground; font.family: Typography.family; font.pixelSize: 18; font.bold: true
                    }
                    ShellButton { label: root.checking ? "Prüfe …" : "Aktualisieren"; enabled: !root.checking; onActivated: root.refresh() }
                    ShellButton { label: "Schließen"; onActivated: root.opened = false }
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.message !== ""
                    text: root.message
                    color: root.warning; font.family: Typography.family; font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
                Repeater {
                    model: [
                        { kind: "xbps", label: "Void (XBPS)", icon: "xbps.svg", count: root.xbpsCount },
                        { kind: "flatpak", label: "Flatpak", icon: "flatpak.svg", count: root.flatpakCount }
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: providerRow.implicitHeight + 20
                        color: root.surface
                        border.width: 1; border.color: root.controlBorder
                        radius: 6
                        RowLayout {
                            id: providerRow
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                            spacing: 10
                            Item {
                                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                Image { anchors.fill: parent; anchors.margins: 4; source: modelData.icon; fillMode: Image.PreserveAspectFit; smooth: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { text: modelData.label; color: root.foreground; font.family: Typography.family; font.pixelSize: 13; font.bold: true }
                                RowLayout {
                                    spacing: 0
                                    Text { text: root.statusLabel(modelData.count); color: root.statusColor(modelData.count); font.family: Typography.family; font.pixelSize: 12 }
                                    Text { visible: modelData.count >= 0; text: "  |  " + root.summary(modelData.count); color: root.foreground; font.family: Typography.family; font.pixelSize: 12 }
                                }
                            }
                            ShellButton {
                                label: root.updating ? "Läuft …" : "Update"
                                enabled: modelData.count > 0 && !root.updating
                                onActivated: root.update(modelData.kind)
                            }
                        }
                    }
                }
            }
        }
    }
}
