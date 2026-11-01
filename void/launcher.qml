// Presentation adapted from ChrisTitusTech/dwm-titus LauncherWindow and LauncherResultDelegate.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ShellRoot {
    id: root
    readonly property string background: "#2E3440"
    readonly property string surface: "#434C5E"
    readonly property string foreground: "#ECEFF4"
    readonly property string muted: "#D8DEE9"
    readonly property string accent: "#81A1C1"
    readonly property string transparent: "#00000000"
    property string query: ""
    property string category: ""
    readonly property var groups: [
        {id:"",label:"Alle"}, {id:"Network",label:"Internet"},
        {id:"Office",label:"Büro"}, {id:"Development",label:"Entwicklung"},
        {id:"Graphics",label:"Grafik"}, {id:"AudioVideo",label:"Medien"},
        {id:"Game",label:"Spiele"}, {id:"System",label:"System"},
        {id:"Utility",label:"Zubehör"} ]
    readonly property var applications: DesktopEntries.applications.values
    function matches(entry, id) { return id === "" || (entry.categories || []).includes(id); }
    function categoryLabel(entry) {
        for (const group of groups) if (group.id !== "" && matches(entry, group.id)) return group.label;
        return "Sonstige";
    }
    readonly property var results: applications.filter(entry => {
        const text = [entry.name, entry.genericName, entry.comment, (entry.keywords || []).join(" ")].join(" ").toLowerCase();
        return matches(entry, category) && text.includes(query.toLowerCase());
    }).sort((a, b) => a.name.localeCompare(b.name))
    function select(index) {
        list.currentIndex = Math.max(0, Math.min(list.count - 1, index));
        if (list.count) list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }
    function launch(index) {
        const entry = results[index];
        if (!entry) return;
        entry.execute(); Qt.quit();
    }
    FloatingWindow {
        id: window
        title: "Void Applications"
        screen: Quickshell.screens.find(s => s.x === Number(Quickshell.env("DWM_VOID_LAUNCHER_X")) && s.y === Number(Quickshell.env("DWM_VOID_LAUNCHER_Y"))) || Quickshell.screens[0]
        implicitWidth: screen ? Math.min(820, screen.width) : 820
        implicitHeight: screen ? Math.min(600, screen.height) : 600
        // Fixed hints make this an actual floating window under dwm too.
        minimumSize: Qt.size(implicitWidth, implicitHeight)
        maximumSize: Qt.size(implicitWidth, implicitHeight)
        color: root.background
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()
        Rectangle {
            anchors.fill: parent
            color: root.background; border.color: root.accent; border.width: 1; radius: 0
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 16
                RowLayout {
                    Layout.fillWidth: true; spacing: 16
                    Rectangle { Layout.preferredWidth: 4; Layout.preferredHeight: 50; color: root.accent; radius: 2 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { Layout.fillWidth: true; text: "PROGRAMMVERZEICHNIS"; color: root.accent; font.family: Typography.family; font.pixelSize: 11; font.bold: true }
                        Text { Layout.fillWidth: true; text: "Programme"; color: root.foreground; font.family: Typography.family; font.pixelSize: 24; font.bold: true }
                    }
                    Text { text: root.applications.length + " Programme"; color: root.accent; font.family: Typography.family; font.pixelSize: 12 }
                    Text { text: "×"; color: root.foreground; font.pixelSize: 18; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.quit() } }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 44
                    radius: 8; color: root.background; border.width: 1; border.color: root.accent
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "/"; color: root.accent; font.family: Typography.family; font.pixelSize: 16 }
                    TextInput {
                        id: search
                        anchors.fill: parent; anchors.leftMargin: 38; anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.foreground; selectionColor: root.surface; selectedTextColor: root.foreground
                        font.family: Typography.family; font.pixelSize: 16
                        clip: true; focus: true
                        Component.onCompleted: forceActiveFocus()
                        onTextChanged: { root.query = text; root.select(0); }
                        Keys.onEscapePressed: Qt.quit()
                        Keys.onReturnPressed: root.launch(list.currentIndex)
                        Keys.onEnterPressed: root.launch(list.currentIndex)
                        Keys.onDownPressed: root.select(list.currentIndex + 1)
                        Keys.onUpPressed: root.select(list.currentIndex - 1)
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_PageDown) { root.select(list.currentIndex + 8); event.accepted = true; }
                            else if (event.key === Qt.Key_PageUp) { root.select(list.currentIndex - 8); event.accepted = true; }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; visible: !search.text && !search.preeditText; text: "Programme suchen …"; color: root.muted; font: search.font }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "KATEGORIEN"; color: root.accent; font.family: Typography.family; font.pixelSize: 11; font.bold: true }
                    Text { text: root.results.length + " angezeigt"; color: root.muted; font.family: Typography.family; font.pixelSize: 11 }
                }
                Flickable {
                    Layout.fillWidth: true; Layout.preferredHeight: 34
                    contentWidth: categories.width; contentHeight: height; clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Row {
                        id: categories; spacing: 6
                        Repeater {
                            model: root.groups
                            Rectangle {
                                required property var modelData
                                readonly property bool selected: root.category === modelData.id
                                width: categoryText.implicitWidth + 22; height: 28; radius: 6
                                color: selected ? root.surface : categoryMouse.containsMouse ? "#4C566A" : root.surface
                                border.width: 1; border.color: selected || categoryMouse.containsMouse ? root.accent : "#3B4252"
                                Text { id: categoryText; anchors.centerIn: parent; text: modelData.label + " " + root.applications.filter(e => root.matches(e, modelData.id)).length; color: root.foreground; font.family: Typography.family; font.pixelSize: 12 }
                                MouseArea { id: categoryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.category = modelData.id; root.select(0); search.forceActiveFocus(); } }
                            }
                        }
                    }
                }
                ListView {
                    id: list
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 4; model: root.results; currentIndex: 0
                    onCurrentIndexChanged: if (count) positionViewAtIndex(currentIndex, ListView.Contain)
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: list.currentIndex === index
                        width: list.width; height: 58; radius: 8
                        color: selected ? root.surface : mouse.containsMouse ? "#4C566A" : root.transparent
                        border.width: 1; border.color: selected ? root.accent : root.transparent
                        RowLayout {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 16; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 16
                            Rectangle { Layout.preferredWidth: 3; Layout.preferredHeight: 34; visible: row.selected; color: root.accent; radius: 2 }
                            Image { Layout.preferredWidth: 28; Layout.preferredHeight: 28; source: Quickshell.iconPath(row.modelData.icon || "application-x-executable", true) }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { Layout.fillWidth: true; text: row.modelData.name; elide: Text.ElideRight; color: root.foreground; font.family: Typography.family; font.pixelSize: 14; font.bold: row.selected }
                                Text { Layout.fillWidth: true; text: (row.modelData.genericName || row.modelData.comment || "") + "  ·  " + root.categoryLabel(row.modelData); elide: Text.ElideRight; color: root.muted; font.family: Typography.family; font.pixelSize: 12 }
                            }
                        }
                        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(row.index) }
                    }
                    Text { anchors.centerIn: parent; visible: list.count === 0; text: "Keine Programme gefunden"; color: root.muted; font.family: Typography.family; font.pixelSize: 14 }
                }
            }
        }
    }
}
