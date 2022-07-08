/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
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

import QtQuick 2.12
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int iconSize: units.iconSizes.large
    property int iconSizeSide: units.iconSizes.smallMedium
    property int _margin: iconSize > 33 ? units.largeSpacing  : units.largeSpacing * 0.5

    property int tileSideHeight: iconSize + theme.mSize(theme.defaultFont).height * 2
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int tileSideWidth: tileSideHeight + units.smallSpacing*2

    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
        + units.largeSpacing
        + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
            highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property int tileSide: cellSize * 1.08

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onVisibleChanged: {
        if (!visible) {
            reset();
        } else {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
        }
    }

    onHeightChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onWidthChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    function toggle() {
        root.visible = false;
    }

    function reset() {
        mainColumnItem.reset()
    }

    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x,
                             screenAvail.y + screenGeom.y,
                             screenAvail.width,
                             screenAvail.height);


        var offset = units.smallSpacing;

        // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
        var x = offset;
        var y = screen.height - height - offset;
        var appletTopLeft;
        var horizMidPoint;
        var vertMidPoint;


        if (plasmoid.configuration.displayPosition === 1) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            y = vertMidPoint - height / 2;
        } else if (plasmoid.configuration.displayPosition === 2) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            y = screen.y + screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.y + screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.y + parent.height + panelSvg.margins.bottom + offset;
        } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = parent.width + panelSvg.margins.right + offset;
            y = screen.y + (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width;
            y = screen.y + (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        }

        return Qt.point(x, y);
    }


    FocusScope {
        Layout.maximumWidth:  (tileSideWidth *  plasmoid.configuration.numberColumns) + _margin * 3
        Layout.minimumHeight: (tileSideHeight *  plasmoid.configuration.numberRows) + footer.height + (tileSideHeight *2) + _margin * 3
        Layout.minimumWidth:  (tileSideWidth *  plasmoid.configuration.numberColumns) + (22 + units.smallSpacing) + _margin * 3
        Layout.maximumHeight: Layout.minimumHeight

        focus: true

        Row{
            anchors.fill: parent

            MainColumnItem{
                id: mainColumnItem
            }
        }

        Rectangle{
            id: footer
            width: parent.width + backgroundSvg.margins.right + backgroundSvg.margins.left
            height: root.iconSize + units.smallSpacing // units.gridUnit * 3
            x: - backgroundSvg.margins.left
            y: parent.height - height + backgroundSvg.margins.bottom
            color: colorWithAlpha(theme.textColor,0.05)

            Footer{
                anchors.fill: parent
                anchors.leftMargin: _margin*2
                anchors.rightMargin: _margin*2
            }

            Rectangle{
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: theme.textColor
                opacity: 0.15
                z:2
            }

        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Escape) {
                root.visible = false;
            }
        }
    }

    function refreshModel() {
        mainColumnItem.reload()
        console.log("refresh model - menu 11")
    }

    Component.onCompleted: {
        rootModel.refreshed.connect(refreshModel)
        kicker.reset.connect(reset);
        reset();
    }
}
