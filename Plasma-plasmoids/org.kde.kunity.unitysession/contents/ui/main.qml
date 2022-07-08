/*
 *  Copyright 2015 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.2
import QtQml 2.14
import QtQuick.Controls 1.1 as QtControls
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents // for Highlight
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.kquickcontrolsaddons 2.0 // kcmshell
import org.kde.plasma.private.quicklaunch 1.0 // Logic
import org.kde.kirigami 2.13 as Kirigami

import org.kde.plasma.private.sessions 2.0 as Sessions

Item {
    id: root

    readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property string displayedName: showFullName ? kuser.fullName : kuser.loginName

    readonly property bool showFace: plasmoid.configuration.showFace
    readonly property bool showSett: plasmoid.configuration.showSett
    readonly property bool showName: plasmoid.configuration.showName
    property var iconSett: plasmoid.configuration.icon

    readonly property bool showFullName: plasmoid.configuration.showFullName

    readonly property string userSwitcherDomain: "plasma_applet_org.kde.plasma.userswitcher"
    readonly property string lookAndFeelDomain: "plasma_lookandfeel_org.kde.lookandfeel"

    // TTY number and X display
    readonly property bool showTechnicalInfo: plasmoid.configuration.showTechnicalInfo
    readonly property bool iconPositionRight: plasmoid.configuration.iconPositionRight

    Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 13
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 12

    Plasmoid.toolTipTextFormat: Text.StyledText
    Plasmoid.toolTipSubText: i18nd(userSwitcherDomain, "You are logged in as <b>%1</b>", displayedName)

    PlasmaCore.DataSource {
        id: apps
        engine: "apps"

        property string appListConfig: plasmoid.configuration.appList
        property ListModel model: ListModel {}
        property var userApps
        
        onNewData: {
            model.append(Object.assign({}, data, userApps.get(sourceName)))
            disconnectSource(sourceName)
        }

        onAppListConfigChanged: {
            model.clear()
            userApps = new Map(JSON.parse(appListConfig))
            Array.from(userApps.keys()).forEach(connectSource)
        }
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: {
            var stdout = data["stdout"]

            if (callbacks[sourceName] !== undefined) {
                callbacks[sourceName](stdout);
            }

            exited(sourceName, stdout)
            disconnectSource(sourceName) // exec finished
        }

        function exec(cmd, onNewDataCallback) {
            if (onNewDataCallback !== undefined){
                callbacks[cmd] = onNewDataCallback
            }
            connectSource(cmd)
        }
        signal exited(string sourceName, string stdout)
    }
    
    Logic {
        id: kRun
        
        function launch(desktopFile) {
            openUrl('file:' + desktopFile)
        }
    }

    Binding {
        target: plasmoid
        property: "icon"
        value: kuser.faceIconUrl
        // revert to the plasmoid icon if no face given
        when: kuser.faceIconUrl.toString() !== ""
        restoreMode: Binding.RestoreBinding
    }

    KCoreAddons.KUser {
        id: kuser
    }

    Plasmoid.compactRepresentation: MouseArea {
        id: compactRoot

        // Taken from DigitalClock to ensure uniform sizing when next to each other
        readonly property bool tooSmall: plasmoid.formFactor === PlasmaCore.Types.Horizontal && Math.round(2 * (compactRoot.height / 5)) <= PlasmaCore.Theme.smallestFont.pixelSize

        Layout.minimumWidth: isVertical ? 0 : compactRow.implicitWidth
        Layout.maximumWidth: isVertical ? Infinity : Layout.minimumWidth
        Layout.preferredWidth: isVertical ? undefined : Layout.minimumWidth

        Layout.minimumHeight: isVertical ? label.height : PlasmaCore.Theme.smallestFont.pixelSize
        Layout.maximumHeight: isVertical ? Layout.minimumHeight : Infinity
        Layout.preferredHeight: isVertical ? Layout.minimumHeight : PlasmaCore.Theme.mSize(PlasmaCore.Theme.defaultFont).height * 2

        onClicked: plasmoid.expanded = !plasmoid.expanded

        Row {
            id: compactRow
            layoutDirection: iconPositionRight ? Qt.RightToLeft : Qt.LeftToRight
            anchors.centerIn: parent
            spacing: PlasmaCore.Units.smallSpacing

            Kirigami.Avatar {
                id: icon
                width: compactRoot.height
                height: compactRoot.height
                source: visible ? (kuser.faceIconUrl || "user-identity") : ""
                visible: root.showFace
            }

            PlasmaCore.IconItem {
                id: icon2
                width: height
                height: compactRoot.height
                Layout.preferredWidth: height
                source: visible ? (iconSett || "avatar-default-symbolic") : ""
                visible: root.showSett
            }

            PlasmaComponents3.Label {
                id: label
                text: root.displayedName
                height: compactRoot.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
                fontSizeMode: Text.VerticalFit
                font.pixelSize: tooSmall ? PlasmaCore.Theme.defaultFont.pixelSize : PlasmaCore.Units.roundToIconSize(PlasmaCore.Units.gridUnit * 2)
                minimumPointSize: PlasmaCore.Theme.smallestFont.pointSize
                visible: root.showName
            }
        }
    }

    PlasmaCore.DataSource {
        id: exe
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }

    function action_reBoot() {
        exe.exec('qdbus org.kde.ksmserver /KSMServer logout 1 1 2')
    }

    function action_susPend() {
         exe.exec('qdbus org.kde.Solid.PowerManagement /org/freedesktop/PowerManagement Suspend')
    }

    function action_logOut() {
        exe.exec('qdbus org.kde.ksmserver /KSMServer logout 1 3 3')
    }

    Plasmoid.fullRepresentation: Item {
        id: fullRoot

        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 15
        Layout.preferredHeight: Math.min(Screen.height * 0.5, column.contentHeight)

        readonly property double iwSize: units.gridUnit * 15 // item width
        readonly property double shSize: 1 // separator height

        // config var
        readonly property string aboutThisComputerCMD: plasmoid.configuration.aboutThisComputerSettings
        readonly property string ubuntuHelpCMD: plasmoid.configuration.ubuntuHelpSettings

        PlasmaCore.DataSource {
            id: pmEngine
            engine: "powermanagement"
            connectedSources: ["PowerDevil", "Sleep States"]

            function performOperation(what) {
                var service = serviceForSource("PowerDevil")
                var operation = service.operationDescription(what)
                service.startOperationCall(operation)
            }
        }

        Sessions.SessionsModel {
            id: sessionsModel
        }

        Connections {
            target: plasmoid
            function onExpandedChanged(expanded) {
                if (expanded) {
                    sessionsModel.reload()
                }
            }
        }

        PlasmaComponents.Highlight {
            id: delegateHighlight
            visible: false
            z: -1 // otherwise it shows ontop of the icon/label and tints them slightly
        }

        ColumnLayout {
            id: column

            // there doesn't seem a more sensible way of getting this due to the expanding ListView
            readonly property int contentHeight: appColumn.childrenRect.height + 5*s1.height + currentUserItem.height + userList.contentHeight
                                               + (lockScreenButton.visible ? lockScreenButton.height : 0)
                                               + suspendButton.height + leaveButton.height + aboutThisComputerItem.height + ubuntuHelpItem.height + shutdownButton.height + restartButton.height

            anchors.fill: parent

            spacing: 0

            ListDelegate {
                id: aboutThisComputerItem
                highlight: delegateHighlight
                text: i18n("About This Computer")
                onClicked: {
                    executable.exec(aboutThisComputerCMD); // cmd exec
                }
            }

            ListDelegate {
                id: ubuntuHelpItem
                highlight: delegateHighlight
                text: i18n("Ubuntu Help...")
                onClicked: executable.exec(ubuntuHelpCMD)
            }

            MenuSeparator {
                id: s1
                padding: 0
                topPadding: 5
                bottomPadding: 5
                //leftPadding: 3
                contentItem: Rectangle {
                    implicitWidth: iwSize
                    implicitHeight: shSize
                    color: PlasmaCore.Theme.neutralTextColor
                }
            }

            ColumnLayout {
                id: appColumn
                Repeater {
                    model: apps.model
                    
                    ListDelegate {
                        text: model.name
                        //icon: model.iconName
                        highlight: delegateHighlight
                        onClicked: kRun.launch(model.entryPath)
                    }
                }
            }

            MenuSeparator {
                id: s2
                padding: 0
                topPadding: 5
                bottomPadding: 5
                //leftPadding: 3
                contentItem: Rectangle {
                    implicitWidth: iwSize
                    implicitHeight: shSize
                    color: PlasmaCore.Theme.neutralTextColor
                }
            }

            ListDelegate {
                id: lockScreenButton
                text: i18ndc(userSwitcherDomain, "@action", "Lock")
                PlasmaComponents.Label {
                    text: "Ctrl+Alt+L "
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.75
                }
                //icon: "system-lock-screen"
                highlight: delegateHighlight
                enabled: pmEngine.data["Sleep States"]["LockScreen"]
                visible: enabled
                onClicked: pmEngine.performOperation("lockScreen")
            }

            MenuSeparator {
                id: s3
                padding: 0
                topPadding: 5
                bottomPadding: 5
                //leftPadding: 3
                contentItem: Rectangle {
                    implicitWidth: iwSize
                    implicitHeight: shSize
                    color: PlasmaCore.Theme.neutralTextColor
                }
            }

            ListDelegate {
                id: currentUserItem
                text: root.displayedName
                subText: i18nd(userSwitcherDomain, "Current user")
                icon: "user-identity"
                interactive: false
                interactiveIcon: KCMShell.authorize("kcm_users.desktop").length > 0
                onIconClicked: KCMShell.openSystemSettings("kcm_users")
            }

            PlasmaExtras.ScrollArea {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: userList
                    model: sessionsModel

                    highlight: PlasmaComponents.Highlight {}
                    highlightMoveDuration: 0

                    delegate: ListDelegate {
                        width: userList.width
                        text: {
                            if (!model.session) {
                                return i18ndc(userSwitcherDomain, "Nobody logged in on that session", "Unused")
                            }

                            if (model.realName && root.showFullName) {
                                return model.realName
                            }

                            return model.name
                        }
                        icon: "user-identity"
                        subText: {
                            if (!root.showTechnicalInfo) {
                                return ""
                            }

                            if (model.isTty) {
                                return i18ndc(userSwitcherDomain, "User logged in on console number", "TTY %1", model.vtNumber)
                            } else if (model.displayNumber) {
                                return i18ndc(userSwitcherDomain, "User logged in on console (X display number)", "on %1 (%2)", model.vtNumber, model.displayNumber)
                            }
                            return ""
                        }

                        onClicked: sessionsModel.switchUser(model.vtNumber, sessionsModel.shouldLock)
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                userList.currentIndex = index
                            } else {
                                userList.currentIndex = -1
                            }
                        }
                    }
                }
            }

            MenuSeparator {
                id: s4
                padding: 0
                topPadding: 5
                bottomPadding: 5
                //leftPadding: 3
                contentItem: Rectangle {
                    implicitWidth: iwSize
                    implicitHeight: shSize
                    color: PlasmaCore.Theme.neutralTextColor
                }
            }

            ListDelegate {
                id: leaveButton
                text: i18ndc(userSwitcherDomain, "Show a dialog with options to logout/shutdown/restart", "Log Out...")
                highlight: delegateHighlight
                //icon: "system-log-out"
                onClicked: action_logOut()
            }

            MenuSeparator {
                id: s5
                padding: 0
                topPadding: 5
                bottomPadding: 5
                //leftPadding: 3
                //anchors.centerIn: parent
                contentItem: Rectangle {
                    implicitWidth: iwSize
                    implicitHeight: shSize
                    color: PlasmaCore.Theme.neutralTextColor
                }
            }

            ListDelegate {
                id: suspendButton
                text: i18ndc(lookAndFeelDomain, "Suspend to RAM", "Suspend")
                highlight: delegateHighlight
                //icon: "system-suspend"
                onClicked: action_susPend()
            }

            ListDelegate {
                id: restartButton
                text: i18ndc(userSwitcherDomain, "Show a dialog with options to logout/shutdown/restart", "Restart")
                highlight: delegateHighlight
                //icon: "system-log-out"
                onClicked: action_reBoot()
            }

            ListDelegate {
                id: shutdownButton
                text: i18ndc(userSwitcherDomain, "Show a dialog with options to logout/shutdown/restart", "Shut Down...")
                highlight: delegateHighlight
                //icon: "system-log-out"
                onClicked: pmEngine.performOperation("requestShutDown")
            }
        }
    }
}
