import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4
import QtQuick.Controls.Styles 1.4

TextField {
    placeholderTextColor: "#cccccc"
    palette.text: config.color
    font.pointSize: config.fontSize
    horizontalAlignment: TextInput.Right
    font.family: config.font
    Layout.maximumWidth: parent.width - 40
    background: Rectangle {
        color: "#1b1b19"
        opacity: 1
        radius: 6
        width: parent.width
        height: width / 8.5
        border.width: 2
        border.color: "#b6876e"
        anchors.centerIn: parent
    }
}
