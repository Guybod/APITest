import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import MyRobot 1.0

Item {
    id: motionPage

    // ------------------------------------------------------------------
    // 辅助配置
    // ------------------------------------------------------------------
    readonly property int typeJointMove: 8
    readonly property int typeLinearMove: 9

    property var presetButtons: [
        { label: qsTr("🏠 原位 (Home)"), type: 0, color: "#10b981" },
        { label: qsTr("🛡️ 安全位置"), type: 1, color: "#3b82f6" },
        { label: qsTr("🕯️ 蜡烛位"), type: 2, color: "#8b5cf6" },
        { label: qsTr("📦 打包位"), type: 3, color: "#f59e0b" },
        { label: qsTr("🔄 程序恢复点"), type: 6, color: "#6366f1" }
    ]

    // 正逆解结果存储
    property string forwardResult: "--"
    property string inverseResult: "--"

    // 监听计算结果
    Connections {
        target: RobotGlobal
        function onRecvNormalMessage(msg) {
            // 10.1 正解返回
            if (msg.ty === "Robot/apostocpos") {
                if (msg.db && Array.isArray(msg.db)) {
                    // 格式化为 [x, y, z, a, b, c]
                    forwardResult = JSON.stringify(msg.db.map(v => v.toFixed(3)))
                } else {
                    forwardResult = "计算失败"
                }
            }
            // 10.2 逆解返回
            else if (msg.ty === "Robot/cpostoapos") {
                if (msg.db && Array.isArray(msg.db)) {
                    inverseResult = JSON.stringify(msg.db.map(v => v.toFixed(3)))
                } else {
                    inverseResult = "计算失败 (可能无解或参数错误)"
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 界面布局
    // ------------------------------------------------------------------

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: parent.width - 20 // 防止水平滚动

        ColumnLayout {
            width: parent.width
            anchors.margins: 20
            spacing: 20

            // ============================================================
            // 第一行：状态与心跳监控 (保持不变)
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                radius: 12
                color: "white"

                layer.enabled: true
                layer.effect: DropShadow { transparentBorder: true; radius: 8; color: "#10000000"; verticalOffset: 2 }

                // 左侧：状态与心跳
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 40

                    // 机器人状态
                    RowLayout {
                        spacing: 15
                        Rectangle {
                            width: 50; height: 50; radius: 25
                            color: "#f3f4f6"
                            Text { text: "🤖"; font.pixelSize: 24; anchors.centerIn: parent }
                        }
                        Column {
                            Text { text: qsTr("机器人状态"); color: "#6b7280"; font.pixelSize: 12 }
                            Text {
                                text: RobotGlobal.robotState === 4 ? qsTr("RunTo 运动中") : (qsTr("状态码: ") + RobotGlobal.robotState)
                                font.bold: true; font.pixelSize: 20
                                color: RobotGlobal.robotState === 4 ? "#3b82f6" : "#374151"
                            }
                        }
                    }
                    Rectangle { width: 1; height: 40; color: "#e5e7eb" }

                    // 心跳信号
                    RowLayout {
                        spacing: 15
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: RobotGlobal.robotState === 4 ? "#ef4444" : "#d1d5db"
                            SequentialAnimation on scale {
                                running: RobotGlobal.robotState === 4
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.3; duration: 400; easing.type: Easing.OutQuad }
                                NumberAnimation { from: 1.3; to: 1.0; duration: 400; easing.type: Easing.OutQuad }
                            }
                        }
                        Column {
                            Text { text: qsTr("心跳信号 (Heartbeat)"); color: "#6b7280"; font.pixelSize: 12 }
                            Text {
                                text: RobotGlobal.robotState === 4 ? qsTr("发送中...") : qsTr("休眠")
                                font.bold: true; font.pixelSize: 16
                                color: RobotGlobal.robotState === 4 ? "#ef4444" : "#9ca3af"
                            }
                        }
                    }
                    Item { Layout.fillWidth: true } // 占位符，把控制区推到右边
                    // 右侧：机器人控制按钮组
                    ColumnLayout {
                        spacing: 10

                        // 模式切换
                        RowLayout {
                            spacing: 10
                            Label { text: "模式切换:"; font.bold: true; color: "#6b7280" }
                            Button { text: "✋ 手动"; onClicked: RobotGlobal.sendJsonRequest("Robot/toManual", "") }
                            Button { text: "🤖 自动"; onClicked: RobotGlobal.sendJsonRequest("Robot/toAuto", "") }
                            Button { text: "📡 远程"; onClicked: RobotGlobal.sendJsonRequest("Robot/toRemote", "") }
                        }

                        // 使能控制
                        RowLayout {
                            spacing: 10
                            Label { text: "使能控制:"; font.bold: true; color: "#6b7280" }
                            Button {
                                text: "⚡ 上使能 (ON)"
                                background: Rectangle { color: parent.down?"#047857":"#059669"; radius: 4 }
                                contentItem: Text { text:parent.text; color:"white"; font.bold:true; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter }
                                onClicked: RobotGlobal.sendJsonRequest("Robot/switchOn", "")
                            }
                            Button {
                                text: "🛑 下使能 (OFF)"
                                background: Rectangle { color: parent.down?"#b91c1c":"#dc2626"; radius: 4 }
                                contentItem: Text { text:parent.text; color:"white"; font.bold:true; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter }
                                onClicked: RobotGlobal.sendJsonRequest("Robot/switchOff", "")
                            }

                            // 远程脚本模式
                            Button {
                                text: "📜 远程脚本模式"
                                onClicked: RobotGlobal.sendJsonRequest("project/enterRemoteScriptMode")
                            }
                        }
                    }
                }
            }
            // ============================================================
            // 【新增】 第二行：工程运行控制
            // ============================================================
            MotionCard {
                title: qsTr("🚀 工程运行控制 (Project Control)")
                iconColor: "#f59e0b"

                content: ColumnLayout {
                    spacing: 15

                    // 第一排：ID运行、索引运行
                    RowLayout {
                        spacing: 20

                        // 运行指定ID工程
                        InputGroup {
                            id: inputProjectId
                            label: qsTr("工程 ID (Folder Name)")
                            placeholder: "e.g. mhv9ub..."
                            Layout.preferredWidth: 200
                            enableValidator: false
                        }
                        Button {
                            text: qsTr("运行 ID 工程")
                            Layout.alignment: Qt.AlignBottom
                            onClicked: {
                                var pid = inputProjectId.inputValue.trim()
                                if(!pid) return
                                var data = { "id": pid }
                                var jsonString = JSON.stringify(data)
                                RobotGlobal.sendJsonRequest("project/run", jsonString)
                            }
                        }
                        Button {
                            text: qsTr("单步运行 (ID)")
                            Layout.alignment: Qt.AlignBottom
                            onClicked: {
                                var pid = inputProjectId.inputValue.trim()
                                var data = {}
                                if(pid) data["id"] = pid // 只有第一次需要传ID，后续暂停不需要，这里简化逻辑全传
                                var jsonString = JSON.stringify(dataObj)
                                RobotGlobal.sendJsonRequest("project/runStep", jsonString)
                            }
                        }

                        Rectangle { width: 1; height: 30; color: "#e5e7eb"; Layout.alignment: Qt.AlignBottom }

                        // 运行索引工程
                        InputGroup {
                            id: inputProjectIndex
                            label: qsTr("映射索引 (0-127)")
                            placeholder: "0"
                            Layout.preferredWidth: 100
                            // 简单的整数验证
                            customValidator: IntValidator{ bottom: 0; top: 127 }
                        }
                        Button {
                            text: qsTr("按索引运行")
                            Layout.alignment: Qt.AlignBottom
                            onClicked: {
                                var idx = parseInt(inputProjectIndex.inputValue)
                                if(isNaN(idx)) return
                                // 直接发整数
                                RobotGlobal.sendJsonRequest("project/runByIndex", idx)
                            }
                        }
                    }

                    // 第二排：全局控制按钮 (暂停、恢复、停止)
                    RowLayout {
                        spacing: 10

                        // 常用控制按钮封装
                        component CtrlBtn : Button {
                            property color baseColor: "#6b7280"
                            Layout.preferredWidth: 100
                            background: Rectangle {
                                radius: 6
                                color: parent.down ? Qt.darker(baseColor, 1.2) : baseColor
                            }
                            contentItem: Text {
                                text: parent.text; color: "white"; font.bold: true
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }

                        CtrlBtn {
                            text: qsTr("⏸ 暂停")
                            baseColor: "#f59e0b"
                            onClicked: RobotGlobal.sendJsonRequest("project/pause")
                        }
                        CtrlBtn {
                            text: qsTr("▶ 恢复")
                            baseColor: "#10b981"
                            onClicked: RobotGlobal.sendJsonRequest("project/resume")
                        }
                        CtrlBtn {
                            text: qsTr("⏹ 停止")
                            baseColor: "#ef4444"
                            onClicked: RobotGlobal.sendJsonRequest("project/stop")
                        }
                    }

                    // 第三排：启动行设置
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f3f4f6" }

                    RowLayout {
                        spacing: 15
                        InputGroup {
                            id: inputStartLine
                            label: qsTr("启动行号 (Start Line)")
                            placeholder: "e.g. 3"
                            Layout.preferredWidth: 150
                            customValidator: IntValidator{ bottom: 1 }
                        }
                        Button {
                            text: qsTr("设置启动行")
                            Layout.alignment: Qt.AlignBottom
                            onClicked: {
                                var line = parseInt(inputStartLine.inputValue)
                                if(isNaN(line)) return
                                RobotGlobal.sendJsonRequest("project/setStartLine", line)
                            }
                        }
                        Button {
                            text: qsTr("清除设置")
                            Layout.alignment: Qt.AlignBottom
                            flat: true
                            onClicked: RobotGlobal.sendJsonRequest("project/clearStartLine")
                        }
                    }
                }
            }

            // ============================================================
            // 第三行：预设点位按钮
            // ============================================================
            MotionCard {
                title: qsTr("📍 快捷指令 (Presets)")
                iconColor: "#8b5cf6"

                content: RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    Repeater {
                        model: presetButtons
                        delegate: Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            text: modelData.label
                            background: Rectangle {
                                radius: 6
                                color: parent.down ? Qt.darker(modelData.color, 1.1) : modelData.color
                            }
                            contentItem: Text {
                                text: parent.text; color: "white"; font.bold: true
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: RobotGlobal.sendRunTo(modelData.type, {})
                        }
                    }
                }
            }

            // ============================================================
            //  第四行：关节运动 & 正解
            // ============================================================
            MotionCard {
               title: qsTr("🦾 关节运动 (Joint Move)")
               iconColor: "#3b82f6"

               content: ColumnLayout {
                   spacing: 15

                   // 1. 输入区
                   RowLayout {
                       spacing: 10
                       Repeater {
                           id: jointRepeater
                           model: ["J1", "J2", "J3", "J4", "J5", "J6"]
                           delegate: InputGroup {
                               label: modelData; suffix: "°"
                               minValue: -360; maxValue: 360; decimals: 3; placeholder: "0.000"
                           }
                       }

                       // 运动按钮
                       Button {
                           text: qsTr("执行关节运动")
                           Layout.preferredHeight: 40; Layout.preferredWidth: 120; Layout.leftMargin: 20
                           background: Rectangle { color: parent.down ? "#1d4ed8" : "#2563eb"; radius: 6 }
                           contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                           onClicked: {
                               var jointArr = []
                               for(var i=0; i<jointRepeater.count; i++) {
                                   var val = parseFloat(jointRepeater.itemAt(i).inputValue)
                                   if (isNaN(val)) val = 0.0
                                   jointArr.push(val)
                               }
                               RobotGlobal.sendJsonRequest(typeJointMove, JSON.stringify({"joint": jointArr}))
                           }
                       }
                   }

                   Rectangle { Layout.fillWidth: true; height: 1; color: "#f3f4f6" }

                   // 2. 正解计算区
                   RowLayout {
                       spacing: 15
                       Text { text: "计算工具:"; font.bold: true; color: "#6b7280" }

                       Button {
                           text: "📐 计算正解 (Forward Kinematics)"
                           onClicked: {
                               // 收集关节角
                               var jp = []
                               for(var i=0; i<jointRepeater.count; i++) {
                                   var val = parseFloat(jointRepeater.itemAt(i).inputValue)
                                   if (isNaN(val)) val = 0.0
                                   jp.push(val)
                               }

                               // 构造请求数据 (简化逻辑：假设 Tool/Coor 均为 0，如果需要可以扩展输入框)
                               var req = {
                                   "jp": jp,
                                   "coor": [0,0,0,0,0,0],
                                   "tool": [0,0,0,0,0,0],
                                   "ep": []
                               }

                               forwardResult = "计算中..."
                               RobotGlobal.sendJsonRequest("Robot/apostocpos", JSON.stringify(req))
                           }
                       }

                       Text {
                           text: "结果 (笛卡尔): "
                           color: "#374151"
                       }
                       Text {
                           text: forwardResult
                           font.family: "Consolas"
                           font.bold: true
                           color: "#059669"
                           Layout.fillWidth: true
                           elide: Text.ElideRight
                       }
                   }
               }
           }
            // ============================================================
            // 第五行：直线运动 & 逆解
            // ============================================================
            MotionCard {
                title: qsTr("📏 直线运动 (Linear Move)")
                iconColor: "#10b981"

                content: ColumnLayout {
                    spacing: 15

                    // 1. 输入区
                    RowLayout {
                        spacing: 10
                        Repeater {
                            id: linearRepeater
                            model: ["X", "Y", "Z", "A", "B", "C"]
                            delegate: InputGroup {
                                label: modelData; suffix: index < 3 ? "mm" : "°"
                                minValue: -2000; maxValue: 2000; decimals: 3; placeholder: "0.000"
                            }
                        }
                        Button {
                            text: qsTr("执行直线运动")
                            Layout.preferredHeight: 40; Layout.preferredWidth: 120; Layout.leftMargin: 20
                            background: Rectangle { color: parent.down ? "#047857" : "#059669"; radius: 6 }
                            contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: {
                                var keys = ["x", "y", "z", "a", "b", "c"]
                                var endObj = {}
                                for(var i=0; i<linearRepeater.count; i++) {
                                    var val = parseFloat(linearRepeater.itemAt(i).inputValue)
                                    if (isNaN(val)) val = 0.0
                                    endObj[keys[i]] = val
                                }
                                RobotGlobal.sendRunTo(typeLinearMove, endObj)
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f3f4f6" }

                    // 2. 逆解计算区
                    RowLayout {
                        spacing: 15
                        Text { text: "计算工具:"; font.bold: true; color: "#6b7280" }

                        Button {
                            text: "🔄 计算逆解 (Inverse Kinematics)"
                            onClicked: {
                                // 收集笛卡尔坐标
                                var cp = []
                                for(var i=0; i<linearRepeater.count; i++) {
                                    var val = parseFloat(linearRepeater.itemAt(i).inputValue)
                                    if (isNaN(val)) val = 0.0
                                    cp.push(val)
                                }

                                // 构造请求 (rj 参考关节角默认为 20,20...)
                                var req = {
                                    "cp": cp,
                                    "rj": [20,20,20,20,20,20],
                                    "ep": []
                                }

                                inverseResult = "计算中..."
                                RobotGlobal.sendJsonRequest("Robot/cpostoapos", JSON.stringify(req))
                            }
                        }

                        Text {
                            text: "结果 (关节角): "
                            color: "#374151"
                        }
                        Text {
                            text: inverseResult
                            font.family: "Consolas"
                            font.bold: true
                            color: "#059669"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ------------------------------------------------------------------
    // 自定义组件封装
    // ------------------------------------------------------------------

    // 1. 运动控制卡片容器 (高度自适应内容)
    component MotionCard : Rectangle {
        property string title
        property color iconColor
        default property alias content: innerPlaceholder.data

        Layout.fillWidth: true
        // 高度 = 内边距 + 标题高 + 内容高 + 底部缓冲
        implicitHeight: innerPlaceholder.implicitHeight + 60
        radius: 12
        color: "white"

        layer.enabled: true
        layer.effect: DropShadow { transparentBorder: true; radius: 8; color: "#10000000"; verticalOffset: 2 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            RowLayout {
                Rectangle { width: 4; height: 16; radius: 2; color: iconColor }
                Text { text: title; font.bold: true; color: "#374151" }
            }

            Item {
                id: innerPlaceholder
                Layout.fillWidth: true
                // 关键：让 Item 的高度跟随其子项的高度
                implicitHeight: childrenRect.height
            }
        }
    }

    // 2. 带标签和校验的输入框组
    component InputGroup : ColumnLayout {
        property string label
        property string suffix: ""
        property string placeholder: ""
        property real minValue: -99999
        property real maxValue: 99999
        property int decimals: 0
        property var customValidator: null // 支持外部传入自定义验证器
        // 【新增】是否启用验证器？默认为 true (数字模式)
        // 如果设为 false，则可以输入任意字符 (如工程ID)
        property bool enableValidator: true

        property alias inputValue: field.text

        spacing: 5
        Layout.fillWidth: true

        RowLayout {
            Text { text: label; font.bold: true; color: "#4b5563"; font.pixelSize: 13 }
            Item { Layout.fillWidth: true }
            Text { text: suffix; color: "#9ca3af"; font.pixelSize: 12; visible: suffix !== "" }
        }

        // 定义一个默认的 DoubleValidator
        DoubleValidator {
            id: defaultValidator
            bottom: minValue
            top: maxValue
            decimals: decimals
            notation: DoubleValidator.StandardNotation
        }


        TextField {
            id: field
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            placeholderText: placeholder
            font.family: "Consolas"
            selectByMouse: true

            background: Rectangle {
                radius: 4
                color: field.activeFocus ? "white" : "#f9fafb"
                border.color: !field.acceptableInput && field.text.length > 0 ? "#ef4444" : (field.activeFocus ? "#3b82f6" : "#d1d5db")
                border.width: 1
            }
            validator: enableValidator ? (customValidator !== null ? customValidator : defaultValidator) : null
        }
    }
}
