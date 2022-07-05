import QtQuick 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.workspace.components 2.0 as PW

Rectangle{
    implicitWidth:  22
    implicitHeight: parent.height
    color: "transparent"
    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        id: shutdownButton
        source: "artwork/poweroff.svg"
        sourceSize: Qt.size(passwordBox.height, passwordBox.height)
        smooth: true
        opacity: 1
    }

    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
        onClicked: sddm.powerOff()
        enabled: sddm.canPowerOff
    }
}
