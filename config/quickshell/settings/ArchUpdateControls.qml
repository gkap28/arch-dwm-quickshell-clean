import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

ColumnLayout {
    id: root

    required property var updateModel
    Layout.fillWidth: true
    spacing: Theme.spacingMd

    Component.onCompleted: root.updateModel.loadDetails()

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingMd

        UiText {
            Layout.fillWidth: true
            text: root.updateModel.checking ? "Updates werden gesucht..." :
                root.updateModel.updateCount + " Updates verfügbar"
            color: root.updateModel.updateCount > 0 ? Theme.warning : Theme.success
            font.bold: true
            elide: Text.ElideRight
        }

        ShellButton {
            objectName: "refreshArchUpdates"
            label: "Prüfen"
            enabled: !root.updateModel.checking
            onActivated: {
                root.updateModel.refresh();
                root.updateModel.loadDetails();
            }
        }

        ShellButton {
            objectName: "applyArchUpdates"
            label: "Aktualisieren"
            enabled: root.updateModel.updateCount > 0
            onActivated: root.updateModel.update()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(220, updateList.contentHeight + Theme.spacingMd * 2)
        Layout.minimumHeight: 72
        color: Theme.controlNormalFill
        border.color: Theme.controlNormalBorder
        border.width: Theme.controlBorderWidth
        radius: Theme.controlRadius

        ListView {
            id: updateList
            anchors.fill: parent
            anchors.margins: Theme.spacingMd
            clip: true
            spacing: Theme.spacingSm
            model: root.updateModel.updateList
            boundsBehavior: Flickable.StopAtBounds

            delegate: UiText {
                required property string modelData
                width: ListView.view.width
                text: modelData
                color: Theme.controlNormalText
                elide: Text.ElideRight
            }
        }
    }

    UiText {
        Layout.fillWidth: true
        text: "Die Aktualisierung läuft sichtbar im Terminal: sudo pacman -Syu und, falls installiert, paru oder yay. Pacman und der AUR-Helper fragen vor der Ausführung nach Bestätigung."
        color: Theme.menuMutedText
        wrapMode: Text.WordWrap
    }
}
