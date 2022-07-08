/*
How the Win11 Indicator (the background part) seems to work
[Hover]
Outline/Border rect appears first
Inside/Filled rect appears very shortly afterwards
[Unhover]
Outline/Border rect disappears first
Inside/Filled rect shrinks to about 85-90% of its size while becoming invisible

I am unable to find a satisfying way to achieve the exact same effect
so my approximation will have to do for now
*/

import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item{
    id: rectangleItem

    property bool isActive: indicator.isActive || (indicator.isWindow && indicator.hasActive)
    
    anchors.centerIn: parent

    Rectangle {
        id: mainRect
        width: indicator.isTask || indicator.isSquare ? Math.min(parent.width, parent.height) : parent.width
        height: indicator.isTask || indicator.isSquare ? width : parent.height
        anchors.centerIn: parent
        radius: indicator.currentIconSize / 10
        // Since the steal focus/demand attention doesn't work in Wayland (at least for the moment), I will not
        // try to implement a color change since I can't test it (and I don't want to try X11 just for that)
        
        // Honestly I don't know which of these looks better, let alone which would be better for most themes
        color: root.colorStyle === 0 ? "white" : indicator.iconGlowColor
        // color: root.colorStyle === 0 ? Qt.lighter(indicator.palette.backgroundColor, 5) : indicator.iconGlowColor

        visible: opacity > 0
        opacity: root.backgroundOpacity

        Behavior on opacity {
            enabled: true
            NumberAnimation {
                duration: 100 * indicator.durationTime / indicator.configuration.animationSpeed
                easing.type: Easing.OutCirc
            }
        }
    }
    
    Rectangle {
        id: backRect
        width: mainRect.width
        height: mainRect.height
        anchors.centerIn: parent
        radius: mainRect.radius
        color: "transparent"
        visible: false
        border.width: 1
    }

    OpacityMask {
        id: borderMask
        width: mainRect.width
        height: mainRect.height
        anchors.centerIn: parent
        source: borderFill
        maskSource: backRect
        opacity: mainRect.opacity + 0.10
        visible: mainRect.visible
    }

    /*Loader{
            id: frontLayer
            anchors.fill: mainRect

            active: indicator.isWindow

            sourceComponent: FrontLayer{
                anchors.fill: mainRect
                showProgress: root.progressVisible
            }
        }*/
}
