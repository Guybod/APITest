import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../Components"
import MyRobot 1.0

Item {
    id: monitorRoot

    // 初始化弹窗数据
    property bool isInitialized: false

    // --- 数据模型存储 ---
    property var projectData: ({})
    property var robotData: ({})
    property var postureData: ({ "joint": [], "end": {} })
    property var coordData: ({ "tool": {}, "user": {} })

    // --- 辅助函数：时间戳转字符串 ---
    function formatTime(timestamp) {
        // 假设 timestamp 是秒 (如 1760946003.582)，JS需要毫秒
        var date = new Date(timestamp * 1000);
        return Qt.formatDateTime(date, "yyyy-MM-dd HH:mm:ss.zzz");
    }

    // --- 辅助函数：映射状态码到文本 ---
    function getProjectStateText(state) {
        switch(state) {
            case 0: return qsTr("空闲")
            case 1: return qsTr("正在加载工程")
            case 2: return qsTr("正在运行")
            case 3: return qsTr("暂停")
            default: return qsTr("未知")
        }
    }

    // --- 辅助函数：映射状态码到文本 ---
    function getProjectTypeText(projectType){
        switch(projectType){
            case 0: return qsTr("普通工程")
            case 1: return qsTr("远程脚本")
            case 2: return qsTr("脚本模式")
            default: return qsTr("未知")
        }
    }

    // --- 辅助函数：映射状态码到文本 ---
    function getRobotModeText(mode) {
        switch(mode) {
            case 0: return qsTr("手动")
            case 1: return qsTr("自动")
            case 2: return qsTr("远程")
            default: return qsTr("未知")
        }
    }

    // --- 辅助函数：映射状态码到文本 ---
    function getRobotStateText(state) {
        switch(state) {
            case 0: return qsTr("未使能")
            case 1: return qsTr("使能中")
            case 2: return qsTr("空闲")
            case 3: return qsTr("点动中")
            case 4: return qsTr("RunTo")
            case 5: return qsTr("拖动中")
            default: return qsTr("未知")
        }
    }

    // 3=程序输出  4=Error(警告信息)

    // --- 辅助函数：映射日志级别到颜色 ---
    function getLogColorText(code) {
        switch(code) {
            case 3: return qsTr("#3b82f6")
            case 4: return qsTr("#dc2626")
            case 6: return qsTr("#d97706")
            default: return qsTr("未知")
        }
    }

    // --- 辅助函数：映射日志级别到文本 ---
    function getLogText(code) {
        switch(code) {
            case 3: return qsTr("程序输出")
            case 4: return qsTr("错误信息")
            case 6: return qsTr("警告信息")
            default: return qsTr("未知")
        }
    }

    // 辅助函数：格式化运行时间
    function formatRunDuration(seconds) {
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        var secs = seconds % 60;
        return hours + "时" + minutes + "分" + secs + "秒";
    }

    // --- 主滚动视图 (防止内容过多超出屏幕) ---
    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: parent.width - 20 // 防止水平滚动条遮挡

        // 增加底部内边距，防止底部内容被遮挡
        bottomPadding: 20

        ColumnLayout {
            width: parent.width
            anchors.margins: 20
            spacing: 15

            // ========================================================
            // 卡片 1: 工程状态 (ProjectState)
            // ========================================================
            DataCard {
                title: qsTr("工程状态监控")
                icon: "🏗️"

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 30
                    rowSpacing: 10

                    InfoItem {
                        label: qsTr("工程 ID")
                        value: projectData.id || "--"
                    }
                    InfoItem {
                        label: qsTr("当前状态");
                        value: getProjectStateText(projectData.state)
                        valueColor: projectData.state === 2 ? "#10b981" : "#374151"
                    }
                    InfoItem {
                        label: qsTr("单步运行")
                        value: projectData.isStep ? qsTr("是") : qsTr("否")
                    }
                    InfoItem {
                        label: qsTr("工程类型")
                        value: getProjectTypeText(projectData.projectType)
                    }

                    // 脚本信息 (如果有)
                    InfoItem {
                        label: qsTr("执行行号");
                        // 简单的逻辑取出第一个脚本的行号
                        value: projectData.scripts ? (Object.values(projectData.scripts)[0]?.line || "--") : "--"
                        visible: projectData.state === 2 || projectData.state === 3
                    }
                }
            }

            // ========================================================
            // 卡片 2: 机器人状态 (RobotStatus)
            // ========================================================
            DataCard {
                title: qsTr("机器人通用状态")
                icon: "🤖"

                GridLayout {
                    Layout.fillWidth: true
                    columns: 6 // 6列布局，更紧凑
                    columnSpacing: 20
                    rowSpacing: 10

                    InfoItem {
                        label: qsTr("型号")
                        value: robotData.type || "--"
                    }
                    InfoItem {
                        label: qsTr("使能状态")
                        value: getRobotStateText(robotData.state)
                        valueColor: "#3b82f6"
                    }
                    InfoItem {
                        label: qsTr("控制模式")
                        value: getRobotModeText(robotData.mode)
                    }
                    InfoItem {
                        label: qsTr("运行时间")
                        value: formatRunDuration(robotData.runDuration)
                    }
                    InfoItem {
                        label: qsTr("自动倍率")
                        value: ((robotData.moveRate || 0)*100).toFixed(0) + "%"
                    }
                    InfoItem {
                        label: qsTr("手动倍率")
                        value: ((robotData.manualMoveRate || 0)*100).toFixed(0) + "%"
                    }

                    InfoItem {
                        label: qsTr("工具 ID")
                        value: robotData.ToolId || "-"
                    }
                    InfoItem {
                        label: qsTr("负载 ID")
                        value: robotData.PayloadId || "-"
                    }
                    InfoItem {
                        label: qsTr("坐标系 ID")
                        value: robotData.CoordinateId || "-"
                    }
                    InfoItem {
                        label: qsTr("默认工具")
                        value: robotData.defaultToolId || "-"
                    }
                    InfoItem {
                        label: qsTr("默认负载")
                        value: robotData.defaultPayloadId || "-"
                    }
                    InfoItem {
                        label: qsTr("默认坐标系")
                        value: robotData.defaultCoordinateId || "-"
                    }

                    InfoItem {
                        label: qsTr("仿真模式")
                        value: robotData.isSimulation ? qsTr("是") : qsTr("否")
                        valueColor: "#f59e0b"
                    }
                    InfoItem {
                        label: qsTr("救援模式")
                        value: robotData.rescueFlag ? qsTr("是") : qsTr("否")
                        valueColor: "#f59e0b"
                    }
                    InfoItem {
                        label: qsTr("传送带状态")
                        value: robotData.recoveryState || "-"
                        valueColor: "#f59e0b"
                    }
                    InfoItem {
                        label: qsTr("使用示教器")
                        value: robotData.teachingPendant ? qsTr("是") : qsTr("否")
                        valueColor: "#f59e0b"
                    }
                    InfoItem {
                        label: qsTr("modeSwitch")
                        value: robotData.modeSwitch || "-"
                        valueColor: "#f59e0b"
                    }
                    InfoItem {
                        label: qsTr("状态名称")
                        value: robotData.stateName || "-"
                        valueColor: "#f59e0b"
                    }
                }
            }

            // ========================================================
            // 卡片 3: 位姿信息 (RobotPosture)
            // ========================================================
            DataCard {
                title: qsTr("实时位姿信息")
                icon: "📐"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    // 关节角度
                    RowLayout {
                        Text { text: qsTr("关节角度 (J1 - J6):"); font.bold: true; color: "#6b7280" }
                        CustomButton {
                            defaultColor: "#f3f4f6"
                            buttonText: "复制"
                            // 按钮稍微小一点，适应行高
                            Layout.preferredHeight: 24
                            onClicked: {
                                // 1. 获取数据，防止为空
                                var rawData = postureData.joint || [0,0,0,0,0,0];

                                // 2. 格式化数据：保留3位小数，并转回 Number 类型以去除多余的0，
                                // 这样生成的 JSON 不会是字符串数组 ["10.000"] 而是数字数组 [10, 20.5]
                                var formattedData = rawData.map(function(val){
                                    return Number(Number(val).toFixed(3));
                                });

                                // 3. 转为字符串数组形式 "[...]" 并复制
                                clipboardHelper.copyText(JSON.stringify(formattedData));
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            // 我们手动构造一个包含 Label 和 Value 的数组模型
                            model: [
                                { label: "J1", val: postureData.joint[0] || 0},
                                { label: "J2", val: postureData.joint[1] || 0},
                                { label: "J3", val: postureData.joint[2] || 0},
                                { label: "J4", val: postureData.joint[3] || 0},
                                { label: "J5", val: postureData.joint[4] || 0},
                                { label: "J6", val: postureData.joint[5] || 0}
                            ]

                            delegate: Rectangle {
                                // 使用 Layout.fillWidth 让6个方块自动平分宽度，
                                // 效果等同于你之前的 (parent.width - 50) / 6，但更稳定
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                // 保持和关节角度一样的颜色和圆角
                                color: "#f3f4f6"
                                radius: 4

                                Text {
                                    anchors.centerIn: parent
                                    // 显示格式例如： "X: 203.002"
                                    text: modelData.label + ": " + (modelData.val || 0).toFixed(3)
                                    font.family: "Consolas"
                                    color: "#374151"
                                    font.pixelSize: 13 // 微调字体大小以防溢出
                                }
                            }
                        }
                    }

                    // 末端位姿
                    RowLayout {
                        Text { text: qsTr("末端坐标 (XYZABC):"); font.bold: true; color: "#6b7280" }
                        CustomButton {
                            defaultColor: "#f3f4f6"
                            buttonText: "复制"
                            Layout.preferredHeight: 24
                            onClicked: {
                                // 1. 提取对象中的值，按 X,Y,Z,A,B,C 顺序组成数组
                                var e = postureData.end || {};
                                var rawArr = [e.x, e.y, e.z, e.a, e.b, e.c];

                                // 2. 格式化为保留3位小数的数字
                                var formattedData = rawArr.map(function(val){
                                    return Number(Number(val || 0).toFixed(3));
                                });

                                // 3. 复制为 [10.0, 20.0, ...] 格式
                                clipboardHelper.copyText(JSON.stringify(formattedData));
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            // 我们手动构造一个包含 Label 和 Value 的数组模型
                            model: [
                                { label: "X", val: postureData.end?.x || 0},
                                { label: "Y", val: postureData.end?.y || 0},
                                { label: "Z", val: postureData.end?.z || 0},
                                { label: "A", val: postureData.end?.a || 0},
                                { label: "B", val: postureData.end?.b || 0},
                                { label: "C", val: postureData.end?.c || 0}
                            ]

                            delegate: Rectangle {
                                // 使用 Layout.fillWidth 让6个方块自动平分宽度，
                                // 效果等同于你之前的 (parent.width - 50) / 6，但更稳定
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                // 保持和关节角度一样的颜色和圆角
                                color: "#f3f4f6"
                                radius: 4

                                Text {
                                    anchors.centerIn: parent
                                    // 显示格式例如： "X: 203.002"
                                    text: modelData.label + ": " + (modelData.val || 0).toFixed(3)
                                    font.family: "Consolas"
                                    color: "#374151"
                                    font.pixelSize: 13 // 微调字体大小以防溢出
                                }
                            }
                        }
                    }
                }
            }

            // ========================================================
            // 卡片 4: 坐标系数据 (RobotCoordinate)
            // ========================================================
            DataCard {
                title: qsTr("坐标系和工具")
                icon: "🌐"

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 40

                    // 工具坐标系
                    ColumnLayout {
                        Text { text: qsTr("当前工具坐标系 (Tool):"); font.bold: true; color: "#6b7280" }
                        Label {
                            text: `X:${coordData.tool?.x?.toFixed(2) || 0}  Y:${coordData.tool?.y?.toFixed(2) || 0}  Z:${coordData.tool?.z?.toFixed(2) || 0}  A:${coordData.tool?.a?.toFixed(2) || 0}  B:${coordData.tool?.b?.toFixed(2) || 0}  C:${coordData.tool?.c?.toFixed(2) || 0}`
                            font.family: "Consolas"
                            background: Rectangle { color: "#f3f4f6"; radius: 4 }
                            padding: 8
                            Layout.fillWidth: true
                        }
                    }

                    // 用户坐标系
                    ColumnLayout {
                        Text { text: qsTr("当前用户坐标系 (User):"); font.bold: true; color: "#6b7280" }
                        Label {
                            text: `X:${coordData.user?.x?.toFixed(2) || 0}  Y:${coordData.user?.y?.toFixed(2) || 0}  Z:${coordData.user?.z?.toFixed(2) || 0}  A:${coordData.user?.a?.toFixed(2) || 0}  B:${coordData.user?.b?.toFixed(2) || 0}  C:${coordData.user?.c?.toFixed(2) || 0}`
                            font.family: "Consolas"
                            background: Rectangle { color: "#f3f4f6"; radius: 4 }
                            padding: 8
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ========================================================
            // 日志消息流 (Log Stream)
            // ========================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 300 // 固定高度
                radius: 12
                color: "white"

                // 阴影
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true; radius: 8; samples: 16; color: "#10000000"; verticalOffset: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5

                    // 标题栏
                    RowLayout {
                        Text { text: qsTr("📝 系统日志"); font.bold: true; font.pixelSize: 14 }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: qsTr("清空")
                            flat: true
                            onClicked: logModel.clear()
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb" }

                    // 日志列表
                    ListView {
                        id: logListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: ListModel { id: logModel }

                        delegate: Rectangle {
                            width: logListView.width
                            height: 30
                            color: index % 2 === 0 ? "#f9fafb" : "white" // 斑马纹

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 5
                                spacing: 10

                                // 类型: 4=Error, 6=Warning (假设)
                                Rectangle {
                                    width: 60; height: 20
                                    radius: 4
                                    color: getLogColorText(typeCode)
                                    Text {
                                        text: getLogText(typeCode)
                                        color: "black"
                                        font.pixelSize: 12
                                        anchors.centerIn: parent
                                    }
                                }

                                Text { text: errorCode; width: 50; font.family: "Consolas"; color: "#6b7280" }
                                Text { text: timeStr; width: 160; font.family: "Consolas"; font.pixelSize: 12; color: "#6b7280" }
                                Text { text: message; Layout.fillWidth: true; elide: Text.ElideRight; color: "#374151" }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================
    // 模态错误弹窗 (Modal Error Popup)
    // ========================================================
    Dialog {
        id: errorPopup

        // 1. 强制居中显示 (相对于 ApplicationWindow)
        // 使用 parent.width/height 确保它参考的是父容器中心
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        width: 520
        height: 420
        modal: true // 模态：开启遮罩
        closePolicy: Popup.NoAutoClose // 禁止点击背景关闭

        // 2. 核心：半透明黑色遮罩层 (Overlay)
        // 这会让弹窗后面的主界面变暗
        Overlay.modal: Rectangle {
            color: "#80000000" // 50% 透明度的黑色
        }

        // 3. 弹窗本体背景 (白色圆角卡片)
        background: Rectangle {
            color: "white"
            radius: 16
            // 红色边框警示
            border.color: "#fee2e2"
            border.width: 1

            // 强烈的阴影让弹窗浮起来
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 20
                samples: 25
                color: "#60000000"
                verticalOffset: 10
            }
        }

        // 弹窗数据属性
        property int errCode: 0
        property string errMsg: "Unknown Error"
        property string errTime: "--"

        // 内容布局
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25 // 增加内边距，不让内容贴边
            spacing: 15

            // 顶部图标和标题
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5

                Text {
                    text: "⚠️" // 或者用具体的 Icon 图片
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: qsTr("系统发生错误")
                    font.pixelSize: 20
                    font.bold: true
                    color: "#dc2626" // 深红
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // 中间信息区 (代码 + 时间)
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#f3f4f6" // 分割线
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 2
                rowSpacing: 5
                columnSpacing: 15

                Text { text: qsTr("错误代码:"); color: "#6b7280"; font.pixelSize: 13 }
                Text { text: errorPopup.errCode; font.bold: true; font.family: "Consolas"; color: "#374151" }

                Text { text: qsTr("发生时间:"); color: "#6b7280"; font.pixelSize: 13 }
                Text { text: errorPopup.errTime; font.family: "Consolas"; font.pixelSize: 13; color: "#374151" }
            }

            // 底部错误详情框 (带滚动条，防止文字太长看不见)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true // 自动占据剩余空间
                color: "#fef2f2" // 浅红背景
                radius: 8
                border.color: "#fecaca"
                border.width: 1

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true // 必须开启裁剪，否则文字会溢出框外

                    TextArea {
                        width: parent.width
                        // 手动处理尖括号，防止 textFormat 失效或渲染引擎混淆
                        text: errorPopup.errMsg.replace(/</g, "&lt;").replace(/>/g, "&gt;")
                        color: "#b91c1c" // 深红文字
                        font.pixelSize: 13
                        readOnly: true
                        wrapMode: Text.Wrap // 自动换行
                        background: null // 去掉 TextArea 自带的背景
                        textFormat: Text.RichText
                    }
                }
            }

            // 确认按钮
            Button {
                text: qsTr("确认并关闭")
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                // 红色按钮样式
                contentItem: Text {
                    text: parent.text
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#991b1b" : "#dc2626"
                    radius: 8

                    // 按钮按下时的微动效
                    scale: parent.down ? 0.98 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                onClicked: errorPopup.close()
            }
        }
    }

    // ========================================================
    // 内部组件封装
    // ========================================================

    // 1. 数据卡片容器
    component DataCard : Rectangle {
        property string title
        property string icon
        default property alias content: innerLayout.data

        Layout.fillWidth: true
        // 高度自适应内容 + 内边距
        implicitHeight: innerLayout.implicitHeight + 60
        color: "white"
        radius: 12

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true; radius: 8; samples: 16; color: "#10000000"; verticalOffset: 2
        }

        ColumnLayout {
            id: innerLayout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            RowLayout {
                Text { text: icon; font.pixelSize: 18 }
                Text { text: title; font.bold: true; font.pixelSize: 15; color: "#1f2937" }
                Item { Layout.fillWidth: true }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#f3f4f6" }

            // 外部内容会插入到这里
        }
    }

    // 2. 信息项 (Label + Value)
    component InfoItem : Column {
        property string label
        property string value
        property color valueColor: "#111827"

        spacing: 5
        Layout.fillWidth: true // 在 Grid 中拉伸

        Text {
            text: label
            color: "#6b7280"
            font.pixelSize: 12
            anchors.left: parent.left
        }
        Text {
            text: value
            color: valueColor
            font.bold: true
            font.pixelSize: 14
            font.family: "Microsoft YaHei"
        }
    }

    // ========================================================
    // 信号处理
    // ========================================================
    Connections {
        target: RobotGlobal

        // 1. 工程状态
        function onRecvProjectStateMessage(msg) {
            projectData = msg
        }

        // 2. 机器人通用状态
        function onRecvRobotStatusMessage(msg) {
            robotData = msg
        }

        // 3. 位姿
        function onRecvRobotPostureMessage(msg) {
            postureData = msg
        }

        // 4. 坐标系
        function onRecvRobotCoordinateMessage(msg) {
            coordData = msg
        }

        // 5. 日志 (Log) - 数组格式 [type, code, time, msg]
        function onRecvLogMessage(msg) {
            if (msg.db && Array.isArray(msg.db)) {
                // msg.db 是一个包含多条日志的数组 [[...], [...]]
                msg.db.forEach(function(logEntry) {
                    logModel.insert(0, { // 插入到最前面
                        typeCode: logEntry[0],
                        errorCode: logEntry[1],
                        timeStr: formatTime(logEntry[2]),
                        message: logEntry[3]
                    })
                    console.log(logEntry[0])
                })

                // 限制日志条数，防止内存溢出
                if (logModel.count > 100) logModel.remove(100, logModel.count - 100)
            }
        }

        // 6. 错误 (Error) - 需要弹窗
        function onRecvErrorMessage(msg) {
            // 1. 记录到日志流 (保持不变)
            if (msg.db && Array.isArray(msg.db)) {
                 onRecvLogMessage(msg);
            }

            // 【关键判断】
            // 1. 必须有 db
            // 2. db 必须是数组
            // 3. 数组长度必须 > 0 (防止空数组触发弹窗)
            if (msg.db && Array.isArray(msg.db) && msg.db.length > 0) {

                var lastErrorEntry = msg.db[msg.db.length - 1];

                // 二次校验内部数据完整性 [type, code, time, msg]
                if (Array.isArray(lastErrorEntry) && lastErrorEntry.length >= 4) {

                    // 【可选优化】如果错误代码是 0 或者某些代表“正常/清除”的代码，不弹窗
                    // if (lastErrorEntry[1] === 0) return;

                    errorPopup.errCode = lastErrorEntry[1]
                    errorPopup.errTime = formatTime(lastErrorEntry[2])
                    errorPopup.errMsg = String(lastErrorEntry[3]) // 强转 String 保险

                    errorPopup.open()
                }
            }
        }

        function onDisconnected() {
            // 断开连接时可选清空或保持最后状态
        }
    }

    // 在组件加载完成后延迟几秒再允许弹窗
    Component.onCompleted: {
        timerInit.start()
    }

    Timer {
        id: timerInit
        interval: 2000 // 2秒后才允许弹窗
        onTriggered: isInitialized = true
    }

    // --- 辅助组件：用于实现复制功能 ---
    TextEdit {
        id: clipboardHelper
        visible: false // 隐藏不可见
        text: ""

        function copyText(dataStr) {
            text = dataStr
            selectAll()
            copy()
            // 可选：在这里调用一个 Toast 提示用户复制成功
            console.log("已复制到剪贴板: " + text)
        }
    }

}
