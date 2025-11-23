import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import MyRobot 1.0 // 引入 SerialGlobal

Item {
    id: pageSerial

    // ------------------------------------------------------------------
    // 状态属性
    // ------------------------------------------------------------------
    property bool isHexRecv: true
    property bool isHexSend: true
    property bool autoScroll: true

    // 自动发送定时器
    Timer {
        id: autoSendTimer
        interval: 1000
        repeat: true
        onTriggered: sendData()
    }

    // ------------------------------------------------------------------
    // 逻辑函数
    // ------------------------------------------------------------------
    function sendData() {
        if (!SerialGlobal.isConnected) return
        var text = inputArea.text
        if (text === "") return

        // 调用 C++ 发送
        SerialGlobal.send(text, isHexSend)

        // 如果勾选了发送回显，可以手动 append 到 logArea
        // logArea.append(">> " + text)
    }

    // 监听 C++ 信号
    Connections {
        target: SerialGlobal

        // 核心：接收数据
        function onMessageReceived(textMsg, hexMsg) {
            var content = isHexRecv ? hexMsg : textMsg
            logArea.insert(logArea.length, content)

            if (autoScroll) {
                logArea.cursorPosition = logArea.length
            }
        }

        // 错误提示
        function onErrorOccurred(msg) {
            console.error(msg) // 或者弹窗提示
        }
    }

    // ------------------------------------------------------------------
    // 界面布局
    // ------------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ============================================================
        // 左侧：串口设置面板 (风格类似寄存器界面)
        // ============================================================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 260
            color: "white"
            radius: 8

            layer.enabled: true
            layer.effect: DropShadow { transparentBorder: true; radius: 6; color: "#08000000"; verticalOffset: 2 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                // 标题
                Text {
                    text: "⚙️ 串口配置"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#374151"
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb" }

                // 1. 端口号 (点击刷新)
                SettingCombo {
                    label: "端口号 (Port)"
                    model: SerialGlobal.portList

                    // 点击下拉框时自动刷新列表
                    onPressedChanged: {
                        if (pressed) SerialGlobal.refreshPorts()
                    }
                }

                // 2. 波特率
                SettingCombo {
                    id: comboBaud
                    label: "波特率 (BaudRate)"
                    model: SerialGlobal.baudList
                    currentIndex: 4 // 默认 115200
                }

                // 3. 数据位
                SettingCombo {
                    id: comboData
                    label: "数据位 (DataBits)"
                    model: SerialGlobal.dataBitsList
                    currentIndex: 3 // 默认 8
                }

                // 4. 校验位
                SettingCombo {
                    id: comboParity
                    label: "校验位 (Parity)"
                    model: SerialGlobal.parityList
                    currentIndex: 0 // 默认 None
                }

                // 5. 停止位
                SettingCombo {
                    id: comboStop
                    label: "停止位 (StopBits)"
                    model: SerialGlobal.stopBitsList
                    currentIndex: 0 // 默认 1
                }

                Item { Layout.fillHeight: true } // 弹簧

                // 开关按钮
                Button {
                    text: SerialGlobal.isConnected ? "🔴 关闭串口" : "🟢 打开串口"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45

                    background: Rectangle {
                        color: SerialGlobal.isConnected ? "#fee2e2" : "#d1fae5"
                        radius: 6
                        border.color: SerialGlobal.isConnected ? "#ef4444" : "#10b981"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: SerialGlobal.isConnected ? "#dc2626" : "#059669"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (SerialGlobal.isConnected) {
                            SerialGlobal.close()
                        } else {
                            // 传入所有参数
                            SerialGlobal.open(
                                portCombo.currentText,
                                comboBaud.currentText,
                                comboData.currentText,
                                comboParity.currentText,
                                comboStop.currentText
                            )
                        }
                    }
                }

                // 在线调试助手链接
                Button {
                    text: "🌐 在线调试助手"
                    flat: true
                    Layout.alignment: Qt.AlignHCenter
                    contentItem: Text {
                        text: parent.text
                        color: "#3b82f6"
                        font.underline: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: Qt.openUrlExternally("https://serial.baud-dance.com/#/")
                }
            }
        }

        // ============================================================
        // 中间：收发区域
        // ============================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            // 1. 接收区 (60% 高度)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 6
                color: "#1e1e1e" // 极客黑背景
                radius: 8
                border.color: "#374151"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    // 显式指定内容尺寸，防止 ScrollView 塌陷
                    contentWidth: availableWidth

                    TextArea {
                        id: logArea
                        readOnly: true
                        selectByMouse: true
                        background: null
                        wrapMode: Text.Wrap

                        // 样式
                        color: "#4ade80" // 终端绿
                        font.family: "Consolas"
                        font.pixelSize: 13
                        text: "Ready...\n"
                    }
                }

                // 接收区标签
                Text {
                    text: "RX"
                    color: "#6b7280"
                    font.bold: true
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    opacity: 0.5
                }
            }

            // 2. 发送区 (剩余高度)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 4
                color: "white"
                radius: 8

                layer.enabled: true
                layer.effect: DropShadow { transparentBorder: true; radius: 6; color: "#08000000"; verticalOffset: 2 }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 2.1 工具栏头部
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: "#f9fafb"

                        // 底部边框
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#e5e7eb" }

                        // 圆角处理
                        radius: 8
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: "#f9fafb" }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 15

                            CheckBox { text: "HEX接收"; checked: isHexRecv; onCheckedChanged: isHexRecv = checked }
                            CheckBox { text: "HEX发送"; checked: isHexSend; onCheckedChanged: isHexSend = checked }
                            CheckBox { text: "自动滚动"; checked: autoScroll; onCheckedChanged: autoScroll = checked }

                            Item { Layout.fillWidth: true } // 弹簧

                            Button {
                                text: "🗑️ 清空接收"
                                flat: true
                                onClicked: logArea.text = ""
                            }
                            Button {
                                text: "🗑️ 清空发送"
                                flat: true
                                onClicked: inputArea.text = ""
                            }
                        }
                    }

                    // 2.2 输入框
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextArea {
                            id: inputArea
                            placeholderText: "在此输入要发送的数据..."
                            selectByMouse: true
                            font.family: "Consolas"
                            background: null
                            padding: 10
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb" }

                    // 2.3 底部发送按钮区
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 10
                        spacing: 10

                        Text { text: "TX"; font.bold: true; color: "#9ca3af" }

                        Item { Layout.fillWidth: true }

                        // 自动发送设置
                        CheckBox {
                            text: "自动发送"
                            checked: autoSendTimer.running
                            onCheckedChanged: autoSendTimer.running = checked
                        }
                        TextField {
                            id: intervalInput
                            text: "1000"
                            placeholderText: "ms"
                            Layout.preferredWidth: 60
                            validator: IntValidator { bottom: 10 }
                            onEditingFinished: autoSendTimer.interval = parseInt(text)
                        }
                        Text { text: "ms"; color: "#6b7280" }

                        // 发送按钮
                        Button {
                            text: "发送"
                            Layout.preferredWidth: 80
                            enabled: SerialGlobal.isConnected

                            background: Rectangle {
                                color: parent.enabled ? (parent.down ? "#1d4ed8" : "#2563eb") : "#e5e7eb"
                                radius: 4
                            }
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "white" : "#9ca3af"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: sendData()
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 组件封装
    // ------------------------------------------------------------------
    component SettingCombo : ColumnLayout {
        property string label
        property alias model: combo.model
        property alias currentIndex: combo.currentIndex
        property alias currentText: combo.currentText
        // 暴露 pressed 属性供外部检测点击
        property alias pressed: combo.pressed

        spacing: 5

        Text {
            text: label
            font.pixelSize: 12
            color: "#6b7280"
            font.bold: true
        }

        ComboBox {
            id: combo
            // 给外部 id 引用
            property alias comboObj: combo
            Layout.fillWidth: true

            // 如果是端口号列表，我们要把 id 暴露出去
            Component.onCompleted: {
                if (label.indexOf("端口") !== -1) pageSerial.portCombo = combo
            }
        }
    }

    // 辅助属性，用于在按钮里引用端口下拉框
    property var portCombo: null
}
