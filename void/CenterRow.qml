import QtQuick
import QtQuick.Controls

Button {
    id: root
    property string detail: ""
    property bool navigates: false
    property bool selected: false
    implicitHeight: 28
    implicitWidth: 240
    font.family: Typography.family
    font.pixelSize: CenterTheme.bodySize
    padding: 8
    background: Rectangle {
        radius: 6
        color: root.hovered ? CenterTheme.hover : root.selected ? CenterTheme.surface : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: CenterTheme.border
    }
    contentItem: Item {
        implicitHeight: 16
        Text {
            anchors { left: parent.left; right: suffix.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: root.text; color: root.hovered ? CenterTheme.strong : CenterTheme.foreground
            font: root.font; elide: Text.ElideRight; opacity: root.enabled ? 1 : 0.45
        }
        Text {
            id: suffix
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: root.navigates ? ">" : root.detail
            color: root.selected ? CenterTheme.success : CenterTheme.foreground
            font: root.font; opacity: root.enabled ? 1 : 0.45
        }
    }
}