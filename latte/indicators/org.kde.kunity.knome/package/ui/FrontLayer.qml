/*
*  Copyright 2019  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: frontLayer
    anchors.fill: parent

    Grid {
        id: lowerIndicators
        rows: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 1 : Math.min(4, indicator.windowsCount)
        columns: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? Math.min(4, indicator.windowsCount) : 1
        rowSpacing: 2
        columnSpacing: 2

        readonly property bool alwaysActive: false
        readonly property bool reversed: false

        Repeater {
            model: Math.min(4, indicator.windowsCount)
            delegate: indicator.configuration.style === 0 /*Triangles*/ ? circleComponent : circleComponent
        }
    }

    readonly property bool fillShapesBackground: {
        if (indicator.configuration.fillShapesForMinimized) {
            return true;
        }

        if (!parent.alwaysActive && indicator.windowsMinimizedCount!==0
                && ((index < maxDrawnMinimizedWindows)
                    || (indicator.windowsCount === indicator.windowsMinimizedCount))) {
            return false;
        }

        return true;
    }

    //! Triangle Indicator Component
    Component {
        id: circleComponent
        Rectangle {
            width: root.size
            height: root.size

            radius: 99
            color: "transparent"

            Rectangle{
                anchors.fill: parent
                anchors.margins: parent.border.width
                radius: parent.radius
                color: fillShapesBackground ? root.activeColor : root.backgroundColor
            }
        }
    }

    //! States
    states: [
        State {
            name: "bottom"
            when: (plasmoid.location === PlasmaCore.Types.BottomEdge)

            AnchorChanges {
                target: lowerIndicators
                anchors{ top:undefined; bottom:parent.bottom; left:undefined; right:undefined;
                    horizontalCenter:parent.horizontalCenter; verticalCenter:undefined}
            }
        },
        State {
            name: "top"
            when: (plasmoid.location === PlasmaCore.Types.TopEdge)

            AnchorChanges {
                target: lowerIndicators
                anchors{ top:parent.top; bottom:undefined; left:undefined; right:undefined;
                    horizontalCenter:parent.horizontalCenter; verticalCenter:undefined}
            }
        },
        State {
            name: "left"
            when: (plasmoid.location === PlasmaCore.Types.LeftEdge)

            AnchorChanges {
                target: lowerIndicators
                anchors{ top:undefined; bottom:undefined; left:parent.left; right:undefined;
                    horizontalCenter:undefined; verticalCenter:parent.verticalCenter}
            }
        },
        State {
            name: "right"
            when: (plasmoid.location === PlasmaCore.Types.RightEdge)

            AnchorChanges {
                target: lowerIndicators
                anchors{ top:undefined; bottom:undefined; left:undefined; right:parent.right;
                    horizontalCenter:undefined; verticalCenter:parent.verticalCenter}
            }
        }
    ]
}
