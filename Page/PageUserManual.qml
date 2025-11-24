import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import MyRobot 1.0
Item {
    id: pageManual

    // ------------------------------------------------------------------
    // 数据模型 (在此处添加/修改手册)
    // ------------------------------------------------------------------

    // 在线手册数据
    ListModel {
        id: onlineDocsModel
        ListElement {
            title: "资料包下载";
            desc: "API 接口完整说明与示例代码";
            icon: "🌐";
            url: "https://drive.weixin.qq.com/s?k=AKIAGgfyAHQVKKmFtN"
        }
        ListElement {
            title: "API文档";
            desc: "API 接口完整说明与示例代码";
            icon: "🌐";
            url: "https://www.kdocs.cn/l/cqlm2DOsjGRp"
        }
        ListElement {
            title: "Lua 脚本指南";
            desc: "Lua脚本编程语法参考";
            icon: "📜";
            url: "https://www.lua.org/manual/5.3/"
        }
        ListElement {
            title: "机器人脚本指南";
            desc: "机器人脚本编程语法参考";
            icon: "📜";
            url: "https://www.kdocs.cn/l/cqkkkry8u4Tg"
        }
        ListElement {
            title: "SDK 下载 (Gitee)";
            desc: "国内高速镜像源";
            icon: "🔴"; // 代表 Gitee 红色
            url: "https://gitee.com/guy-bod/CodroidApi"
        }
        ListElement {
            title: "SDK 下载 (GitHub)";
            desc: "全球主仓库";
            icon: "🐱"; // 代表 GitHub 章鱼猫
            url: "https://github.com/Guybod/CodroidApi.git"
        }
        ListElement {
            title: "常见问题 (FAQ)";
            desc: "故障排除与解决方案";
            icon: "❓";
            url: "https://www.codroidrobotics.com/support"
        }
    }

    // 本地手册数据 (文件名需对应 resources 目录下的文件)
    ListModel {
        id: localDocsModel
    }

    // ------------------------------------------------------------------
    // 逻辑处理
    // ------------------------------------------------------------------
    function openDoc(type, target) {
        if (type === "online") {
            Qt.openUrlExternally(target)
        }
        else if (type === "local") {
            // 1. 获取 C++ 提供的绝对路径 (结果类似 "D:/Qt/Tool/build/...")
            var appDir = RobotGlobal.getAppDir()

            // 2. 拼接完整路径
            var fullPath = "file:///" + appDir + "/resources/" + target

            // console.log("尝试打开本地文件:", fullPath)

            // 3. 打开
            Qt.openUrlExternally(fullPath)
        }
    }

    // ------------------------------------------------------------------
    // 界面布局
    // ------------------------------------------------------------------
    ScrollView {
        anchors.fill: parent
        clip: true
        // 增加底部 padding 防止遮挡
        contentHeight: mainCol.implicitHeight + 40
        contentWidth: parent.width - 20

        ColumnLayout {
            id: mainCol
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 40

            // ============================================================
            // 区域 1: 在线资源库
            // ============================================================
            SectionGroup {
                title: "☁️ 在线资源库 (Online Resources)"
                model: onlineDocsModel
                isLocal: false
                Layout.leftMargin: 40
                Layout.rightMargin: 40
            }

            // ============================================================
            // 区域 2: 本地技术手册
            // ============================================================
            SectionGroup {
                title: "📂 本地技术手册 (Local Manuals)"
                model: localDocsModel
                isLocal: true
                Layout.leftMargin: 40
                Layout.rightMargin: 40
            }
        }
    }

    // ------------------------------------------------------------------
    // 组件封装
    // ------------------------------------------------------------------

    // 文档区域分组组件
    component SectionGroup : ColumnLayout {
        property string title
        property alias model: grid.model
        property bool isLocal: false

        spacing: 20
        Layout.fillWidth: true

        // 标题
        Text {
            text: title
            font.bold: true
            font.pixelSize: 18
            color: "#374151"
        }

        // 网格布局 (卡片容器)
        GridView {
            id: grid
            Layout.fillWidth: true
            // 动态计算高度：行数 * (卡片高 + 间距)
            // 这里的 80 是卡片高度，15 是间距，220 是卡片宽度
            property int cols: Math.floor(width / 235)
            property int rows: Math.ceil(model.count / Math.max(1, cols))
            Layout.preferredHeight: rows * 95

            cellWidth: 235
            cellHeight: 95
            interactive: false // 禁止内部滚动，由外部 ScrollView 负责

            delegate: DocCard {
                docTitle: model.title
                docDesc: model.desc
                docIcon: model.icon

                onClicked: {
                    if (isLocal) openDoc("local", model.fileName)
                    else openDoc("online", model.url)
                }
            }
        }
    }

    // 文档卡片组件
    component DocCard : Item {
        property string docTitle
        property string docDesc
        property string docIcon
        signal clicked()

        width: 220
        height: 80

        // 卡片背景
        Rectangle {
            id: bg
            anchors.fill: parent
            color: "white"
            radius: 8

            // 阴影和边框
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true; radius: 8; samples: 16; color: "#10000000"; verticalOffset: 3
            }
            border.width: mouseArea.containsMouse ? 1 : 0
            border.color: "#3b82f6" // 悬停时显示蓝色边框

            // 悬停动画
            scale: mouseArea.containsMouse ? 1.02 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                // 图标背景
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: mouseArea.containsMouse ? "#eff6ff" : "#f3f4f6"
                    Text {
                        text: docIcon
                        anchors.centerIn: parent
                        font.pixelSize: 20
                    }
                }

                // 文本信息
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: docTitle
                        font.bold: true
                        color: mouseArea.containsMouse ? "#2563eb" : "#374151"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: docDesc
                        color: "#9ca3af"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.parent.clicked()
            }
        }
    }
}
