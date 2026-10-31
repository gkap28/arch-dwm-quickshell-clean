import QtQuick
import Quickshell

ShellRoot {
    id: root
    readonly property string background: "#2E3440"
    readonly property string surface: "#434C5E"
    readonly property string hover: "#4C566A"
    readonly property string foreground: "#ECEFF4"
    readonly property string muted: "#D8DEE9"
    readonly property string accent: "#88C0D0"
    property string query: ""
    readonly property var applications: DesktopEntries.applications.values
    readonly property var results: applications.filter(entry => {
        const text = [entry.name, entry.genericName, entry.comment, (entry.keywords || []).join(" ")].join(" ").toLowerCase();
        return text.includes(query.toLowerCase());
    }).sort((a, b) => a.name.localeCompare(b.name))
    function launch(index) {
        const entry = results[index];
        if (!entry) return;
        entry.execute();
        Qt.quit();
    }
    FloatingWindow {
        id: window
        title: "Void Applications"
        screen: Quickshell.screens.find(s => s.x === Number(Quickshell.env("DWM_VOID_LAUNCHER_X")) && s.y === Number(Quickshell.env("DWM_VOID_LAUNCHER_Y"))) || Quickshell.screens[0]
        implicitWidth: 460
        implicitHeight: 560
        minimumSize: Qt.size(460, 560)
        maximumSize: Qt.size(460, 560)
        color: root.background
        visible: true
        onVisibleChanged: { if (!visible) Qt.quit(); }
        Item {
            anchors.fill: parent
            anchors.margins: 16
            Text {
                text: "Programme"
                color: root.accent
                font.family: "monospace"; font.pixelSize: 20; font.bold: true
            }
            Rectangle {
                id: searchBox
                anchors.top: parent.top; anchors.topMargin: 40
                width: parent.width; height: 42
                radius: 6; color: root.surface
                border.width: 1; border.color: root.accent
                TextInput {
                    id: search
                    anchors.fill: parent; anchors.margins: 10
                    color: root.foreground
                    font.family: "monospace"; font.pixelSize: 16
                    clip: true; focus: true
                    Component.onCompleted: forceActiveFocus()
                    onTextChanged: { root.query = text; list.currentIndex = 0; }
                    Keys.onEscapePressed: Qt.quit()
                    Keys.onReturnPressed: root.launch(list.currentIndex)
                    Keys.onEnterPressed: root.launch(list.currentIndex)
                    Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                    Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                    Text { visible: !search.text && !search.preeditText; text: "Suchen …"; color: root.muted; font: search.font }
                }
            }
            ListView {
                id: list
                anchors.top: searchBox.bottom; anchors.topMargin: 12
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                clip: true; spacing: 4
                model: root.results
                currentIndex: 0
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width; height: 46; radius: 6
                    color: mouse.containsMouse ? root.hover : list.currentIndex === index ? root.surface : root.background
                    border.width: list.currentIndex === index ? 1 : 0; border.color: root.accent
                    Image {
                        id: icon
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        width: 26; height: 26
                        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                    }
                    Text {
                        anchors.left: icon.right; anchors.leftMargin: 10; anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.name; elide: Text.ElideRight
                        color: root.foreground; font.family: "monospace"; font.pixelSize: 15
                    }
                    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(row.index) }
                }
                Text { anchors.centerIn: parent; visible: list.count === 0; text: "Keine Programme gefunden"; color: root.muted; font.family: "monospace"; font.pixelSize: 15 }
            }
        }
    }
}
