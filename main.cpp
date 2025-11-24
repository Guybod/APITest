#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QImage>
#include <QIcon> // 引入头文件
#include "./src/RobotClient.h" // 包含头文件
#include "./src/SerialClient.h"

int main(int argc, char *argv[])
{
    // 【关键】强制使用 Basic 风格，这样就可以随便改背景色和圆角了
    QQuickStyle::setStyle("Basic");

    QGuiApplication app(argc, argv);

    QImage img(":/estun.png"); // 假设你原来的图其实是 png
    if (!img.isNull()) {
        img.save("real_icon.ico", "ICO"); // Qt 支持保存为 ICO
    }

    // 注意：路径前的冒号 ':' 等同于 "qrc:/"
    app.setWindowIcon(QIcon(":/estun.ico"));

    // 1. 在 C++ 中手动实例化 RobotClient
    // 让它属于 app 对象，这样程序结束时自动销毁
    RobotClient *robotClient = new RobotClient(&app);

    // 2. 将这个实例注册为 QML 单例
    // 这样在 QML 任何地方都可以直接通过 "RobotGlobal" 访问它，不需要再实例化
    qmlRegisterSingletonInstance("MyRobot", 1, 0, "RobotGlobal", robotClient);


    SerialClient *serialClient = new SerialClient(&app);
    qmlRegisterSingletonInstance("MyRobot", 1, 0, "SerialGlobal", serialClient);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("CodroidAPITestTool", "Main");

    return app.exec();
}
