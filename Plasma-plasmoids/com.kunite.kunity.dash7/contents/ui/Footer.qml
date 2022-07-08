import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0

import org.kde.kwindowsystem 1.0
import QtGraphicalEffects 1.0
import org.kde.kquickcontrolsaddons 2.0

import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.private.quicklaunch 1.0



RowLayout{

    spacing: units.largeSpacing

    Logic {   id: logic }

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

    Item{
        Layout.fillWidth: true
    }

    PlasmaComponents3.ToolButton {
        icon.name:  "user-home"
        onClicked: logic.openUrl("file:///usr/share/applications/org.kde.dolphin.desktop")
        ToolTip.delay: 1000
        ToolTip.timeout: 1000
        ToolTip.visible: hovered
        ToolTip.text: i18n("User Home")
    }

    PlasmaComponents3.ToolButton {
        icon.name:  "configure"
        onClicked: logic.openUrl("file:///usr/share/applications/systemsettings.desktop")
        ToolTip.delay: 1000
        ToolTip.timeout: 1000
        ToolTip.visible: hovered
        ToolTip.text: i18n("System Preferences")
    }

    PlasmaComponents3.ToolButton {
        icon.name:   "system-lock-screen"
        onClicked: pmEngine.performOperation("lockScreen")
        ToolTip.delay: 1000
        ToolTip.timeout: 1000
        ToolTip.visible: hovered
        ToolTip.text: i18n("Lock Screen")
        visible: pmEngine.data["Sleep States"]["LockScreen"]
    }

    PlasmaComponents3.ToolButton {
        icon.name:  "system-shutdown"
        onClicked: pmEngine.performOperation("requestShutDown")

        ToolTip.delay: 1000
        ToolTip.timeout: 1000
        ToolTip.visible: hovered
        ToolTip.text: i18n("Leave ...")
    }

    Item{
        Layout.fillWidth: true
    }
}
