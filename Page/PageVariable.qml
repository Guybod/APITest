import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import MyRobot 1.0

Item {
    id: pageVar


    function showError(msg) {
            // console.error("[Error] " + msg)
            // 如果你的主界面有全局弹窗接口，请调用它
            // 如果没有，可以临时在这里加一个 MessageDialog
            errorDialog.text = msg
            errorDialog.open()
        }

    // 在 PageVariable 底部添加一个简单的弹窗
    Dialog {
        id: errorDialog
        property alias text: msgLabel.text
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok
        contentItem: Label { id: msgLabel; color: "red" }
    }






    // --- 配置常量 ---
    readonly property var reservedKeywords: [
        "and", "break", "do", "else", "elseif", "end","false", "for", "function", "goto", "if",
        "in","local", "nil", "not", "or", "repeat", "return","then", "true", "until", "while",
        "table", "math","DO", "DOGroup", "DIO", "DIOGroup", "AO", "AIO","ModbusTCP","setSpeedJ",
        "setAccJ", "setSpeedL", "setAccL", "setBlender","setMoveRate","getCoor", "getTool", "setCoor",
        "editCoor", "setTool", "editTool","setPayload","enableVibrationSuppression", "disableVibrationSuppression",
        "setCollisionDetectionSensitivity","initComplianceControl", "enableComplianceControl","disableComplianceControl",
        "forceControlZeroCalibrate", "setFilterPeriod","searchSuccessed","getJoint", "getTCP", "getCoor", "getTool",
        "aposToCpos","cposToApos", "cposToCpos","posOffset", "posTrans", "coorRel", "toolRel", "getJointTorque",
        "getJointExternalTorque","createTray", "getTrayPos", "posInverse", "distance", "interPos","planeTrans",
        "getTrajStart", "getTrajEnd", "arrayAdd", "arraySub","coorTrans","movJ", "movL", "movC", "movCircle",
        "movLW", "movCW", "movTraj","setWeave", "weaveStart", "weaveEnd","setDO", "getDI", "getDO", "setDOGroup",
        "getDIGroup","getDOGroup", "setAO", "getAI", "getAO","getRegisterBool", "setRegisterBool", "getRegisterInt",
        "setRegisterInt", "getRegisterFloat", "setRegisterFloat","RS485init", "RS485flush", "RS485write", "RS485read",
        "readCoils", "readDiscreteInputs", "readHoldingRegisters","readInputRegisters","writeSingleCoil", "writeSingleRegister",
        "writeMultipleCoils","writeMultipleRegisters","createSocketClient", "connectSocketClient", "writeSocketClient",
        "readSocketClient", "closeSocketClient","wait", "waitCondition", "systemTime", "stopProject","pauseProject",
        "runScript", "pauseScript", "resumeScript","stopScript", "callModule", "print","setInterruptInterval",
        "setInterruptCondition","clearInterrupt","strcmp", "strToNumberArray", "arrayToStr","enableMultiWeld",
        "getCurSeam", "isMultiWeldFinished","setMultiWeldOffset", "weldNextSeam", "resetMultiWeld","searchStart",
        "setMasterFlag", "getOffsetValue", "search","searchEnd", "searchOffset", "searchOffsetEnd", "searchError"
    ]

    // --- 数据模型 ---
    ListModel { id: globalVarModel }
    ListModel { id: projectVarModel }

    // --- 定时器 ---
    Timer {
        id: globalTimer
        interval: parseInt(intervalCombo.currentValue)
        repeat: true
        onTriggered: RobotGlobal.sendJsonRequest("globalVar/getVars")
    }

    Timer {
        id: projectTimer
        interval: parseInt(intervalCombo.currentValue)
        repeat: true
        onTriggered: RobotGlobal.sendJsonRequest("globalVar/GetProjectVarUpdate")
    }

    // --- 信号监听 ---
    Connections {
        target: RobotGlobal
        function onRecvNormalMessage(msg) {
            // 1. 获取全局变量回调
            if (msg.ty === "globalVar/getVars") {
                updateGlobalTable(msg.db)
            }
            // 2. 获取工程变量回调
            else if (msg.ty === "globalVar/GetProjectVarUpdate") {
                updateProjectTable(msg.db)
            }
            // 3. 保存/删除成功回调
            else if (msg.ty === "globalVar/saveVars" || msg.ty === "globalVar/removeVars") {
                // 操作成功后，立即刷新一次列表
                RobotGlobal.sendJsonRequest("globalVar/getVars")
            }
        }
    }

    // --- 逻辑函数 ---
    function validateName(name) {
        if (!name) return qsTr("变量名不能为空")
        // 检查首字符 (字母或下划线)
        if (!/^[a-zA-Z_]/.test(name)) return qsTr("变量名必须以字母或下划线开头")
        // 检查双下划线
        if (/^__/.test(name)) return qsTr("变量名不能以双下划线开头")
        // 检查非法字符
        if (!/^\w+$/.test(name)) return qsTr("变量名包含非法字符")
        // 检查保留字
        if (reservedKeywords.includes(name)) return qsTr("不能使用系统保留关键字")
        return "" // 通过
    }

    function saveVariable() {
        var name = inputName.text.trim()
        var val = inputVal.text.trim()
        var note = inputNote.text.trim()

        // 校验
        var err = validateName(name)
        if (err) {
            showError(err)
            return
        }
        if (!val) {
            showError(qsTr("变量值不能为空"))
            return
        }

        var errq = validateName(name)
        if (errq) { showError(errq); return; }
        if (!val) { showError(qsTr("变量值不能为空")); return; }

        var dbObj = {}
        var varData = { "val": val }

        // 如果备注不为空，才加进去 (虽然 NetAssist 测出来空也能过，但严谨点好)
        if (note !== "") {
            varData["nm"] = note
        } else {
             varData["nm"] = "" // 既然 NetAssist 能过，那就发空串，不要发空格
        }

        dbObj[name] = varData

        // 【修改】使用 JSON.stringify 转成字符串发送
        // 这样会进入 C++ 的 QString 分支，然后被还原成 JSON 对象
        var jsonString = JSON.stringify(dbObj)
        // console.log("发送保存请求:", JSON.stringify(dbObj))
        RobotGlobal.sendJsonRequest("globalVar/saveVars", jsonString)
    }

    // 辅助函数
    function isNumeric(str) {
        if (typeof str != "string") return false
        return !isNaN(str) &&
               !isNaN(parseFloat(str))
    }


    function deleteVariable() {
        var name = inputName.text.trim()
        if (!name) {
            showError("请在变量名输入框填写要删除的变量名称")
            return
        }

        // console.log("发送删除请求:", name)

        // 注意：第二个参数必须是数组
        // 这里的 db 是 ["varName"]
        RobotGlobal.sendJsonRequest("globalVar/removeVars", [name])
    }

    function updateGlobalTable(db) {
        // 简单的 Diff 更新或全量重置，这里用全量重置保证一致性
        // 生产环境可用 Diff 算法优化性能
        globalVarModel.clear()
        if (!db) return

        for (var key in db) {
            var item = db[key]
            globalVarModel.append({
                "key": key,
                "value": String(item.val),
                "note": String(item.nm || "")
            })
        }
    }

    function updateProjectTable(db) {
        projectVarModel.clear()
        if (!db) return

        for (var key in db) {
            var item = db[key]
            var displayVal = ""

            // 工程变量可能是复杂对象（如点位）
            if (typeof item === 'object') {
                displayVal = JSON.stringify(item)
            } else {
                displayVal = String(item)
            }

            projectVarModel.append({
                "key": key,
                "value": displayVal
            })
        }
    }

    // --- 界面布局 ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // ============================================================
        // 第一行：添加/保存变量
        // ============================================================
        ControlCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                InputGroup {
                    id: inputName
                    label: "变量名 (Key)"
                    placeholder: "e.g. v_speed"
                    Layout.preferredWidth: 200
                }

                InputGroup {
                    id: inputVal
                    label: "变量值 (Value)"
                    placeholder: "100 或 \"abc\""
                    Layout.fillWidth: true
                }

                InputGroup {
                    id: inputNote
                    label: "备注 (Note)"
                    placeholder: "可选"
                    Layout.preferredWidth: 200
                }

                Button {
                    text: qsTr("💾 保存/修改")
                    Layout.alignment: Qt.AlignBottom
                    Layout.preferredHeight: 36
                    background: Rectangle {
                        color: parent.down ? "#047857" : "#059669"
                        radius: 6
                    }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; anchors.centerIn: parent }
                    onClicked: saveVariable()
                }
            }
        }

        // ============================================================
        // 第二行：删除变量
        // ============================================================
        ControlCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 60

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                spacing: 10

                Text { text: "🗑️ 危险操作:"; color: "#dc2626"; font.bold: true }

                Button {
                    text: qsTr("删除当前变量名对应的变量")
                    background: Rectangle {
                        color: parent.down ? "#991b1b" : "#dc2626"
                        radius: 6
                    }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; anchors.centerIn: parent }
                    onClicked: deleteVariable()
                }

                Text {
                    text: "(将删除上方 '变量名' 输入框中指定的变量)"
                    color: "#6b7280"
                    font.pixelSize: 12
                }
            }
        }

        // ============================================================
        // 第三行：获取控制与循环设置
        // ============================================================
        ControlCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 70

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 20

                // 1. 全局变量控制
                RowLayout {
                    spacing: 10
                    Button {
                        text: qsTr("获取全局变量")
                        onClicked: RobotGlobal.sendJsonRequest("globalVar/getVars")
                    }
                    Switch {
                        text: qsTr("循环")
                        checked: globalTimer.running
                        onCheckedChanged: globalTimer.running = checked
                    }
                }

                Rectangle { width: 1; height: 30; color: "#e5e7eb" }

                // 2. 工程变量控制
                RowLayout {
                    spacing: 10
                    Button {
                        text: qsTr("获取工程变量")
                        onClicked: RobotGlobal.sendJsonRequest("globalVar/GetProjectVarUpdate")
                    }
                    Switch {
                        text: qsTr("循环")
                        checked: projectTimer.running
                        onCheckedChanged: projectTimer.running = checked
                    }
                }

                Item { Layout.fillWidth: true } // 弹簧

                // 3. 频率设置
                RowLayout {
                    spacing: 10
                    Text { text: "刷新间隔 (ms):"; color: "#374151" }
                    ComboBox {
                        id: intervalCombo
                        model: ["100", "200", "500", "1000", "2000", "5000"]
                        currentIndex: 3 // 默认 1000
                        Layout.preferredWidth: 100
                    }
                }
            }
        }

        // ============================================================
        // 第四行：数据显示表格
        // ============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            // 左侧：全局变量表格
            VarTableCard {
                title: "🌍 全局变量列表"
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: globalVarModel
                // 选中行时自动填入上方输入框
                onRowClicked: (key, val, note) => {
                    inputName.text = key
                    inputVal.text = val
                    inputNote.text = note
                }
            }

            // 右侧：工程变量表格
            VarTableCard {
                title: "🏗️ 工程变量列表 (运行时有效)"
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: projectVarModel
                isProject: true
            }
        }
    }

    // ============================================================
    // 组件封装
    // ============================================================

    // 1. 白色圆角卡片容器
    component ControlCard : Rectangle {
        color: "white"
        radius: 8
        border.color: "#e5e7eb"
        border.width: 1
        layer.enabled: true
        layer.effect: DropShadow { transparentBorder: true; radius: 6; color: "#08000000"; verticalOffset: 2 }
    }

    // 2. 带Label的输入框
    component InputGroup : Column {
        property alias text: field.text
        property alias placeholder: field.placeholderText
        property string label
        spacing: 4

        Text { text: label; color: "#4b5563"; font.pixelSize: 12; font.bold: true }
        TextField {
            id: field
            width: parent.width
            height: 36
            background: Rectangle {
                radius: 4; border.color: field.activeFocus ? "#3b82f6" : "#d1d5db"
            }
        }
    }

    // 3. 变量表格卡片
    component VarTableCard : ControlCard {
        property string title
        property alias model: listView.model
        property bool isProject: false
        signal rowClicked(string key, string val, string note)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            // 标题
            Text { text: title; font.bold: true; color: "#374151"; font.pixelSize: 14 }

            // 表头
            Rectangle {
                Layout.fillWidth: true; height: 30; color: "#f3f4f6"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: "变量名 (Name)"; width: 150; font.bold: true; color: "#6b7280" }
                    Text { text: "值 (Value)"; Layout.fillWidth: true; font.bold: true; color: "#6b7280" }
                    Text { text: "备注"; width: 100; font.bold: true; color: "#6b7280"; visible: !isProject }
                }
            }

            // 列表
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                delegate: Rectangle {
                    width: listView.width
                    height: 40
                    color: index % 2 === 0 ? "white" : "#f9fafb"

                    // 选中高亮
                    Rectangle {
                        anchors.fill: parent
                        color: "#eff6ff"
                        visible: ma.containsMouse || listView.currentIndex === index
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: model.key
                            width: 150
                            elide: Text.ElideRight
                            font.bold: true
                            color: "#2563eb"
                        }
                        Text {
                            text: model.value
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.family: "Consolas"
                            color: "#374151"
                        }
                        Text {
                            text: model.note || "-"
                            width: 100
                            elide: Text.ElideRight
                            color: "#6b7280"
                            visible: !isProject
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            listView.currentIndex = index
                            // 触发点击信号，填充输入框
                            if (!isProject) {
                                rowClicked(model.key, model.value, model.note)
                            }
                        }
                    }
                }
            }
        }
    }
}
