/*
 *    Copyright 2014  Sebastian Kügler <sebas@kde.org>
 *    SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *    Copyright (C) 2021 by Mikel Johnson <mikel5764@gmail.com>
 *    Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License along
 *    with this program; if not, write to the Free Software Foundation, Inc.,
 *    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.plasma.private.quicklaunch 1.0

Control {
    id: footer
    rightPadding: rightInset
    leftPadding: rightPadding
    property Item configureButton: configureButton
    property int iconSize: units.iconSizes.smallMedium
    property var footerNames: ["Documents", "Pictures", "Music", "Downloads", "Videos", "File manager", "System settings", "Lock screen", "Power options"]
    property var footerIcons: ["folder-documents-symbolic", "folder-pictures-symbolic", "folder-music-symbolic", "folder-download-symbolic", "folder-videos-symbolic", plasmoid.configuration.replaceExplorerIcon ? Qt.resolvedUrl((theme.textColor.r * 0.299 + theme.textColor.g * 0.587 + theme.textColor.b * 0.114) > 0.7265625 ? "icons/explorer.svg" : "icons/explorer_dark.svg") : "folder-symbolic", "configure", "system-lock-screen", "system-shutdown"]

    background: Rectangle {
        color: Qt.darker(theme.backgroundColor)
        opacity: .115
        border.width: 1
        border.color: "#cacbd0"
        radius: 5
    }

    Logic { id: logic }
    anchors.bottomMargin: units.largeSpacing * 1.8
    anchors.topMargin: anchors.bottomMargin
    height: units.iconSizes.medium * 1.5

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

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    RowLayout {
        anchors.rightMargin: units.largeSpacing * 3 - footer.rightPadding - footer.anchors.leftMargin
        anchors.right: parent.right
        x: -units.smallSpacing
        anchors.verticalCenter: parent.verticalCenter

        // looks visually balanced that way
        spacing: Math.round(PlasmaCore.Units.smallSpacing * 2.5)

        Repeater {
            model: 9
            PlasmaComponents.TabButton {
                id: newTabButton
                visible: [
                    plasmoid.configuration.downIconsDocuments,
                    plasmoid.configuration.downIconsPictures,
                    plasmoid.configuration.downIconsMusic,
                    plasmoid.configuration.downIconsDownloads,
                    plasmoid.configuration.downIconsVideos,
                    plasmoid.configuration.downIconsFileManager,
                    plasmoid.configuration.downIconsSystemSettings,
                    plasmoid.configuration.downIconsLock,
                    plasmoid.configuration.downIconsPowerOptions
                ][index]
                // flat: true
                NumberAnimation {
                    id: animateOpacity
                    target: newTabButton
                    properties: "opacity"
                    from: 1
                    to: 0.5
                    duration: PlasmaCore.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    id: animateOpacityReverse
                    target: newTabButton
                    properties: "opacity"
                    from: 0.5
                    to: 1
                    duration: PlasmaCore.Units.longDuration
                    easing.type: Easing.InOutQuad
                }

                icon {
                    name: footerIcons[index]
                    width: iconSize * (plasmoid.configuration.reduceIconSizeFooter ? 0.97 : 1)
                }
                onHoveredChanged: hovered ? animateOpacity.start() : animateOpacityReverse.start();
                PlasmaComponents.ToolTip {
                    text: i18n(footerNames[index])
                }
                MouseArea {
                    onClicked: index < 6 ? executable.exec("xdg-open $(xdg-user-dir" + (index < 5 ? (" " + footerNames[index].toUpperCase()) : "") + ")") : index == 6 ? logic.openUrl("file:///usr/share/applications/systemsettings.desktop") : pmEngine.performOperation(index == 8 ? "requestShutDown" : "lockScreen")
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }
}
