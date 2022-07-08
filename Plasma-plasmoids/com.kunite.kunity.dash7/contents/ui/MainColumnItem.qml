/***************************************************************************
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>           *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/


import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

import QtQuick 2.12
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.components 2.0 as PlasmaComponents2
import QtQuick.Layouts 1.12
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kwindowsystem 1.0
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons

import "../code/tools.js" as Tools

Item {
    id: item

    width: (tileSideWidth *  plasmoid.configuration.numberColumns) + _margin * 3
    height: (tileSideHeight *  plasmoid.configuration.numberRows) + _margin * 5
    y: units.largeSpacing
    property int iconSize: units.iconSizes.large
    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
        + (2 * units.smallSpacing)
        + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
            highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property bool searching: (searchField.text != "")
    property bool showAllApps: plasmoid.configuration.defaultAllApps
    property bool showRecents: false
    property int tileSide: cellSize * 1.08
    property int tileSideWidth: tileSideHeight + units.smallSpacing*2
    property int _margin: units.largeSpacing //* 0.5

    property int tileSideHeight: iconSize + theme.mSize(theme.defaultFont).height * 2
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onSearchingChanged: {
        if (!searching) {
            reset();
        } else {
            if (showRecents) resetPinned.start();
        }
    }
    signal  newTextQuery(string text)
    property real mainColumnHeight: tileSide * plasmoid.configuration.numberRows
    property real favoritesColumnHeight: tileSide * 0.6 * 3
    property var pinnedModel: [globalFavorites, rootModel.modelForRow(0), rootModel.modelForRow(1)]
    property var recommendedModel: [rootModel.modelForRow(1), rootModel.modelForRow(0), globalFavorites, globalFavorites]
    property var allAppsModel: [rootModel.modelForRow(2)]

    function updateModels() {
        item.pinnedModel = [globalFavorites, rootModel.modelForRow(0), rootModel.modelForRow(1)]
        item.recommendedModel = [rootModel.modelForRow(1), rootModel.modelForRow(0), globalFavorites, globalFavorites]
        item.allAppsModel = [rootModel.modelForRow(2)]
    }

    function reset() {
        if (showRecents) resetPinned.start();
        searchField.clear()
        searchField.focus = true
        showAllApps = plasmoid.configuration.defaultAllApps
        showRecents = false
        documentsFavoritesGrid.tryActivate(0, 0);
        allAppsGrid.tryActivate(0, 0);
        globalFavoritesGrid.tryActivate(0, 0);
    }

    function reload() {
        mainColumn.visible = false
        recentItem.visible = false
        pinnedModel = null
        recommendedModel = null
        allAppsModel = null
        preloadAllAppsTime.done = false
        preloadAllAppsTime.defer()
    }

    KWindowSystem {
        id: kwindowsystem
    }
    KCoreAddons.KUser { id: kuser }

    PlasmaExtras.Heading {
        id: dummyHeading

        visible: false
        width: 0
        level: 1
    }


    ParallelAnimation {
        id: removePinned
        running: false
        NumberAnimation { target: mainColumn; property: "height"; from: mainColumnHeight; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mainColumn; property: "opacity"; from: 1; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: documentsFavoritesGrid; property: "height"; from: favoritesColumnHeight; to: parent.height; duration: 500; easing.type: Easing.InOutQuad }
    }

    ParallelAnimation {
        id: restorePinned
        running: false
        NumberAnimation { target: mainColumn; property: "height"; from: 0; to: searching || showAllApps ? parent.height : mainColumnHeight; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mainColumn; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: documentsFavoritesGrid; property: "height"; from: parent.height; to: favoritesColumnHeight; duration: 500; easing.type: Easing.InOutQuad }
    }

    ParallelAnimation {
        id: resetPinned
        running: false
        NumberAnimation { target: mainColumn; property: "height"; from: 0; to: searching || showAllApps ? parent.height : mainColumnHeight; duration: 0; }
        NumberAnimation { target: mainColumn; property: "opacity"; from: 0; to: 1; duration: 0; }
        NumberAnimation { target: documentsFavoritesGrid; property: "height"; from: parent.height; to: favoritesColumnHeight; duration: 0; }
    }

    TextMetrics {
        id: headingMetrics
        font: dummyHeading.font
    }

    Timer {
        id: preloadAllAppsTime
        property bool done: false
        interval: 100
        repeat: false
        onTriggered: {
            if (done) {
                return;
            }
            item.updateModels()
            mainColumn.tryActivate(0, 0);
            done = true;
            mainColumn.visible = true
            recentItem.visible = true
        }

        function defer() {
            if (!running && !done) {
                restart();
            }
        }
    }

    Kicker.ContainmentInterface {
        id: containmentInterface
    }

    PlasmaComponents2.Menu {
        id: contextMenu
        PlasmaComponents2.MenuItem {
            action: plasmoid.action("configure")
        }
    }


    PlasmaComponents.TextField {
        id: searchField
        anchors.top: parent.top
        //anchors.margins: _margin
        //anchors.horizontalCenter: parent.horizontalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: units.largeSpacing * 1.3
        focus: true
        placeholderText: i18n("Search your computer...")
        placeholderTextColor: colorWithAlpha(theme.textColor,0.7)
        opacity: searching || plasmoid.configuration.alwaysShowSearchBar
        leftPadding: units.largeSpacing + units.iconSizes.small
        topPadding: units.gridUnit * 0.5
        verticalAlignment: Text.AlignTop
        implicitHeight: units.gridUnit * 2
        width: tileSideWidth * plasmoid.configuration.numberColumns
        x: 1.5 * units.largeSpacing
        Accessible.editable: true
        Accessible.searchEdit: true
        background: Rectangle {
            color: theme.backgroundColor
            radius: 6
            border.width: 1
            border.color: colorWithAlpha(theme.textColor,0.25)
        }

        onTextChanged: {
            runnerModel.query = text;
            newTextQuery(text)
        }

        PlasmaCore.IconItem {
            id: searchIconItem
            source: "search"
            height: units.iconSizes.small * 1.5
            width: height
            x: PlasmaCore.Units.iconSizes.small * 0.45
            anchors {
                left: searchField.left
                verticalCenter: searchField.verticalCenter
                leftMargin: units.smallSpacing
            }
        }

        function clear() {
            text = "";
        }
        function backspace() {
            if (searching) {
                text = text.slice(0, -1);
            }
            focus = true;
        }
        function appendText(newText) {
            if (!root.visible) {
                return;
            }
            focus = true;
            text = text + newText;
        }
        Keys.onPressed: {
            if (event.key == Qt.Key_Down) {
                event.accepted = true;
                mainColumn.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Up) {
                event.accepted = true;
                mainColumn.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if (searching) {
                    clear()
                } else {
                    root.toggle()
                }
            }
        }
    }

    PlasmaExtras.Heading {
        id: mainLabelGrid
        anchors.top: plasmoid.configuration.alwaysShowSearchBar ? searchField.bottom : parent.top
        anchors.leftMargin: units.largeSpacing * 3
        anchors.topMargin: plasmoid.configuration.alwaysShowSearchBar ? units.largeSpacing : _margin
        anchors.left: parent.left
        x: units.smallSpacing
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        color: theme.textColor
        level: 5
        font.bold: true
        font.weight: Font.Bold
        text: i18n(showAllApps ? "All apps" : showRecents ? "Recommended" : "Pinned")
        visible: !searching
    }

    PlasmaComponents.Button  {
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (showAllApps || !showRecents)
                    showAllApps = !showAllApps
                else {
                    showRecents = !showRecents
                    if (showRecents)
                        removePinned.start();
                    else
                        restorePinned.start();
                }
                mainColumn.visibleGrid.tryActivate(0, 0)
            }
        }
        text: i18n(showAllApps || showRecents ? "Back" : "All apps")
        id: mainsecLabelGrid
        icon.name: showAllApps || showRecents ? "go-previous" : "go-next"
        font.pointSize: 9
        icon.height: 15
        icon.width: 15
        LayoutMirroring.enabled: true
        LayoutMirroring.childrenInherit: !showAllApps && !showRecents
        flat: false
        background: Rectangle {
            color: Qt.lighter(theme.backgroundColor)
            border.width: 1
            border.color: Qt.darker(theme.backgroundColor, 1.14)
            radius: 5
        }
        topPadding: 4
        bottomPadding: topPadding
        leftPadding: 8
        rightPadding: 8
        icon{
            width: height
            height: visible ? units.iconSizes.small : 0
            name: showAllApps || showRecents ? "go-previous" : "go-next"
        }

        anchors {
            topMargin: units.smallSpacing
            verticalCenter: mainLabelGrid.verticalCenter
            rightMargin: units.largeSpacing * 3
            leftMargin: units.largeSpacing * 3
            left: parent.left
        }
        x: -units.smallSpacing
        visible: !searching
    }

    Item {
        id: mainColumn
        anchors {
            top: mainLabelGrid.bottom
            leftMargin: units.largeSpacing * 2
            rightMargin: units.largeSpacing
            topMargin: units.largeSpacing * 0.7
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            //bottomMargin: 5
        }
        height: searching || showAllApps || plasmoid.configuration.recentGridModel == 3 ? parent.height : mainColumnHeight
        property Item visibleGrid: globalFavoritesGrid
        function tryActivate(row, col) {
            if (visibleGrid) {
                visibleGrid.tryActivate(row, col);
            }
        }

        ItemGridView {
            id: globalFavoritesGrid
            model: pinnedModel[plasmoid.configuration.favGridModel]
            width: tileSideWidth *  plasmoid.configuration.numberColumns
            height: tileSideHeight *  plasmoid.configuration.numberRows
            cellWidth: tileSideWidth
            cellHeight: tileSideHeight
            square: true
            dropEnabled: true
            usesPlasmaTheme: true
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            opacity: searching || showAllApps ? 0 : 1
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = globalFavoritesGrid;
                }
            }
            onKeyNavDown: documentsFavoritesGrid.tryActivate(0, 0)

        }

        ItemMultiGridView {
            id: allAppsGrid
            //anchors.fill: parent
            anchors{
                left: parent.left
                right: parent.right
            }
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            height: globalFavoritesGrid.height + tileSideHeight + (root.iconSize + units.smallSpacing)
            //width: tileSideWidth * plasmoid.configuration.numberColumns
            aCellWidth: tileSideWidth
            aCellHeight: tileSideHeight
            grabFocus: true
            model: allAppsModel[0]
            opacity: showAllApps && !searching ? 1.0 : 0.0
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = allAppsGrid;
                }
            }
        }

        ItemMultiGridView {
            id: runnerGrid
            //anchors.fill: parent
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            height: globalFavoritesGrid.height + tileSideHeight + (root.iconSize + units.smallSpacing)
            width: tileSideWidth *  plasmoid.configuration.numberColumns
            aCellWidth: tileSideWidth
            aCellHeight: tileSideHeight
            model: runnerModel
            grabFocus: true
            opacity: searching ? 1.0 : 0.0
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = runnerGrid;
                }
            }
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                if (searching)
                    searchField.backspace();
                else
                    searchField.focus = true
            } else if (event.key == Qt.Key_Tab) {
                event.accepted = true;
                if (!searching && !showAllApps) documentsFavoritesGrid.tryActivate(0, 0);
            } else if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if (searching) {
                    searchField.clear()
                } else {
                    root.toggle()
                }
            } else if (event.text != "") {
                event.accepted = true;
                searchField.appendText(event.text);
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            onPressed: {
                if (mouse.button == Qt.RightButton) {
                    contextMenu.open(mouse.x, mouse.y);
                }
            }

            onClicked: {
                if (mouse.button == Qt.LeftButton) {
                }
            }
        }

    }

    Item{
        id: recentItem
        width: parent.width
        //height: globalFavoritesGrid.height
        anchors.top: mainColumn.bottom
        //anchors.topMargin: units.largeSpacing * 0.5
        anchors.left: mainColumn.left
        anchors.right: mainColumn.right
        //anchors.bottom: parent.bottom
        //anchors.leftMargin: units.largeSpacing * 1.6
        //anchors.rightMargin: units.largeSpacing
        //anchors.horizontalCenter: mainColumn.horizontalCenter
        visible: plasmoid.configuration.recentGridModel != 3

        //property int iconSize: 22

        PlasmaExtras.Heading {
            id: headLabelDocuments
            x: units.smallSpacing
            width: parent.width - x
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            color: theme.textColor
            level: 5
            font.bold: true
            font.weight: Font.Bold
            visible: !searching && !showAllApps && !showRecents
            text: i18n("Recommended")
        }

        ItemGridView {
            id: documentsFavoritesGrid
            visible: !searching && !showAllApps
            showDescriptions: true

            anchors{
                top: headLabelDocuments.bottom
                left: parent.left
                right: parent.right
                bottomMargin: 0
                topMargin: units.largeSpacing * 0.7
            }

            increaseLeftSpacings: true
            width: tileSideWidth
            height:  tileSideHeight
            cellWidth:   tileSideWidth
            cellHeight:  tileSideHeight
            iconSize: units.iconSizes.large
            model: recommendedModel[plasmoid.configuration.recentGridModel]
            usesPlasmaTheme: false
            square: false
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

            onKeyNavUp: {
                mainColumn.visibleGrid.tryActivate(0, 0);
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    mainColumn.visibleGrid.tryActivate(0, 0)
                } else if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    if (searching)
                        searchField.backspace();
                    else
                        searchField.focus = true
                } else if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if (searching) {
                        searchField.clear()
                    } else {
                        root.toggle()
                    }
                } else if (event.text != "") {
                    event.accepted = true;
                    searchField.appendText(event.text);
                }

            }
        }
    }

    Item {
        id: footerTransparent
        height: 22
        visible: !searching
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: recentItem.bottom
    }

    Component.onCompleted: {
        searchField.focus = true
    }
}

