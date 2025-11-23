/* CustomMenuBar.qml */

import QtQuick.Controls
import MyRobot 1.0

MenuBar {

    signal connectClicked()
    signal disconnectClicked()

    Menu {
        width: 80
        title: qsTr("连接设置")
        MenuItem {
            text: qsTr("重新连接")
            onTriggered: {
                connectClicked()
            }
        }
        MenuItem {
            text: qsTr("断开连接")
            onTriggered: {
                disconnectClicked()
            }
        }
    }
    Menu {
        width: 80
        title: qsTr("设置")
        Menu {
            width: 120
            title: qsTr("语言")
            MenuItem { text: qsTr("中文") }
            MenuItem { text: qsTr("英语") }
        }
    }
    Menu {
        width: 80
        title: "帮助"
        MenuItem {
            text: "关于"
            onTriggered: {
            }
        }
    }
}
