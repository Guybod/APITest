import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "./Components"
import "./Page"
import MyRobot 1.0 // 引入单例模块

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    visible: true
    title: qsTr("Robot Control Panel")

    // 设置全局字体（可选）
    font.family: "Microsoft YaHei"
    font.pixelSize: 14


    // ---------------------------------------------------------
    // 顶部菜单栏
    // ---------------------------------------------------------
    menuBar: CustomMenuBar {
        onConnectClicked: {
            if(!RobotGlobal.isConnected){
                RobotGlobal.connectToRobot(pageConnect.host, parseInt(pageConnect.port))
            }
        }

        onDisconnectClicked: {
            RobotGlobal.disconnectFromRobot()
        }
    }

    // ---------------------------------------------------------
    // 主体区域 (SplitView)
    // ---------------------------------------------------------
    SplitView {
        anchors.fill: parent

        // === 1. 左侧导航栏 ===
        Rectangle {
            id: leftPanel
            SplitView.preferredWidth: 220
            SplitView.minimumWidth: 180
            SplitView.maximumWidth: 280
            color: "#f3f4f6" // 现代浅灰色背景

            // 右侧分割线装饰
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: "#e5e7eb"
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 1.1 导航标题区域
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        spacing: 10
                        Text {
                            text: "⚡" // 可以换成Logo图片
                            font.pixelSize: 20
                        }
                        Text {
                            text: "功能导航"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#1f2937"
                        }
                    }
                }

                // 1.2 导航按钮列表
                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 10
                    spacing: 4
                    clip: true

                    // 在这里添加了 icon 属性用于显示
                    model: ListModel {
                        ListElement { name: qsTr("连接配置"); icon: "🌐" }
                        ListElement { name: qsTr("状态监控"); icon: "📊" }
                        ListElement { name: qsTr("运动控制"); icon: "⚙️" }
                        ListElement { name: qsTr("变量接口"); icon: "🏷️️" }
                        ListElement { name: qsTr("IO和寄存器"); icon: "🏷️️" }
                        ListElement { name: qsTr("串口通信"); icon: "🔌️" }
                        ListElement { name: qsTr("用户手册"); icon: "📖" }
                    }

                    // 自定义代理，替代原生的 ItemDelegate
                    delegate: Rectangle {
                        id: navItemDelegate
                        width: navList.width - 16 // 留出左右边距
                        height: 46
                        radius: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        // 选中状态颜色逻辑
                        color: ListView.isCurrentItem ? "#3b82f6" : (mouseArea.containsMouse ? "#e5e7eb" : "transparent")

                        // 颜色过渡动画
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 12

                            Text {
                                text: model.icon
                                font.pixelSize: 16
                                // 选中变白，未选中深灰
                                color: navItemDelegate.ListView.isCurrentItem ? "white" : "#4b5563"
                            }

                            Text {
                                text: model.name
                                font.bold: true
                                Layout.fillWidth: true
                                color: navItemDelegate.ListView.isCurrentItem ? "white" : "#374151"
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                navList.currentIndex = index
                                mainStack.currentIndex = index // 核心逻辑保持不变
                            }
                        }
                    }
                }

                // 1.3 底部版本号 (装饰)
                Text {
                    text: "v1.0.2"
                    color: "#9ca3af"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 10
                }
            }
        }

        // === 2. 右侧内容区域 ===
        Rectangle {
            SplitView.fillWidth: true
            color: "white"

            StackLayout {
                id: mainStack
                anchors.fill: parent
                currentIndex: 0

                // 页面切换时的淡入淡出效果 (纯UI优化，不影响逻辑)
                // 注意：StackLayout直接切换 opacity 动画可能需要额外封装，这里保持原生最稳

                // index 0: 连接配置页
                PageConnect {
                    id:pageConnect
                }
                // index 1: 状态监控页
                PageMonitor { }

                // index 2: 运动控制页
                PageMove { }

                // index 3: 变量管理页
                PageVariable {
                }

                // index 4: IO和寄存器管理页
                PageIORegister {
                }

                // index 5: 串口通信管理页
                PageSerial {
                }

                // index 6: 使用手册管理页
                PageUserManual {
                }
            }
        }
    }

    // ---------------------------------------------------------
    // 底部状态栏 (Footer) - 扁平化风格
    // ---------------------------------------------------------
    footer: Rectangle {
        height: 36
        color: "white"

        // 顶部边框
        Rectangle { width: parent.width; height: 1; color: "#e5e7eb" }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 15

            // 系统状态
            RowLayout {
                spacing: 6
                Text {
                    text: "系统通信:"
                    font.bold: true
                    font.pixelSize: 12
                    color: "#6b7280"
                }

                // 状态指示灯 (带呼吸动画)
                Rectangle {
                    width: 10; height: 10
                    radius: 5
                    color: RobotGlobal.isConnected ? "#10b981" : "#ef4444" // 绿色/红色

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: RobotGlobal.isConnected // 只在连接时闪烁
                        NumberAnimation { from: 1.0; to: 0.5; duration: 1000 }
                        NumberAnimation { from: 0.5; to: 1.0; duration: 1000 }
                    }
                }

                Text {
                    text: RobotGlobal.isConnected ? "在线" : "离线"
                    color: RobotGlobal.isConnected ? "#059669" : "#dc2626"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            // 竖线分割
            Rectangle { width: 1; height: 16; color: "#e5e7eb" }

            // 机器人状态码
            RowLayout {
                spacing: 6
                Text {
                    text: "状态码:"
                    color: "#6b7280"
                    font.pixelSize: 12
                }
                Text {
                    text: RobotGlobal.robotState
                    color: "#374151"
                    font.family: "Consolas" // 等宽字体显示数字更好看
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true } // 占位符

            // 右下角时间或信息
            Text {
                text: Qt.formatDateTime(new Date(), "HH:mm")
                color: "#9ca3af"
                font.pixelSize: 12
            }
        }
    }
}
