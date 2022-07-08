/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.components 1.0 as LatteComponents

LatteComponents.IndicatorItem{
    id: root

    backgroundCornerMargin: indicator && indicator.configuration ? indicator.configuration.backgroundCornerMargin : 0.50
    minLengthPadding: 0.04

    enabledForApplets: true

    providesInAttentionAnimation: true
    providesTaskLauncherAnimation: true
    providesClickedAnimation: true
    providesHoveredAnimation: true
    providesGroupedWindowAddedAnimation: true
    providesGroupedWindowRemovedAnimation: true

    readonly property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property real factor: indicator.configuration.size
    readonly property int size: factor * indicator.currentIconSize
    readonly property int thickLocalMargin: indicator.configuration.thickMargin * indicator.currentIconSize

    readonly property int screenEdgeMargin: indicator.screenEdgeMargin

    readonly property int thicknessMargin: screenEdgeMargin + thickLocalMargin


    readonly property real opacityStep: {
        if (indicator.configuration.maxBackgroundOpacity >= 0.3) {
            return 0.1;
        }

        return 0.05;
    }

    readonly property real backgroundOpacity: {
        if (indicator.isHovered && indicator.hasActive || (indicator.isWindow &&
                    indicator.configuration.backgroundAlwaysActive && indicator.isHovered)) {
            return indicator.configuration.maxBackgroundOpacity;
        } else if (indicator.hasActive || (indicator.isWindow && indicator.configuration.backgroundAlwaysActive)) {
            return indicator.configuration.maxBackgroundOpacity - opacityStep;
        } else if (indicator.isHovered) {
            return indicator.configuration.maxBackgroundOpacity - 2*opacityStep;
        }

        return 0;
    }

    readonly property real bgScale: {
        if (indicator.isHovered || indicator.hasActive || (indicator.isWindow &&
                    indicator.configuration.backgroundAlwaysActive))
            return 1;

        return 0.85;
    }

    property real scale: {
        if (indicator.isPressed)
            return 0.8;

        return 1;
    }


    /*Rectangle{
        anchors.fill: parent
        border.width: 1
        border.color: "blue"
        color: "transparent"
    }*/

    Binding{
        target: level.requested
        property: "isTaskLauncherAnimationRunning" //this is needed in order to inform latte when the animation has ended
        when: level && level.requested && level.requested.hasOwnProperty("isTaskLauncherAnimationRunning")
        value: launcherAnimationScale.running && launcherAnimationOpacity.running
    }

    Binding{
        target: level.requested
        property: "isInAttentionAnimationRunning"
        when: level && level.requested && level.requested.hasOwnProperty("isInAttentionAnimationRunning")
        value: inAttentionAnimationDance.running
    }

    Binding{
        target: root
        property: "lengthPadding"
        when: root.hasOwnProperty("lengthPadding")
        value: indicator.configuration.lengthPadding
    }

    /*LatteComponents.GlowPoint{
        id: dot
        width: root.size
        height: root.size
        opacity: {
            if (indicator.isEmptySpace) {
                return 0;
            }

            if (indicator.isTask) {
                return ((indicator.isLauncher || indicator.inRemoving) ? 0 : 1)
            }

            if (indicator.isApplet) {
                return (0)
            }
        }

        basicColor: indicator.palette.buttonFocusColor
        contrastColor: indicator.shadowColor

        size: root.size
        glow3D: true
        animation: Math.max(1.65*3*LatteCore.Environment.longDuration,indicator.durationTime*3*LatteCore.Environment.longDuration)
        location: plasmoid.location
        attentionColor: indicator.palette.negativeTextColor
        roundCorners: true
        showAttention: indicator.inAttention
        showGlow: false
        showBorder: true
    }*/

    //! Animations - Connections
    Connections {
        target: level
        enabled: indicator.animationsEnabled && indicator.isLauncher && level.isBackground
        onTaskLauncherActivated: {
            if (!launcherAnimationScale.running) {
                launcherAnimationScale.loops = 1;
                launcherAnimationScale.start();
                launcherAnimationOpacity.loops = 1;
                launcherAnimationOpacity.start();
            }
        }
    }

    Connections {
        target: indicator
        enabled: indicator && indicator.isApplet
        onIsActiveChanged: {
            if (indicator.isApplet && !launcherAnimationScale.running) {
                launcherAnimationScale.loops = 0;
                launcherAnimationScale.start();
                launcherAnimationOpacity.loops = 0;
                launcherAnimationOpacity.start();
            }
        }
    }

    Connections {
        target: indicator
        enabled: indicator
        onInAttentionChanged: {
            if (indicator.inAttention) {
                inAttentionAnimationDance.loops = Infinity;
                inAttentionAnimationDance.start();
            } else {
                inAttentionAnimationDance.stop();
                inAttentionAnimationDance.loops = 1;
            }
        }
    }

    Connections {
        target: level
        enabled: indicator.animationsEnabled && indicator.isTask && level.isBackground
        onTaskGroupedWindowAdded: {
            if (!windowAddedAnimation.running) {
                windowAddedAnimation.start();
            }
        }

        onTaskGroupedWindowRemoved: {
            if (!windowRemovedAnimation.running) {
                windowRemovedAnimation.start();
            }
        }
    }

    //! Animations
    SequentialAnimation {
        id: launcherAnimationScale
        alwaysRunToEnd: true

        readonly property int animationStep: 200

        ScriptAction {
            script: {
                if (level) {
                    if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                        level.requested.iconTransformOrigin = Item.Top;
                    } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                            level.requested.iconTransformOrigin = Item.Left;
                    } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                            level.requested.iconTransformOrigin = Item.Right;
                    } else {
                        level.requested.iconTransformOrigin = Item.Bottom;
                    }
                }
            }
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconScale"
            to: 2.5
            duration: indicator.durationTime * launcherAnimationScale.animationStep
            easing.type: Easing.OutExpo
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconScale"
            to: 1
            duration:  0
            easing.type: Easing.OutExpo
        }

        ScriptAction {
            script: {
                if (level) {
                    level.requested.iconTransformOrigin = Item.Center;
                }
            }
        }
    }

    //! Animations
    SequentialAnimation {
        id: launcherAnimationOpacity
        alwaysRunToEnd: true

        readonly property int animationStep: 200

        ScriptAction {
            script: {
                if (level) {
                    if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                        level.requested.iconTransformOrigin = Item.Top;
                    } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                            level.requested.iconTransformOrigin = Item.Left;
                    } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                            level.requested.iconTransformOrigin = Item.Right;
                    } else {
                        level.requested.iconTransformOrigin = Item.Bottom;
                    }
                }
            }
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconOpacity"
            to: 0
            duration: indicator.durationTime * launcherAnimationOpacity.animationStep
            easing.type: Easing.OutCirc
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconOpacity"
            to: 1
            duration:  0
            easing.type: Easing.OutCirc
        }

        ScriptAction {
            script: {
                if (level) {
                    level.requested.iconTransformOrigin = Item.Center;
                }
            }
        }
    }

    //! Animation - Attention
    SequentialAnimation {
        id: inAttentionAnimationDance
        alwaysRunToEnd: true

        readonly property int animationStep: 300

        ScriptAction {
            script: {
                if (level) {
                    if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                        level.requested.iconTransformOrigin = Item.Center;
                    } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                            level.requested.iconTransformOrigin = Item.Center;
                    } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                            level.requested.iconTransformOrigin = Item.Center;
                    } else {
                        level.requested.iconTransformOrigin = Item.Center;
                    }
                }
            }
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconRotation"
            to: 14
            duration: inAttentionAnimationDance.animationStep
            easing.type: Easing.OutQuint
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconRotation"
            to: -14
            duration: inAttentionAnimationDance.animationStep
            easing.type: Easing.OutQuint
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconRotation"
            to: 14
            duration: inAttentionAnimationDance.animationStep
            easing.type: Easing.OutQuint
        }

        PropertyAnimation {
            target: level ? level.requested : null
            property: "iconRotation"
            to: 0
            duration: inAttentionAnimationDance.animationStep
            easing.type: Easing.OutQuint
        }

        ScriptAction {
            script: {
                if (level) {
                    level.requested.iconTransformOrigin = Item.Center;
                }
            }
        }
    }

    SequentialAnimation {
        id: windowAddedAnimation
        alwaysRunToEnd: true
        readonly property string toproperty: !root.vertical ? "iconOffsetY" : "iconOffsetX"

        PropertyAnimation {
            target: level ? level.requested : null
            property: windowAddedAnimation.toproperty
            to: 0
            duration: 0
            easing.type: Easing.OutBounce
        }
    }

    SequentialAnimation {
        id: windowRemovedAnimation
        alwaysRunToEnd: true
        readonly property string toproperty: !root.vertical ? "iconOffsetX" : "iconOffsetY"

        PropertyAnimation {
            target: level ? level.requested : null
            property: windowRemovedAnimation.toproperty
            to: 0
            duration: 0
            easing.type: Easing.OutInElastic
        }
    }

    //! States
    states: [
        State {
            name: "left"
            when: plasmoid.location === PlasmaCore.Types.LeftEdge

            AnchorChanges {
                target: dot
                anchors{ verticalCenter:parent.verticalCenter; horizontalCenter:undefined;
                    top:undefined; bottom:undefined; left:parent.left; right:undefined;}
            }
            PropertyChanges{
                target: dot
                anchors.leftMargin: root.thicknessMargin;    anchors.rightMargin: 0;     anchors.topMargin:0;    anchors.bottomMargin:0;
                anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "bottom"
            when: (plasmoid.location === PlasmaCore.Types.Floating || plasmoid.location === PlasmaCore.Types.BottomEdge )

            AnchorChanges {
                target: dot
                anchors{ verticalCenter:undefined; horizontalCenter:parent.horizontalCenter;
                    top:undefined; bottom:parent.bottom; left:undefined; right:undefined;}
            }
            PropertyChanges{
                target: dot
                anchors.leftMargin: 0;    anchors.rightMargin: 0;     anchors.topMargin:0;    anchors.bottomMargin: root.thicknessMargin;
                anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "top"
            when: plasmoid.location === PlasmaCore.Types.TopEdge

            AnchorChanges {
                target: dot
                anchors{ verticalCenter:undefined; horizontalCenter:parent.horizontalCenter;
                    top:parent.top; bottom:undefined; left:undefined; right:undefined;}
            }
            PropertyChanges{
                target: dot
                anchors.leftMargin: 0;    anchors.rightMargin: 0;     anchors.topMargin: root.thicknessMargin;    anchors.bottomMargin:0;
                anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "right"
            when: plasmoid.location === PlasmaCore.Types.RightEdge

            AnchorChanges {
                target: dot
                anchors{ verticalCenter:parent.verticalCenter; horizontalCenter:undefined;
                    top:undefined; bottom:undefined; left:undefined; right:parent.right;}
            }
            PropertyChanges{
                target: dot
                anchors.leftMargin: 0;    anchors.rightMargin: root.thicknessMargin;     anchors.topMargin:0;    anchors.bottomMargin:0;
                anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: 0;
            }
        }
    ]

    //! Background Layer
    Item {
        id: floater
        anchors.fill: parent
        anchors.topMargin: plasmoid.location === PlasmaCore.Types.TopEdge ? root.screenEdgeMargin : 0
        anchors.bottomMargin: plasmoid.location === PlasmaCore.Types.BottomEdge ? root.screenEdgeMargin : 0
        anchors.leftMargin: plasmoid.location === PlasmaCore.Types.LeftEdge ? root.screenEdgeMargin : 0
        anchors.rightMargin: plasmoid.location === PlasmaCore.Types.RightEdge ? root.screenEdgeMargin : 0

        Loader{
            id: backLayer
            anchors.fill: parent

            // Make this configurable
            active: level.isBackground && !indicator.inRemoving

            sourceComponent: BackLayer{
                anchors.fill: parent
            }
        }

        Loader{
            id: frontLayer
            anchors.fill: parent

            active: (level.isForeground && indicator.configuration.shapesAtForeground)
                    || !indicator.configuration.shapesAtForeground

            sourceComponent:FrontLayer{
                anchors.fill: parent
            }
        }
    }

}// number of windows indicator

