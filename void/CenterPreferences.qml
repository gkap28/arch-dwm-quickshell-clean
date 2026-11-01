pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME") + "/.local/share/dwm-void/"
    property bool power: true
    property bool volume: true
    property bool network: true
    property bool layout: true
    property bool seconds: false
    property int timeout: 0
    property bool busy: false
    property string message: ""
    function apply(text) {
        for (const line of text.trim().split("\n")) {
            const p = line.split("=");
            if (["power", "volume", "network", "layout", "seconds"].indexOf(p[0]) >= 0) root[p[0]] = p[1] === "1";
            else if (p[0] === "timeout") root.timeout = Number(p[1]);
        }
    }
    function setValue(key, value) {
        if (busy) return;
        message = ""; busy = true;
        writer.command = ["sh", home + "center-settings.sh", "set", key, value.toString()];
        writer.running = true;
    }
    Process {
        id: reader
        command: ["sh", root.home + "center-settings.sh", "read"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
    }
    Process {
        id: writer
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.message = text.trim() }
        onExited: (code, status) => { root.busy = false; if (code !== 0 && !root.message) root.message = "Einstellung konnte nicht gespeichert werden."; }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: if (!reader.running && !root.busy) reader.running = true }
}