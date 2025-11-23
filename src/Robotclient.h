#ifndef ROBOTCLIENT_H
#define ROBOTCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QNetworkProxy>

// [新增] 引入文件处理相关的头文件
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QMutex>
#include <QCoreApplication>

// 机器人客户端类
class RobotClient : public QObject{

    Q_OBJECT // 这是一个宏，属于Qt，必须加上，才能使用信号与槽


    // 暴露机器人的关键状态给 QML，方便 UI 绑定
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStatusChanged)
    Q_PROPERTY(int robotState READ robotState NOTIFY robotStateChanged) // 0=未使能, 4=RunTo等
    // 【新增】暴露 connectionStateString 给 QML
    // CONSTANT 表示这个值只读且不会发出变更信号（或者你可以复用 connectionStatusChanged 信号）
    Q_PROPERTY(QString connectionStateString READ connectionStateString NOTIFY connectionStatusChanged)

// 公有方法
public:

    // Qt 标准构造函数写法 需要传入父类指针，如果没有，则为空指针
    explicit RobotClient(QObject *parent = nullptr);
    // 机器人客户端类析构函数
    ~RobotClient();

    // 是否连接
    bool isConnected() const;

    // 是否处于连接状态
    bool isConnecting() const;

    // 当前连接状态
    QString connectionStateString() const;

    // 缓存机器人状态
    int robotState() const;

    // 如果想让函数在QML可调用，要么用Q_INVOKABLE，要么标记为槽函数
    // --- 给 QML 调用的接口  ---

    // 获取应用程序运行目录
    Q_INVOKABLE QString getAppDir();

    // 连接机器人
    Q_INVOKABLE void connectToRobot(const QString &host,int port);

    // 断开连接
    Q_INVOKABLE void disconnectFromRobot();

    // 发送Json
    Q_INVOKABLE void sendJsonRequest(const QString &type, const QVariant  &data = QVariant ());

    // 发送String
    Q_INVOKABLE void sendStringRequest(const QString &message);

    //发送 RunTo 指令 调用此函数后，会自动启动 500ms 的心跳定时器 targetJson 可选的目标位置 JSON 对象 (对于 Home/Safe 可传空)
    Q_INVOKABLE void sendRunTo(int moveType, const QJsonObject &targetJson = QJsonObject());

    // 手动订阅主题
    Q_INVOKABLE void subscribeTopic(const QString &topic);


// --- 通知 QML 的信号  ---
signals:

    // 连接状态改变(附加参数 布尔两：是否连接)
    void connectionStatusChanged(bool isConnected);

    // 状态改变信号
    void robotStateChanged(int state);

    // 开始连接
    void connectionStarted(const QString &ip, int port);

    // 已连接
    void connected();

    // 连接失败
    void connectionFailed(const QString &error);

    //断开连接
    void disconnected();

    // 接收到正常的Json数据，传给 QML
    void recvNormalMessage(const QJsonObject &NormalMessage);

    // 接收到工程状态Json数据，传给 QML
    void recvProjectStateMessage(const QJsonObject &ProjectStateMessage);

    // 接收到变量更新Json数据，传给 QML
    void recvVarUpdateMessage(const QJsonObject &VarUpdateMessage);

    // 接收到机器人状态Json数据，传给 QML
    void recvRobotStatusMessage(const QJsonObject &RobotStatusMessage);

    // 接收到机器人位姿Json数据，传给 QML
    void recvRobotPostureMessage(const QJsonObject &RobotPostureMessage);

    // 接收到机器人坐标系Json数据，传给 QML
    void recvRobotCoordinateMessage(const QJsonObject &RobotCoordinateMessage);

    // 接收到LogJson数据，传给 QML
    void recvLogMessage(const QJsonObject &LogMessage);

    // 接收到ErrosJson数据，传给 QML
    void recvErrorMessage(const QJsonObject &ErrorMessage);

    // 接收到心跳，传给 QML
    void recvMoveToHeartbeatMessage();

    // 解析异常
    void jsonParseError(const QString &errorMessage);

    // 日志
    void logGenerated(const QString &log);

// --- C++ 内部逻辑 QML 无法调用 ---
private slots:

    // 当 TCP Socket 有数据来了，自动执行
    void onReadyRead();

    // 当Socket状态改变，自动执行
    void onSocketStateChanged(QAbstractSocket::SocketState socketState);

    // 当 TCP Socket 报错了，自动执行
    void onErrorOccurred(QAbstractSocket::SocketError socketError);

    // 定时器槽函数：发送心跳
    void onHeartbeatTimer();

    void onConnected();

    void onDisconnected();

    // 机器人状态解析
    void onhandleRobotStatus(const QJsonObject &db);

// 私有成员
private:
    // socket对象
    QTcpSocket *m_socket;

    // 用于维持 RunTo 的心跳定时器
    QTimer *m_heartbeatTimer;

    // 缓存当前机器人状态
    int m_currentRobotState = -1;

    // 自增请求 ID
    int m_requestId = 0;

    // // 写入日志
    void writeLog(const QString &msg);// 修改原有的 writeLog

    // 全部订阅
    void subscribeAll();

    // 用于处理 TCP 粘包/半包的缓冲区
    QByteArray m_buffer;

    // [新增] 接收缓冲区，用于处理粘包和半包
    QByteArray m_receiveBuffer;

    // [新增] 非RunTo状态计数器，用于心跳逻辑
    int m_nonRunToStateCount = 0;

    // [新增] 内部函数：处理单条解析好的JSON，将onReadyRead逻辑剥离
    void processOneMessage(const QJsonObject &root);

    // [新增] 日志系统相关成员
    QString m_logFilePath; // 当前使用的日志文件路径
    QMutex m_logMutex;     // 互斥锁，保证多线程写入安全

    // [新增] 内部函数
    void initLogSystem();  // 初始化日志系统（创建文件夹、清理旧文件、确定文件名）


};
#endif // ROBOTCLIENT_H
