pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string family: regular.status === FontLoader.Ready ? regular.name : "MesloLGS Nerd Font Mono"
    FontLoader { id: regular; source: "fonts/Meslo-Regular.ttf" }
    FontLoader { source: "fonts/Meslo-Bold.ttf" }
}