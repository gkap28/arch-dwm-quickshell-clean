import QtQuick
import Quickshell
import Quickshell.Io

pragma ComponentBehavior: Bound

Item {
    id: root

    property int updateCount: 0
    property var updateList: []
    property bool checking: false
    property bool detailVisible: false

    // Timer für automatische Aktualisierung (alle 30 Minuten)
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Initial laden
    Component.onCompleted: {
        root.refresh()
    }

    Process {
        id: updateProcess

        command: ["/usr/local/bin/check-updates.sh"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                root.updateCount = parseInt(output) || 0
                console.log("Update-Count:", root.updateCount)
            }
        }

        onRunningChanged: {
            if (!running) {
                root.checking = false
            }
        }
    }

    Process {
        id: detailProcess

        command: ["bash", "-c", "checkupdates 2>/dev/null | head -20; echo '--- AUR ---'; paru -Qua 2>/dev/null | head -10"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("detailProcess output:", this.text)
                const lines = this.text.split("\n")
                    .map(function(l) { return l.trim(); })
                    .filter(function(l) { return l.length > 0 && l.indexOf("--- AUR ---") === -1; })
                root.updateList = lines.length > 0 ? lines : ["System ist aktuell"]
            }
        }
    }

    function refresh() {
        if (root.checking) return
        root.checking = true
        updateProcess.running = true
    }

    function loadDetails() {
        console.log("loadDetails called, running:", detailProcess.running)
        if (detailProcess.running) return
        detailProcess.running = true
    }

    function toggle() {
        detailVisible = !detailVisible
        if (detailVisible) {
            root.loadDetails()
        }
    }

    function close() {
        detailVisible = false
    }

    function open() {
        detailVisible = true
        root.loadDetails()
    }
}
