/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
 
import QtQuick 2.8

import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "components"

PlasmaCore.ColorScope {
    id: root

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup

    width: 1600
    height: 900

    property string notificationMessage
    property string clock_color: "#fff"

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    /*
    Repeater {
        model: screenModel

        Background {
            x: geometry.x; y: geometry.y; width: geometry.width; height: geometry.height
            sceneBackgroundType: config.type
            sceneBackgroundColor: config.color
            sceneBackgroundImage: config.background
        }
    }*/

    Image {
        id: wallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        Rectangle {
            color: "#000000"
            anchors.fill: wallpaper
            z: -1
        }
        source: config.background || config.Background
        smooth: true;
        asynchronous: true
        cache: true
        clip: true
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1 || userListComponent.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive || config.type != "image"

        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }

        //takes one full minute for the ui to disappear
        Timer {
            id: fadeoutTimer
            running: true
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    loginScreenRoot.uiVisible = false;
                }
            }
        }

        StackView {
            id: mainStack
            anchors{
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: parent.width/9
            }
            height: 400
            width: 275

            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            Timer {
                //SDDM has a bug in 0.13 where even though we set the focus on the right item within the window, the window doesn't have focus
                //it is fixed in 6d5b36b28907b16280ff78995fef764bb0c573db which will be 0.14
                //we need to call "window->activate()" *After* it's been shown. We can't control that in QML so we use a shoddy timer
                //it's been this way for all Plasma 5.x without a huge problem
                running: true
                repeat: false
                interval: 200
                onTriggered: mainStack.forceActiveFocus()
            }

            initialItem: Login {
                id: userListComponent
                userListModel: userModel
                loginScreenUiVisible: loginScreenRoot.uiVisible
                PlasmaComponents.Label{
                    id: anotherUserLabel
                    anchors.top: parent.bottom
                    anchors.topMargin: -6
                    text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Not Listed?")
                    font.pointSize: 10
                    MouseArea {
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: mainStack.push(userPromptComponent)
                        enabled: true
                        visible: !userListComponent.showUsernamePrompt && !inputPanel.keyboardActive
                    }
                }
                userListCurrentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                lastUserName: userModel.lastUser

                showUserList: {
                    if ( !userListModel.hasOwnProperty("count")
                    || !userListModel.hasOwnProperty("disableAvatarsThreshold"))
                        return (userList.y + mainStack.y) > 0

                    if ( userListModel.count == 0 ) return false

                    return userListModel.count <= userListModel.disableAvatarsThreshold && (userList.y + mainStack.y) > 0
                }

                notificationMessage: {
                    var text = ""
                    if (keystateSource.data["Caps Lock"]["Locked"]) {
                        text += i18nd("plasma_lookandfeel_org.kde.lookandfeel","Caps Lock is on")
                        if (root.notificationMessage) {
                            text += " • "
                        }
                    }
                    text += root.notificationMessage
                    return text
                }

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionButton.currentIndex)
                }
            }

            Behavior on opacity {
                OpacityAnimator {
                    duration: units.longDuration
                }
            }
        }

        Loader {
            id: inputPanel
            state: "hidden"
            property bool keyboardActive: item ? item.active : false
            onKeyboardActiveChanged: {
                if (keyboardActive) {
                    state = "visible"
                } else {
                    state = "hidden";
                }
            }
            source: "components/VirtualKeyboard.qml"
            anchors {
                left: parent.left
                right: parent.right
            }

            function showHide() {
                state = state == "hidden" ? "visible" : "hidden";
            }

            states: [
                State {
                    name: "visible"
                    PropertyChanges {
                        target: mainStack
                        y: Math.min(0, root.height - inputPanel.height - userListComponent.visibleBoundary)
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: root.height - inputPanel.height
                        opacity: 1
                    }
                },
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: mainStack
                        y: 0
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: root.height - root.height/4
                        opacity: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                inputPanel.item.activated = true;
                                Qt.inputMethod.show();
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.OutQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: units.longDuration
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: units.longDuration
                                easing.type: Easing.InQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: units.longDuration
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                Qt.inputMethod.hide();
                            }
                        }
                    }
                }
            ]
        }


        Component {
            id: userPromptComponent
            Login {
                showUsernamePrompt: true
                notificationMessage: root.notificationMessage
                loginScreenUiVisible: loginScreenRoot.uiVisible

                // using a model rather than a QObject list to avoid QTBUG-75900
                userListModel: ListModel {
                    ListElement {
                        name: ""
                        iconSource: ""
                    }
                    Component.onCompleted: {
                        // as we can't bind inside ListElement
                        setProperty(0, "name", i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Another user"));
                    }
                }

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionButton.currentIndex)
                }

                actionItems:
                    ActionButton {
                    Image {
                        source: "assets/back_button.svgz"
                        sourceSize: Qt.size(38, 38)
                        smooth: true
                    }
                    text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Back")
                    MouseArea {
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: mainStack.pop()
                    }
                }
            }
        }

        Rectangle {
            id: blurBg
            anchors.fill: mainStack/2
            anchors{
                //left: mainStack.left
                //leftMargin: mainStack.width/6
                //right: mainStack.right
                horizontalCenter: mainStack.horizontalCenter
                //verticalCenter: mainStack.verticalCenter
                bottom: mainStack.bottom
                bottomMargin: 95
                top: mainStack.top
                topMargin: 150
            }
            color: "#272727"
            opacity: 0.1
            height: 175
            width: 300
            z:-1
        }

        Rectangle {
            id: formBg
            anchors{
                fill:blurBg
                left: mainStack.left
                right: mainStack.right
                //bottom: mainStack.bottom
                //top: mainStack.top
            }
            width: mainStack.width
            radius: 7
            color: "#272727"
            border.color: "#464646"
            border.width: 1
            opacity: 0.5
            z:-1
        }

        ShaderEffectSource {
            id: blurArea
            sourceItem: wallpaper
            width: blurBg.width
            height: blurBg.height
            anchors.centerIn: blurBg
            sourceRect: Qt.rect(x,y,width,height)
            visible: true
            z:-2
        }

        GaussianBlur {
            id: blur
            height: blurBg.height
            width: blurBg.width
            source: blurArea
            radius: 8
            cached: true
            anchors.centerIn: blurBg
            visible: true
            z:-2
        }

    //Header

    Rectangle {
        id: topBar
        anchors {
            left: parent.left
            right: parent.right
            //top: parent.top
            //bottom: header.bottom
        }
        height: header.height + 6
        color: "#181818"
        opacity: 0.85
        z:0
    }

    Rectangle {
        id: topBarBlur
        anchors.fill: topBar
        color: "#272727"
        opacity: 0.1
        height: 175
        width: 300
        z:-1
    }

    ShaderEffectSource {
        id: topBarBlurArea
        sourceItem: wallpaper
        width: topBarBlur.width
        height: topBarBlur.height
        anchors.centerIn: topBarBlur
        sourceRect: Qt.rect(x,y,width,height)
        visible: true
        z:-2
    }

    GaussianBlur {
        id: topBarBlurEffect
        height: topBarBlur.height
        width: topBarBlur.width
        source: topBarBlurArea
        radius: 8
        cached: true
        anchors.centerIn: topBarBlur
        visible: true
        z:-2
    }

    RowLayout {
        id: header
        spacing: 8
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 2
            leftMargin: 12
            rightMargin: 6
        }

        Behavior on opacity {
            OpacityAnimator {
                duration: units.longDuration
            }
        }

        PlasmaComponents.Label{
            id: welcomeLabel
            height: batteryLabel.font.pointSize*2
            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Starts with")
            font.pointSize: 10
            font.weight: Font.Bold
        }

        Item {
            width: 1
        }

        SessionButton {
                id: sessionButton
        }

        Item {
            Layout.fillWidth: true
        }

        PlasmaComponents.ToolButton {
            text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to show/hide virtual keyboard", "Virtual Keyboard")
            iconName: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
            onClicked: inputPanel.showHide()
            visible: inputPanel.status == Loader.Ready
        }

        KeyboardButton {}

        Notification {}

        Volume {}

        Battery {}

        Bluetooth {}

        Network {}

        Clock {}

        Restart {}

        Shutdown {}
    }

        //Footer
        RowLayout {
            id: footer
            anchors {
                bottom: parent.bottom
                left: parent.left
                margins: units.smallSpacing
            }

            Behavior on opacity {
                OpacityAnimator {
                    duration: units.longDuration
                }
            }

            Logo {}
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            notificationMessage = i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Login Failed")
        }
        onLoginSucceeded: {
            //note SDDM will kill the greeter at some random point after this
            //there is no certainty any transition will finish, it depends on the time it
            //takes to complete the init
            mainStack.opacity = 0
            footer.opacity = 0
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.start();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: notificationMessage = ""
    }
}
