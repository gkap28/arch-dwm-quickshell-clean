import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

pragma ComponentBehavior: Bound

ClickAwayPopup {
    id: root

    required property var updateModel
    required property var panelWindow

    readonly property int cardWidth: 360
    readonly property int cardHeight: 420
    readonly property int edgeMargin: Theme.rowSpacing

    visible: panelWindow !== null && panelWindow.screen !== null
        && updateModel.detailVisible
    grabFocus: true
    targetWindow: panelWindow
    popupWidth: cardWidth
    popupHeight: cardHeight
    popupX: panelWindow ? Math.max(edgeMargin, panelWindow.width - cardWidth - edgeMargin) : edgeMargin
    popupY: Theme.panelHeight
    onDismissed: updateModel.close()

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                content.forceActiveFocus();
            });
        }
    }

    Process {
        id: updateProc
        running: false
        onRunningChanged: {
            if (!running) {
                root.updateModel.refresh();
            }
        }
    }

    ShellSurface {
        id: content

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.updateModel.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.popupPadding
            spacing: Theme.popupSpacing

            // Header
            Text {
                Layout.fillWidth: true
                text: "System-Updates"
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleFontSize
                font.bold: true
            }

            // Update-Zähler
            Text {
                Layout.fillWidth: true
                text: root.updateModel.updateCount + " Updates verfügbar"
                color: root.updateModel.updateCount > 0 ? Theme.warning : Theme.success
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyFontSize
                font.bold: true
            }

            // Trennlinie
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            // Update-Liste
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.listSpacing
                model: root.updateModel.updateList

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 28
                    radius: Theme.radius
                    color: "transparent"

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.rowSpacing
                        anchors.rightMargin: Theme.rowSpacing
                        text: parent.modelData
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Trennlinie
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.rowSpacing

                ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight
                    label: "Aktualisieren"
                    enabled: root.updateModel.updateCount > 0
                    onActivated: {
                        updateProc.command = ["alacritty", "-e", "bash", "-c",
                            "sudo pacman -Syu && paru -Syu; echo; read -n 1 -s -r -p 'Enter zum Schliessen'"]
                        updateProc.running = true
                        root.updateModel.close()
                    }
                }

                ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight
                    label: "Schließen"
                    onActivated: root.updateModel.close()
                }
            }
        }
    }
}
