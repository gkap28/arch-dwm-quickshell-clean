import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

Flickable {
    id: root

    required property var systemManagementModel
    required property var capabilities
    required property var updateModel
    property string clockText: ""
    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    activeFocusOnTab: true
    onHeightChanged: Qt.callLater(root.revealFocusedControl)
    onContentHeightChanged: Qt.callLater(root.revealFocusedControl)

    function revealFocusedControl() {
        delegateControls.revealFocusedControl();
        regionalControls.revealFocusedControl();
        informationControls.revealFocusedControl();
    }

    function scrollTo(position) {
        root.contentY = Math.max(0, Math.min(position, Math.max(0, root.contentHeight - root.height)));
    }

    function reveal(target) {
        const position = target.mapToItem(content, 0, 0);
        if (position.y < root.contentY) root.scrollTo(position.y);
        else if (position.y + target.height > root.contentY + root.height)
            root.scrollTo(position.y + target.height - root.height);
    }

    Keys.onPressed: event => {
        const lineStep = Math.max(Theme.spacingXl, 40);
        const pageStep = Math.max(lineStep, root.height - Theme.spacingXl);
        if (event.key === Qt.Key_Down) root.scrollTo(root.contentY + lineStep);
        else if (event.key === Qt.Key_Up) root.scrollTo(root.contentY - lineStep);
        else if (event.key === Qt.Key_PageDown) root.scrollTo(root.contentY + pageStep);
        else if (event.key === Qt.Key_PageUp) root.scrollTo(root.contentY - pageStep);
        else if (event.key === Qt.Key_Home) root.scrollTo(0);
        else if (event.key === Qt.Key_End) root.scrollTo(root.contentHeight - root.height);
        else return;
        event.accepted = true;
    }

    function statusColor(status) {
        if (status === "available" || status === "ready") return Theme.success;
        if (status === "partial" || status === "restricted") return Theme.warning;
        if (status === "unavailable" || status === "failure") return Theme.danger;
        return Theme.menuMutedText;
    }

    function severityColor(severity) {
        if (severity === "critical" || severity === "security") return Theme.danger;
        if (severity === "important" || severity === "bugfix") return Theme.warning;
        return Theme.accent;
    }

    function restartLabel(value) {
        if (value === "none") return "No restart required";
        if (value === "application") return "Restart applications";
        if (value === "session") return "Log out and back in";
        if (value === "system") return "Restart the computer";
        if (value === "security-session") return "Security update / log out required";
        if (value === "security-system") return "Security update / restart required";
        return "Restart requirement unknown";
    }

    function ageLabel(value) {
        if (!/^(0|[1-9][0-9]*)$/.test(value)) return "Unknown";
        const seconds = Number(value);
        if (seconds < 60) return seconds + "s ago";
        if (seconds < 3600) return Math.floor(seconds / 60) + "m ago";
        if (seconds < 86400) return Math.floor(seconds / 3600) + "h ago";
        return Math.floor(seconds / 86400) + "d ago";
    }

    component StatusCard: Rectangle {
        id: statusCard

        required property string label
        required property string status
        required property string value
        required property string detail
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(72, statusContent.implicitHeight + Theme.spacingLg * 2)
        color: Theme.controlNormalFill
        border.color: root.statusColor(status)
        border.width: Theme.controlBorderWidth
        radius: Theme.controlRadius

        ColumnLayout {
            id: statusContent
            anchors.fill: parent
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacingXs

            RowLayout {
                Layout.fillWidth: true
                PlainText {
                    Layout.fillWidth: true
                    text: statusCard.label
                    color: Theme.controlNormalText
                    font.bold: true
                    elide: Text.ElideRight
                }
                PlainText {
                    text: statusCard.value
                    color: root.statusColor(statusCard.status)
                    font.bold: true
                }
            }
            PlainText {
                Layout.fillWidth: true
                text: statusCard.detail
                color: Theme.menuMutedText
                wrapMode: Text.WordWrap
            }
        }
    }

    component DataList: ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: Theme.spacingSm
        boundsBehavior: Flickable.StopAtBounds
        activeFocusOnTab: true
        keyNavigationEnabled: true
    }

    component PlainText: UiText {
        textFormat: Text.PlainText
    }

    ColumnLayout {
        id: content
        width: root.width
        spacing: Theme.spacingLg

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMd

            PlainText {
                Layout.fillWidth: true
                text: "Arch Linux · Pacman und lokale Systeminformationen"
                color: Theme.accent
                font.bold: true
                elide: Text.ElideRight
            }
            PlainText {
                text: "SYSTEM STATUS"
                color: Theme.menuMutedText
                font.pixelSize: Theme.fontCaptionSize
                font.bold: true
            }
            ShellButton {
                objectName: "reloadSystemStatus"
                label: root.systemManagementModel.busy ? "Loading..." : "Reload status"
                enabled: !root.systemManagementModel.busy
                onActivated: root.systemManagementModel.refresh()
            }
        }

        PlainText {
            Layout.fillWidth: true
            visible: root.systemManagementModel.snapshotState === "loading"
                || root.systemManagementModel.snapshotState === "failure"
                || root.systemManagementModel.snapshotState === "partial"
            text: root.systemManagementModel.message
            color: root.statusColor(root.systemManagementModel.snapshotState)
            wrapMode: Text.WordWrap
        }

        PlainText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.systemManagementModel.discoveryDetail
            color: Theme.warning
            wrapMode: Text.WordWrap
        }

        SectionLabel { label: "Arch Linux updates" }

        ArchUpdateControls {
            updateModel: root.updateModel
        }

        SystemRegionalControls {
            id: regionalControls
            model: root.systemManagementModel
            viewportHeight: root.height
            onRevealRequested: target => root.reveal(target)
        }

        SystemDelegateControls {
            id: delegateControls
            model: root.systemManagementModel
            onRevealRequested: target => root.reveal(target)
        }

        SystemInformationControls {
            id: informationControls
            model: root.systemManagementModel
            onRevealRequested: target => root.reveal(target)
        }

        SectionLabel { label: "Administration boundaries" }

        Repeater {
            model: root.capabilities
            delegate: StatusCard {
                id: capabilityCard
                required property var modelData
                label: capabilityCard.modelData.label
                status: capabilityCard.modelData.status
                value: capabilityCard.modelData.capabilityClass.toUpperCase()
                detail: capabilityCard.modelData.detail + " / " + capabilityCard.modelData.provider
            }
        }

        PlainText {
            Layout.fillWidth: true
            text: "Reload status reads local system providers. Arch updates run visibly in a terminal through pacman and an installed AUR helper. Delegated administration launches require confirmation; those tools own their internal changes."
            color: Theme.menuMutedText
            font.pixelSize: Theme.fontCaptionSize
            wrapMode: Text.WordWrap
        }
    }
}
