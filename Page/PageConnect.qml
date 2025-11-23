import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Components"
import MyRobot 1.0 // 引入单例

Item {

    property string host: "192.168.1.136"
    property string port: "9001"

    // 布局内容
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: 300

        Label {
            text: "机器人连接配置"
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Text {
                text: qsTr("IP地址:")
                font.family: "Consolas"
                font.pointSize: 12
                font.bold: true
            }
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 40
                radius: 8
                border.color: ipField.activeFocus ? "#4CAF50" : "#cccccc"
                border.width: 2
                color: ipField.enabled ? "white" : "#f5f5f5"

                TextField {
                    id: ipField
                    anchors.fill: parent
                    font.family: "Consolas"
                    anchors.margins: 2
                    placeholderText: qsTr("请输入IP")
                    font.pointSize: 12
                    selectByMouse: true
                    background: null // 清除默认背景
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中

                     // 输入验证 - 只允许IP地址格式
                     validator: RegularExpressionValidator {
                         regularExpression: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
                    }

                    // 默认值
                    text: host
                }
            }
        }
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Text {
                text: qsTr("端口号:")
                font.family: "Consolas"
                font.pointSize: 12
                font.bold: true
            }
            // 端口输入框 - 使用Rectangle包装
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 40
                radius: 8
                border.color: portField.activeFocus ? "#4CAF50" : "#cccccc"
                border.width: 2
                color: portField.enabled ? "white" : "#f5f5f5"

                TextField {
                    id: portField
                    anchors.fill: parent
                    anchors.margins: 2
                    font.family: "Consolas"
                    placeholderText: qsTr("请输入端口号")
                    font.pointSize: 12
                    selectByMouse: true
                    background: null // 清除默认背景
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中

                    // 端口验证 (1-65535)
                    validator: IntValidator {
                        bottom: 1
                        top: 65535
                    }

                    // 默认值
                    text: port
                }
            }
        }
        CustomButton{
            buttonText: RobotGlobal.isConnected ? qsTr("断开连接") : qsTr("立即连接")
            fontSize: 18
            Layout.fillWidth: true
            onClicked: {
                if (RobotGlobal.isConnected) {
                    RobotGlobal.disconnectFromRobot()
                } else {
                    RobotGlobal.connectToRobot(ipField.text, parseInt(portField.text))
                }
            }
        }

        Label {
            text: RobotGlobal.isConnected ? qsTr("当前状态: 已连接") : qsTr("当前状态: 未连接")
            color: RobotGlobal.isConnected ? "green" : "gray"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
