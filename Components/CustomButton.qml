/* CustomButton.qml */
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: buttonRoot
    radius: 8
    color: defaultColor

    // 外部可设置的属性
    property color defaultColor: "cyan"
    property color hoverColor: "#00b7eb"
    property color pressColor: "#0099c3"
    property color disabledColor: "#cccccc"        // 新增：禁用状态颜色
    property color textColor: "black"
    property color disabledTextColor: "#888888"    // 新增：禁用状态文字颜色
    property string buttonText: "按钮"
    property int fontSize: 12
    property int animationDuration: 150
    property real widthMultiplier: 1.5
    property real heightMultiplier: 1
    property int minWidth: 60
    property int minHeight: 40
    property int minPadding: 20
    property bool enabled: true                    // 新增：启用/禁用状态

    // 点击信号
    signal clicked()

    // 文字测量组件
    Text {
        id: textMetrics
        text: buttonText
        font.pixelSize: fontSize
        font.bold: true
        visible: false
    }

    // 根据文字内容和字体大小智能计算尺寸
    readonly property int textWidth: textMetrics.contentWidth
    readonly property int textHeight: textMetrics.contentHeight
    readonly property int calculatedWidth: Math.max(minWidth, Math.round(textWidth * widthMultiplier + minPadding))
    readonly property int calculatedHeight: Math.max(minHeight, Math.round(fontSize * heightMultiplier + minPadding))

    // 设置按钮尺寸
    width: calculatedWidth
    height: calculatedHeight
    implicitWidth: calculatedWidth
    implicitHeight: calculatedHeight

    // 显示的文字
    Text {
        id: displayText
        text: buttonText
        color: buttonRoot.enabled ? textColor : disabledTextColor
        font.pixelSize: fontSize
        font.bold: true
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    // 鼠标区域
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: buttonRoot.enabled  // 只在启用时启用悬停
        cursorShape: buttonRoot.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: buttonRoot.enabled  // 禁用状态下不可点击

        onClicked: {
            if (buttonRoot.enabled) {
                buttonRoot.clicked()
            }
        }
    }

    // 状态管理
    states: [
        State {
            name: "DISABLED"
            when: !buttonRoot.enabled
            PropertyChanges {
                target: buttonRoot
                color: disabledColor
                scale: 1.0
            }
            PropertyChanges {
                target: displayText
                color: disabledTextColor
            }
        },
        State {
            name: "HOVERED"
            when: buttonRoot.enabled && mouseArea.containsMouse && !mouseArea.pressed
            PropertyChanges {
                target: buttonRoot
                color: hoverColor
                scale: 1.02
            }
        },
        State {
            name: "PRESSED"
            when: buttonRoot.enabled && mouseArea.pressed
            PropertyChanges {
                target: buttonRoot
                color: pressColor
                scale: 0.98
            }
        },
        State {
            name: "NORMAL"
            when: buttonRoot.enabled && !mouseArea.containsMouse
            PropertyChanges {
                target: buttonRoot
                color: defaultColor
                scale: 1.0
            }
        }
    ]

    // 状态切换动画
    transitions: Transition {
        PropertyAnimation {
            properties: "color, scale"
            duration: animationDuration
            easing.type: Easing.OutCubic
        }
    }

    // 阴影效果（禁用状态下减弱阴影）
    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        radius: buttonRoot.enabled ? 8 : 4
        samples: 16
        color: buttonRoot.enabled ? "#40000000" : "#20000000"
        verticalOffset: buttonRoot.enabled ? 2 : 1
    }
}
