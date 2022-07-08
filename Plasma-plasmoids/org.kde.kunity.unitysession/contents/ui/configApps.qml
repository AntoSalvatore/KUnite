import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.core 2.0 as PlasmaCore

ColumnLayout {
    property string cfg_appList
    property var userApps: new Map(JSON.parse(plasmoid.configuration.appList))
    property ListModel appsModel: ListModel {}
    property ListModel userAppsModel: ListModel {
        onDataChanged: saveApps()
        onCountChanged: saveApps()
        onRowsMoved: saveApps()
    }
    
    PlasmaCore.DataSource {
        id: appSource
        engine: "apps"
        connectedSources: sources
        property var getUserApps: () => Array.from(userApps.entries())
                .map(([k,v]) => Object.assign({}, data[k], v))
        property var getAllApps: () => data.keys()
                .map(i => data[i])
                .filter(i => i.display && i.isApp)
                .sort((a,b) => a.name.localeCompare(b.name))

        Component.onCompleted: {
            appsModel.append(getAllApps())
            userAppsModel.append(getUserApps())
        }
    }
    
    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        id: userAppList
        clip: true
        model: userAppsModel
        delegate: appListItem
        ScrollBar.vertical: ScrollBar {
            active: true
        }
    }

    Component {
        id: appListItem
        ItemDelegate {
            width: ListView.view.width
            contentItem: RowLayout {
                ConfigIcon {
                    value: model.iconName
                    onValueChanged: model.iconName = value
                }
                Label {
                    text: model.name
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                ToolButton {
                    icon.name: 'arrow-up'
                    enabled: index > 0
                    onClicked: userAppList.model.move(index, index - 1, 1)
                }
                ToolButton {
                    icon.name: 'arrow-down'
                    enabled: index > -1 && index < userAppList.model.count - 1
                    onClicked: userAppList.model.move(index, index + 1, 1)
                }
                ToolButton {
                    icon.name: 'delete'
                    onClicked: userAppList.model.remove(index)
                }
            }
        }
    }

    RowLayout {
        ComboBox {
            id: appSelector
            Layout.fillWidth: true
            editable: true
            textRole: "name"
            model: appsModel
            onAccepted: {
                if (find(currentText) !== -1) {
                    userAppsModel.append(model.get(currentIndex))
                    currentIndex = -1
                } 
            }
        }
        Button {
            icon.name: "list-add"
            onClicked: appSelector.accepted()
        }
    }

    function saveApps() {
        const newAppConfig = new Map()
        for(let i = 0; i < userAppsModel.count; i++) {
            const app = userAppsModel.get(i)
            newAppConfig.set(app.menuId, { iconName: app.iconName })
        }
        cfg_appList = JSON.stringify(Array.from(newAppConfig.entries()));        
    }
}
