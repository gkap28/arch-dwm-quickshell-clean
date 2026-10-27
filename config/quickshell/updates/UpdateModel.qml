import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

pragma ComponentBehavior: Bound

Item {
    id: root

    property int updateCount: 0
    property var updateList: []
    property bool checking: false
    property bool detailVisible: false

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Process {
        id: countProcess

        command: Commands.archUpdatesCommand("count")
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                root.updateCount = parseInt(output, 10) || 0;
            }
        }

        onRunningChanged: {
            if (!running) root.checking = false;
        }
    }

    Process {
        id: detailProcess

        command: Commands.archUpdatesCommand("list")
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                    .map(function(line) { return line.trim(); })
                    .filter(function(line) { return line.length > 0; });
                root.updateList = lines.length > 0 ? lines : ["System ist aktuell"];
            }
        }
    }

    Process {
        id: applyProcess

        command: Commands.archUpdatesCommand("update")
        running: false
        onRunningChanged: {
            if (!running) root.refresh();
        }
    }

    function refresh() {
        if (root.checking) return;
        root.checking = true;
        countProcess.running = true;
    }

    function loadDetails() {
        if (!detailProcess.running) detailProcess.running = true;
    }

    function update() {
        if (applyProcess.running) return;
        root.close();
        applyProcess.running = true;
    }

    function toggle() {
        detailVisible = !detailVisible;
        if (detailVisible) root.loadDetails();
    }

    function close() {
        detailVisible = false;
    }

    function open() {
        detailVisible = true;
        root.loadDetails();
    }
}
