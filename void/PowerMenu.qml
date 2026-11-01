import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Power menu with the same five session actions as the Titus panel:
// reboot, logout, lock (no confirmation), suspend, shutdown.
// Actions run through the user-local power-action.sh helper only.
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
    width: 28
    height: 28
    // "" = closed, "menu" = action list, otherwise the id being confirmed.
    property string opened: ""
    property bool busy: false
    property string message: ""
    property bool suspendAvailable: false
    readonly property var selectedAction: actionFor(opened)
    readonly property var actions: [
        { id: "reboot", label: "Neustart", detail: "Startet den Rechner neu.", confirm: true },
        { id: "logout", label: "Abmelden", detail: "Beendet die laufende Sitzung.", confirm: true },
        { id: "lock", label: "Sperren", detail: "Sperrt die Sitzung.", confirm: false },
        { id: "suspend", label: "Ruhezustand", detail: "Versetzt den Rechner in Bereitschaft.", confirm: true },
        { id: "shutdown", label: "Ausschalten", detail: "Schaltet den Rechner aus.", confirm: true }
    ]
    function actionFor(id) {
        for (const a of actions) if (a.id === id) return a;
        return null;
    }
    function request(a) {
        if (busy) return;
        message = "";
        if (a.id === "suspend" && !suspendAvailable) {
            message = "Ruhezustand wird auf diesem System nicht unterstützt (elogind/loginctl fehlt oder verweigert).";
            return;
        }
        if (a.confirm) { opened = a.id; return; }
        run(a);
    }
    function run(a) {
        if (busy) return;
        busy = true;
        message = "";
        powerAction.pending = a.id;
        powerAction.running = true;
    }
    Process {
        id: powerAction
        property string pending: ""
        command: ["sh", root.home + "power-action.sh", pending]
        onExited: (code, status) => {
            root.busy = false;
            if (code !== 0) root.message = "Aktion fehlgeschlagen — bitte Dienst oder Programm prüfen.";
        }
    }
    Process {
        id: suspendCheck
        command: ["sh", "-c", "command -v loginctl >/dev/null 2>&1 && loginctl can-suspend 2>/dev/null || echo no"]
        running: true
        stdout: SplitParser { onRead: data => { const t = data.trim(); if (t !== "") root.suspendAvailable = t === "yes"; } }
    }
    Rectangle {
        anchors.centerIn: parent; width: 26; height: 26; radius: 6
        color: root.opened !== "" ? root.surface : powerMouse.containsMouse ? root.hover : "transparent"
        border.width: 1
        border.color: root.opened !== "" || powerMouse.containsMouse ? root.accent : "transparent"
    }
    Canvas {
        anchors.centerIn: parent
        width: 15; height: 15
        onPaint: {
            const c = getContext("2d"); c.reset();
            c.scale(width / 28, height / 28);
            c.strokeStyle = root.foreground; c.lineWidth = 2.4; c.lineCap = "round";
            c.beginPath(); c.arc(14, 15, 7, -Math.PI / 4, Math.PI * 1.25); c.stroke();
            c.beginPath(); c.moveTo(14, 5); c.lineTo(14, 14); c.stroke();
        }
    }
    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.message = ""; root.opened = root.opened === "" ? "menu" : ""; }
    }
    PopupWindow {
        id: popup
        anchor.window: root.panel
        anchor.rect.x: Math.max(0, root.panel.width - implicitWidth - 8)
        anchor.rect.y: root.panel.height
        implicitWidth: 276
        implicitHeight: cardColumn.implicitHeight + 36
        visible: root.opened !== ""
        grabFocus: true
        onVisibleChanged: { if (visible) card.forceActiveFocus(); else root.opened = ""; }
        color: root.background
        MouseArea { anchors.fill: parent; onClicked: root.opened = "" }
        Rectangle {
            id: card
            readonly property int cardWidth: 276
            x: 0
            width: cardWidth
            height: cardColumn.implicitHeight + 36
            color: root.background
            border.width: 1
            border.color: root.accent
            radius: 0
            focus: true
            Keys.onEscapePressed: {
                if (root.opened !== "" && root.opened !== "menu") root.opened = "menu";
                else root.opened = "";
            }
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: cardColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    Text {
                        visible: root.selectedAction !== null
                        text: "< Zurück"
                        color: backMouse.containsMouse ? root.accent : root.foreground; font.family: "monospace"; font.pixelSize: 13
                        MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.opened = "menu" }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.selectedAction ? root.selectedAction.label : "Power"
                        color: root.foreground; font.family: "monospace"; font.pixelSize: 13; font.letterSpacing: root.selectedAction ? 1 : 2
                    }
                    Text {
                        text: "x"
                        color: closeMouse.containsMouse ? root.accent : root.foreground; font.family: "monospace"; font.pixelSize: 13
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.opened = "" }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.topMargin: 2; Layout.bottomMargin: 2; height: 1; color: root.accent; opacity: 0.55 }
                Text {
                    Layout.fillWidth: true
                    visible: root.message !== ""
                    text: root.message
                    color: root.accent; font.family: "monospace"; font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.opened === "menu"
                    spacing: 2
                    Repeater {
                        model: root.actions
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 6
                            color: rowMouse.containsMouse ? root.hover : "transparent"
                            border.width: 0
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: rowMouse.containsMouse ? root.strong : root.foreground; font.family: "monospace"; font.pixelSize: 13
                                }
                                Text {
                                    visible: modelData.confirm
                                    text: ">"
                                    color: rowMouse.containsMouse ? root.strong : root.foreground; font.family: "monospace"; font.pixelSize: 13
                                }
                            }
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !root.busy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.request(modelData)
                            }
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.opened !== "" && root.opened !== "menu"
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: root.selectedAction ? root.selectedAction.detail : ""
                        color: root.foreground; font.family: "monospace"; font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Diese Aktion wirkt auf die laufende Sitzung oder den Rechner."
                        color: root.accent; font.family: "monospace"; font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            id: cancelButton
                            Layout.fillWidth: true
                            implicitHeight: 30
                            enabled: !root.busy
                            font.family: "monospace"; font.pixelSize: 13
                            text: "Abbrechen"
                            onClicked: root.opened = "menu"
                            contentItem: Text { text: cancelButton.text; color: root.foreground; font: cancelButton.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { radius: 6; color: cancelButton.hovered ? root.hover : root.surface; border.width: 1; border.color: cancelButton.hovered ? root.accent : root.controlBorder }
                        }
                        Button {
                            id: confirmButton
                            Layout.fillWidth: true
                            implicitHeight: 30
                            enabled: !root.busy
                            font.family: "monospace"; font.pixelSize: 13
                            text: root.busy ? "Läuft …" : "Bestätigen"
                            onClicked: { const a = root.actionFor(root.opened); if (a) root.run(a); }
                            contentItem: Text { text: confirmButton.text; color: root.foreground; font: confirmButton.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; opacity: confirmButton.enabled ? 1 : 0.45 }
                            background: Rectangle { radius: 6; color: confirmButton.hovered ? root.hover : root.surface; border.width: 1; border.color: confirmButton.hovered ? root.accent : root.controlBorder }
                        }
                    }
                }
            }
        }
    }
}
