import QtQuick 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.workspace.components 2.0 as PW

Rectangle{
    implicitWidth:  200
    implicitHeight: 70
    color: "transparent"
    Image {
        anchors{
            bottom: parent.bottom
            left: parent.left
            //right: parent.right
            bottomMargin: 15
            leftMargin: 15
        }
        id: logo
        source: "assets/new-ubuntu-logo.svg"
        sourceSize: Qt.size(200, 70)
        smooth: true
        opacity: 1
    }
}
