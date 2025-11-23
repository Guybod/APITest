import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import MyRobot 1.0

Item {
    id: pageIOReg

    // ============================================================
    // 顶部导航栏 (Tab Bar)
    // ============================================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: bar
            width: parent.width
            Layout.fillWidth: true

            TabButton { text: qsTr("🔌 IO 状态监控与控制") }
            TabButton { text: qsTr("🔢 寄存器 (Register) 管理") }
        }

        StackLayout {
            width: parent.width
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // ---------------- Tab 1: IO 页面 ----------------
            IOControlPage {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            // ---------------- Tab 2: 寄存器页面 ----------------
            RegisterControlPage {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }

    // ============================================================
    // Tab 1 实现: IO 页面
    // ============================================================
    component IOControlPage : Item {
        // 配置：默认监控的端口数量
        readonly property int diCount: 16
        readonly property int doCount: 16
        readonly property int aiCount: 4
        readonly property int aoCount: 4

        // 定时器：循环获取 IO 状态
        Timer {
            id: ioTimer
            interval: 500
            repeat: true
            onTriggered: refreshIO()
        }

        // 刷新逻辑：构造 GetIOValue 请求
        function refreshIO() {
            var dbList = []
            // 添加 DI
            for(var i=0; i<diCount; i++) dbList.push({"type": "DI", "port": i})
            // 添加 DO
            for(var j=0; j<doCount; j++) dbList.push({"type": "DO", "port": j})
            // 添加 AI
            for(var k=0; k<aiCount; k++) dbList.push({"type": "AI", "port": k})
            // 添加 AO
            for(var l=0; l<aoCount; l++) dbList.push({"type": "AO", "port": l})

            // 发送请求 (C++ 会自动处理 QVariantList -> JSON Array)
            RobotGlobal.sendJsonRequest("IOManager/GetIOValue", dbList)
        }

        // 写入逻辑：SetIOValue
        function setIO(type, port, val) {

            var finalVal = (type === "AO") ? parseFloat(val) : parseInt(val);

            var data = {
                "type": type,
                "port": port,
                "value": val
            }
            // 转为 JSON 字符串发送，确保格式绝对正确
            var jsonStr = JSON.stringify(data)


            console.log("写入IO (String):", jsonStr)
            // 发送请求 (C++ 会自动处理 QVariantMap -> JSON Object)
            // 为了兼容性，这里使用 JSON.stringify 转换为字符串发送，或者依赖 RobotClient 的 QVariantMap 支持
            // 建议直接发对象，依赖我们在 RobotClient.cpp 里加的 map 转换
            RobotGlobal.sendJsonRequest("IOManager/SetIOValue", jsonStr)
        }

        // 数据接收处理
        Connections {
            target: RobotGlobal
            function onRecvNormalMessage(msg) {
                if (msg.ty === "IOManager/GetIOValue") {
                    updateIOUI(msg.db)
                }
            }
        }

        function updateIOUI(dbArray) {
            if (!Array.isArray(dbArray)) return

            dbArray.forEach(function(item) {
                var port = item.port
                var val = item.value

                if (item.type === "DI") {
                    if(port < diRepeater.count) diRepeater.itemAt(port).isOn = (val === 1)
                } else if (item.type === "DO") {
                    if(port < doRepeater.count) doRepeater.itemAt(port).isOn = (val === 1)
                } else if (item.type === "AI") {
                    if(port < aiRepeater.count){
                        // 【修改】只保留3位小数
                        var displayAI = (typeof val === 'number') ? val.toFixed(3) : "--"
                        aiRepeater.itemAt(port).currentVal = displayAI
                    }
                } else if (item.type === "AO") {
                    if(port < aoRepeater.count){
                        // 【修改】只保留3位小数
                        var displayAO = (typeof val === 'number') ? val.toFixed(3) : "--"
                        aoRepeater.itemAt(port).currentVal = displayAO
                    }
                }
            })
        }

        // 界面布局
        ScrollView {
            id: scrollView
            anchors.fill: parent
            clip: true

            // 必须告诉 ScrollView 内容有多高，否则它可能渲染为 0
            contentHeight: mainCol.implicitHeight + 40
            contentWidth: parent.width - 20

            ColumnLayout {
                id: mainCol // 给个 id 方便引用
                // 防止水平滚动条出现
                width: parent.width - 20
                anchors.margins: 20
                anchors.top: parent.top
                anchors.left: parent.left
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                // 顶部控制栏
                ControlCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60 // 给固定高度
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15; spacing: 20
                        Text { text: "🔄 自动刷新:"; font.bold: true }
                        Switch {
                            checked: ioTimer.running
                            onCheckedChanged: ioTimer.running = checked
                        }

                        Rectangle { width: 1; height: 24; color: "#e5e7eb" } // 分割线

                        Text { text: "间隔(ms):"; color: "#6b7280" }
                        ComboBox {
                            model: ["100", "200", "500", "1000", "2000", "5000"]
                            currentIndex: 2 // 默认 500
                            Layout.preferredWidth: 100
                            onCurrentTextChanged: {
                                var ms = parseInt(currentText)
                                if(!isNaN(ms)) ioTimer.interval = ms
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "立即刷新"
                            onClicked: refreshIO()
                        }
                    }
                }

                // 数字量 IO 区域
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 20

                    // DI 面板
                    IOCard {
                        title: "📥 数字输入 (DI)"
                        color: "#dbeafe" // 浅蓝
                        Layout.fillWidth: true
                        // 两个卡片都设为 fillWidth: true，它们会自动平分
                        Layout.preferredWidth: 1 // 只要非0且相等即可平分

                        GridLayout {
                            columns: 4; columnSpacing: 10; rowSpacing: 10
                            Repeater {
                                id: diRepeater
                                model: diCount
                                delegate: DILight { index: model.index }
                            }
                        }
                    }

                    // DO 面板
                    IOCard {
                        title: "📤 数字输出 (DO)"
                        color: "#d1fae5" // 浅绿
                        Layout.fillWidth: true
                        // 两个卡片都设为 fillWidth: true，它们会自动平分
                        Layout.preferredWidth: 1 // 只要非0且相等即可平分

                        GridLayout {
                            columns: 4; columnSpacing: 10; rowSpacing: 10
                            Repeater {
                                id: doRepeater
                                model: doCount
                                delegate: DOSwitch {
                                    index: model.index
                                    onToggled: (p, v) => setIO("DO", p, v)
                                }
                            }
                        }
                    }
                }

                // 模拟量 IO 区域
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // AI 面板
                    IOCard {
                        title: "📈 模拟输入 (AI)"
                        color: "#fff7ed" // 浅橙
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 5
                            Repeater {
                                id: aiRepeater
                                model: aiCount
                                delegate: AIRow { index: model.index }
                            }
                        }
                    }

                    // AO 面板
                    IOCard {
                        title: "🎛️ 模拟输出 (AO)"
                        color: "#f3e8ff" // 浅紫
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 5
                            Repeater {
                                id: aoRepeater
                                model: aoCount
                                delegate: AORow {
                                    index: model.index
                                    onSetClicked: (p, v) => setIO("AO", p, v)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // Tab 2 实现: 寄存器页面
    // ============================================================
    component RegisterControlPage : Item {
        ListModel { id: regModel } // 存储监控的寄存器列表

        Timer {
            id: regTimer
            interval: 1000
            repeat: true
            onTriggered: refreshRegisters()
        }

        function refreshRegisters() {
            if (regModel.count === 0) return

            var addrList = []
            for(var i=0; i<regModel.count; i++) {
                addrList.push(regModel.get(i).address)
            }

            // 发送 [10000, 20000]
           // RobotClient.cpp 里的 canConvert<QVariantList> 会处理它
           console.log("请求寄存器:", JSON.stringify(addrList))
            RobotGlobal.sendJsonRequest("RegisterManager/GetRegisterValue", addrList)
        }

        function writeRegister(addr, val) {
            var data = {
                "address": addr,
                "value": parseFloat(val) // 寄存器通常是数字
            }
            var jsonMessage = JSON.stringify(data)
            console.log("写入寄存器:", jsonMessage)
            RobotGlobal.sendJsonRequest("RegisterManager/SetRegisterValue", jsonMessage)
        }

        Connections {
            target: RobotGlobal
            function onRecvNormalMessage(msg) {
                // 注意：文档里说响应可能是 IOManager/GetRegisterValue 或 RegisterManager/GetRegisterValue
                // 这里做模糊匹配
                if (msg.ty.includes("GetRegisterValue")) {
                    if (msg.db && Array.isArray(msg.db)) {
                        updateRegUI(msg.db)
                    }
                }
            }
        }

        function updateRegUI(db) {
            db.forEach(function(item) {
                // 在 model 中找到对应的 address 并更新 value
                for(var i=0; i<regModel.count; i++) {
                    if (regModel.get(i).address === item.address) {
                        regModel.setProperty(i, "currValue", String(item.value))
                        break;
                    }
                }
            })
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // 1. 控制卡片
            ControlCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 15

                    TextField {
                        id: inputAddr
                        placeholderText: "输入地址 (如 10001)"
                        Layout.preferredWidth: 150
                        validator: IntValidator { bottom: 0 }
                    }
                    Button {
                        text: "➕ 添加监控"
                        highlighted: true
                        onClicked: {
                            var addr = parseInt(inputAddr.text)
                            if (isNaN(addr)) return
                            // 查重
                            for(var i=0; i<regModel.count; i++) {
                                if(regModel.get(i).address === addr) return
                            }
                            regModel.append({ "address": addr, "currValue": "--" })
                            inputAddr.text = ""
                            refreshRegisters() // 立即刷新一次
                        }
                    }

                    Rectangle { width: 1; height: 30; color: "#e5e7eb" }

                    // 刷新控制区域
                    Switch {
                        text: "循环"
                        checked: regTimer.running
                        onCheckedChanged: regTimer.running = checked
                    }

                    ComboBox {
                        model: ["100", "200", "500", "1000", "2000", "5000"]
                        currentIndex: 2 // 默认 500
                        Layout.preferredWidth: 90
                        onCurrentTextChanged: {
                            var ms = parseInt(currentText)
                            if(!isNaN(ms)) regTimer.interval = ms
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "🗑️ 清空列表"
                        flat: true
                        onClicked: regModel.clear()
                    }
                }
            }

            // 2. 寄存器列表
            ControlCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    // 表头
                    RowLayout {
                        spacing: 10
                        Text { text: "地址 (Address)"; width: 120; font.bold: true; color: "#6b7280" }
                        Text { text: "当前值 (Value)"; width: 120; font.bold: true; color: "#6b7280" }
                        Text { text: "操作 (Write)"; Layout.fillWidth: true; font.bold: true; color: "#6b7280" }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb" }

                    ListView {
                        id: regList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: regModel
                        spacing: 5

                        delegate: Rectangle {
                            width: regList.width
                            height: 40
                            color: index % 2 === 0 ? "#f9fafb" : "white"
                            radius: 4

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    text: model.address
                                    width: 120
                                    font.family: "Consolas"; font.bold: true
                                    color: "#3b82f6"
                                }
                                Text {
                                    text: model.currValue
                                    width: 120
                                    font.family: "Consolas"
                                    color: "#374151"
                                }

                                // 写入操作区
                                TextField {
                                    id: writeVal
                                    placeholderText: "新值"
                                    Layout.preferredWidth: 80
                                    Layout.preferredHeight: 30
                                }
                                Button {
                                    text: "写入"
                                    Layout.preferredHeight: 30
                                    onClicked: writeRegister(model.address, writeVal.text)
                                }
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: "✖"
                                    flat: true
                                    onClicked: regModel.remove(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    // ============================================================
    // 公共组件封装
    // ============================================================

    // 卡片容器
    component ControlCard : Rectangle {
        color: "white"
        radius: 8
        layer.enabled: true
        layer.effect: DropShadow { transparentBorder: true; radius: 6; color: "#08000000"; verticalOffset: 2 }
    }

    // IO 分组卡片
    component IOCard : ControlCard {
        property string title
        property color color: "white"
        default property alias content: inner.data

        // 关键：设置隐式高度 = 标题栏 + 内容区高度 + 边距
        implicitHeight: headerRect.height + inner.implicitHeight + 20

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: headerRect
                Layout.fillWidth: true
                height: 36
                color: parent.parent.color
                radius: 8
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 8; color: parent.color }
                Text {
                    text: title; anchors.centerIn: parent
                    font.bold: true; color: "#374151"
                }
            }

            // 内容容器
            Item {
                id: inner
                Layout.fillWidth: true
                // 让 inner 的高度等于它子元素撑开的高度
                implicitHeight: childrenRect.height
                Layout.margins: 15
            }
        }
    }

    // DI 指示灯组件
    component DILight : Column {
        property int index
        property bool isOn: false
        spacing: 5
        Rectangle {
            width: 40; height: 40
            radius: 20
            color: isOn ? "#10b981" : "#e5e7eb" // 绿/灰
            border.color: isOn ? "#059669" : "#d1d5db"
            border.width: 2

            // 高光效果
            Rectangle {
                width: 12; height: 12; radius: 6
                x: 8; y: 8
                color: "white"; opacity: 0.3
            }
            Text {
                text: isOn ? "ON" : "OFF"
                anchors.centerIn: parent
                font.pixelSize: 10
                color: isOn ? "white" : "#6b7280"
                font.bold: true
            }
        }
        Text { text: "DI " + index; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // DO 开关组件
    component DOSwitch : Column {
        property int index
        property bool isOn: false
        signal toggled(int port, int value)
        spacing: 5

        // 模拟开关按钮
        Rectangle {
            width: 40; height: 40
            radius: 8
            color: isOn ? "#3b82f6" : "white"
            border.color: isOn ? "#2563eb" : "#d1d5db"
            border.width: 2

            Text {
                text: index
                anchors.centerIn: parent
                color: isOn ? "white" : "#6b7280"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: toggled(index, isOn ? 0 : 1)
            }
        }
        Text { text: "DO " + index; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // AI 显示行
    component AIRow : RowLayout {
        property int index
        property string currentVal: "--"
        spacing: 10
        Text {
            text: "AI " + index
            font.bold: true
            color: "#6b7280"
            // 给标签一个固定宽度，对齐更好看
            Layout.preferredWidth: 40
        }
        // 数值框自动填满剩余空间
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: "#f3f4f6"
            radius: 4
            Text {
                text: currentVal
                anchors.centerIn: parent
                font.family: "Consolas"
                color: "#d97706"
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // AO 控制行
    component AORow : RowLayout {
        property int index
        property string currentVal: "--"
        signal setClicked(int port, double val)
        spacing: 10

        Text {
            text: "AO " + index
            font.bold: true;
            color: "#6b7280"
            Layout.preferredWidth: 40
        }

        // 当前值显示
        Rectangle {
            Layout.preferredWidth: 60 // 固定宽度显示当前值
            Layout.preferredHeight: 28
            color: "#f3f4f6"
            radius: 4
            Text {
                text: currentVal
                anchors.centerIn: parent
                font.family: "Consolas"
                font.pixelSize: 12 // 显式设置小字体
                color: "#7c3aed" // 紫色
            }
        }

        // 输入与设置
        TextField {
            id: input
            Layout.preferredWidth: 60
            Layout.preferredHeight: 28
            placeholderText: "0.0"
            validator: DoubleValidator { decimals: 3 }

            font.pixelSize: 12
            verticalAlignment: TextInput.AlignVCenter
            leftPadding: 8

            // 样式微调
            background: Rectangle {
                color: input.activeFocus ? "white" : "#f9fafb"
                border.color: "#d1d5db"
                radius: 4
            }
        }
        Button {
            text: "SET"
            Layout.preferredHeight: 28
            Layout.preferredWidth: 40

            // 按钮样式
            background: Rectangle {
                color: parent.down ? "#6d28d9" : "#8b5cf6" // 深紫/紫
                radius: 4
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.bold: true
                font.pixelSize: 11
                anchors.centerIn: parent
            }

            onClicked: {
                var v = parseFloat(input.text)
                if (!isNaN(v)) {
                    setClicked(index, v)
                    // 可选：点击后清空输入框，或者保留以便微调
                    input.text = ""
                }
            }
        }
    }
}
