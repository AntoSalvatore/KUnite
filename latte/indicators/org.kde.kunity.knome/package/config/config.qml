import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0

import org.kde.latte.components 1.0 as LatteComponents

ColumnLayout {
    Layout.fillWidth: true

    LatteComponents.SubHeader {
		text: i18n("Dot Indicator")
	}

	ColumnLayout {

		spacing: 0

		RowLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing

            PlasmaComponents.Label {
                text: i18n("Size")
                horizontalAlignment: Text.AlignLeft
            }

            LatteComponents.Slider {
                id: sizeSlider
                Layout.fillWidth: true

                value: Math.round(indicator.configuration.size * 100)
                from: 3
                to: 25
                stepSize: 1
                wheelEnabled: false

                onPressedChanged: {
                    if (!pressed) {
                        indicator.configuration.size = Number(value / 100).toFixed(2);
                    }
                }
            }

            PlasmaComponents.Label {
                text: i18nc("number in percentage, e.g. 85 %","%1 %", currentValue)
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: theme.mSize(theme.defaultFont).width * 4
                Layout.maximumWidth: theme.mSize(theme.defaultFont).width * 4

                readonly property int currentValue: sizeSlider.value
            }
        }
	}

    LatteComponents.SubHeader {
        text: i18n("Background Indicator")
    }

    ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing

            PlasmaComponents.Label {
                Layout.minimumWidth: implicitWidth
                horizontalAlignment: Text.AlignLeft
                Layout.rightMargin: units.smallSpacing
                text: i18n("Max Opacity")
            }

            LatteComponents.Slider {
                id: maxOpacitySlider
                Layout.fillWidth: true

                leftPadding: 0
                value: indicator.configuration.maxBackgroundOpacity * 100
                from: 10
                to: 100
                stepSize: 1
                wheelEnabled: false

                function updateMaxOpacity() {
                    if (!pressed) {
                        indicator.configuration.maxBackgroundOpacity = value/100;
                    }
                }

                onPressedChanged: {
                    updateMaxOpacity();
                }

                Component.onCompleted: {
                    valueChanged.connect(updateMaxOpacity);
                }

                Component.onDestruction: {
                    valueChanged.disconnect(updateMaxOpacity);
                }
            }

            PlasmaComponents.Label {
                text: i18nc("number in percentage, e.g. 85 %","%1 %", maxOpacitySlider.value)
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: theme.mSize(theme.defaultFont).width * 4
                Layout.maximumWidth: theme.mSize(theme.defaultFont).width * 4
            }
        }

        LatteComponents.CheckBox {
			Layout.maximumWidth: dialog.optionsWidth
			text: i18n("Always show background for open tasks/windows")
			checked: indicator.configuration.backgroundAlwaysActive

			onClicked: {
				indicator.configuration.backgroundAlwaysActive = !indicator.configuration.backgroundAlwaysActive;
			}
		}
    }


    LatteComponents.SubHeader {
        text: i18n("Misc Options")
    }

    RowLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing

            PlasmaComponents.Label {
                Layout.minimumWidth: implicitWidth
                horizontalAlignment: Text.AlignLeft
                Layout.rightMargin: units.smallSpacing
                text: i18n("Animation Speed")
            }

            LatteComponents.Slider {
                id: animSpeedSlider
                Layout.fillWidth: true

                leftPadding: 0
                value: indicator.configuration.animationSpeed * 100
                from: 10
                to: 200
                stepSize: 5
                wheelEnabled: false

                function updateAnimSpeed() {
                    if (!pressed) {
                        indicator.configuration.animationSpeed = value/100;
                    }
                }

                onPressedChanged: {
                    updateAnimSpeed();
                }

                Component.onCompleted: {
                    valueChanged.connect(updateAnimSpeed);
                }

                Component.onDestruction: {
                    valueChanged.disconnect(updateAnimSpeed);
                }
            }

            PlasmaComponents.Label {
                text: i18nc("number in percentage, e.g. 85 %","%1 %", animSpeedSlider.value)
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: theme.mSize(theme.defaultFont).width * 4
                Layout.maximumWidth: theme.mSize(theme.defaultFont).width * 4
            }
        }

    RowLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing
            visible: deprecatedPropertiesAreHidden

            PlasmaComponents.Label {
                text: i18n("Tasks Length")
                horizontalAlignment: Text.AlignLeft
            }

            LatteComponents.Slider {
                id: lengthIntMarginSlider
                Layout.fillWidth: true

                leftPadding: 0
                value: Math.round(indicator.configuration.lengthPadding * 100)
                from: 4
                to: maxMargin
                stepSize: 1
                wheelEnabled: false

                readonly property int maxMargin: 80

                onPressedChanged: {
                    if (!pressed) {
                        indicator.configuration.lengthPadding = value / 100;
                    }
                }
            }

            PlasmaComponents.Label {
                text: i18nc("number in percentage, e.g. 85 %","%1 %", currentValue)
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: theme.mSize(theme.defaultFont).width * 4
                Layout.maximumWidth: theme.mSize(theme.defaultFont).width * 4

                readonly property int currentValue: lengthIntMarginSlider.value
            }
        }

    LatteComponents.CheckBoxesColumn {
        Layout.fillWidth: true

        LatteComponents.CheckBox {
            Layout.maximumWidth: dialog.optionsWidth
            text: i18n("Progress animation in background")
            checked: indicator.configuration.progressAnimationEnabled

            onClicked: {
                indicator.configuration.progressAnimationEnabled = !indicator.configuration.progressAnimationEnabled
            }
        }
    }

    LatteComponents.CheckBox {
        Layout.maximumWidth: dialog.optionsWidth
        text: i18n("Show indicators for applets")
        checked: indicator.configuration.enabledForApplets
        tooltip: i18n("Indicators are shown for applets")
        visible: deprecatedPropertiesAreHidden

        onClicked: {
            indicator.configuration.enabledForApplets = !indicator.configuration.enabledForApplets;
        }
    }
}
