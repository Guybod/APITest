#include "RobotClient.h"

// 构造函数实现
// 冒号(:)后面是“成员初始化列表”，这比在大括号里写赋值语句效率更高
RobotClient::RobotClient(QObject *parent)
    : QObject(parent)                  // 1. 先初始化基类 QObject，确立对象树关系，(parent代表实例化时需传入父类，否则为顶级对象)
    , m_socket(new QTcpSocket(this))   // 2. 实例化 Socket，传入 this 将其挂载到本对象下，随本对象自动销毁
    , m_heartbeatTimer(new QTimer(this)) // 3. 实例化定时器，同样指定 this 为父对象，无需手动 delete}
{
    // 设置心跳间隔 500ms
    m_heartbeatTimer->setInterval(500);

    // 连接定时器超时信号 -> 发送心跳包
    connect(m_heartbeatTimer, &QTimer::timeout, this, &RobotClient::onHeartbeatTimer);

    // 连接readyRead信号 -> 调用onReadyRead()函数
    connect(m_socket, &QTcpSocket::readyRead, this, &RobotClient::onReadyRead);

    // 连接stateChanged信号 -> 调用onSocketStateChanged()函数
    connect(m_socket, &QTcpSocket::stateChanged, this, &RobotClient::onSocketStateChanged);

    // Socket 状态与错误
    connect(m_socket, &QTcpSocket::connected, this, &RobotClient::onConnected);

    connect(m_socket, &QTcpSocket::disconnected, this, &RobotClient::onDisconnected);

    connect(m_socket, &QTcpSocket::errorOccurred, this, &RobotClient::onErrorOccurred);

    // 连接stateChanged信号 -> 调用onSocketStateChanged()函数
    connect(this, &RobotClient::recvRobotStatusMessage, this, &RobotClient::onhandleRobotStatus);

    // [新增] 初始化日志系统
    initLogSystem();

    // 连接 bytesWritten 信号，确认数据真的发出去了
    // connect(m_socket, &QTcpSocket::bytesWritten, this, [](qint64 bytes){
    //             qDebug() << "[系统] 成功向网络层写入字节数:" << bytes;
    //         });

    // connect(this, &RobotClient::connectionStarted, this, [](const QString &ip, int port) {
    //     qDebug() << "开始连接:" << ip << ":" << port;
    // });

    // connect(this, &RobotClient::connected, this, [] {
    //     qDebug() << "连接成功，可以开始发送指令";
    // });

    // connect(this, &RobotClient::connectionFailed, this, [](const QString &error) {
    //     qDebug() << "连接失败:" << error;
    //     // 可以显示错误对话框或重试逻辑
    // });

    // connect(this, &RobotClient::disconnected, this, [] {
    //     qDebug() << "连接断开";
    // });
    writeLog(QString("RobotClient初始化完成"));
}

//析构函数
RobotClient::~RobotClient()
{
    // 停止定时器
    m_heartbeatTimer->stop();

    // 先断开所有连接，避免信号触发
    m_socket->disconnect();

    // 然后关闭socket
    if (m_socket->state() != QAbstractSocket::UnconnectedState) {
        m_socket->abort();  // 立即中止
    }
    writeLog(QString("RobotClien销毁完成"));
}

// 是否连接
bool RobotClient::isConnected() const
{
    return m_socket->state() == QAbstractSocket::ConnectedState;
}

// 是否处于连接状态
bool RobotClient::isConnecting() const
{
    return m_socket->state() == QAbstractSocket::ConnectingState;
}

// 当前连接状态
QString RobotClient::connectionStateString() const
{
    switch (m_socket->state()) {
    case QAbstractSocket::UnconnectedState: return "未连接";
    case QAbstractSocket::HostLookupState: return "查找主机";
    case QAbstractSocket::ConnectingState: return "连接中";
    case QAbstractSocket::ConnectedState: return "已连接";
    case QAbstractSocket::ClosingState: return "关闭中";
    default: return "未知状态";
    }
}

// 查询机器人状态
int RobotClient::robotState() const {
    return m_currentRobotState;
}

QString RobotClient::getAppDir()
{
    // 返回可执行文件所在的目录路径 (例如 D:/Qt/Tool/build/.../Debug)
    return QCoreApplication::applicationDirPath();
}

//  连接服务器
void RobotClient::connectToRobot(const QString &host, int port){
    if (isConnected()) {
        // writeLog("机器人已经连接");
        return;
    }

    // 检查是否正在连接中
    if (m_socket->state() == QAbstractSocket::ConnectingState) {
        // writeLog("正在连接中，请等待...");
        return;
    }

    // writeLog(QString("正在连接机器人: %1:%2").arg(host).arg(port));
    emit connectionStarted(host, port);

    // [新增] 强制禁用代理，忽略系统VPN或代理设置，使用直连
    // 解决 "对于这个操作代理类型是无效的" 错误
    m_socket->setProxy(QNetworkProxy::NoProxy);

    // [新增] 连接前清空缓冲区，防止上次残留数据干扰
    m_receiveBuffer.clear();

    m_socket->connectToHost(host, port);
}

//  断开连接
void RobotClient::disconnectFromRobot()
{
    m_socket->disconnectFromHost();
    m_socket->close();
}

// 发送Json数据
void RobotClient::sendJsonRequest(const QString &type, const QVariant &data)
{
    if(!isConnected()) return;

    QJsonObject root;
    root["id"] = QString::number(++m_requestId);
    root["ty"] = type;

    if (data.isNull()) {
        root["db"] = QJsonValue::Null;
    }
    // 处理整数
    else if (data.typeId() == QMetaType::Int || data.typeId() == QMetaType::LongLong || data.typeId() == QMetaType::UInt) {
        root["db"] = data.toLongLong();
    }
    // 处理浮点数
    else if (data.typeId() == QMetaType::Double || data.typeId() == QMetaType::Float) {
        root["db"] = data.toDouble();
    }
    // 处理 JSON 对象
    else if (data.typeId() == QMetaType::QJsonObject) {
        root["db"] = data.toJsonObject();
    }
    // 处理 JSON 数组
    else if (data.typeId() == QMetaType::QJsonArray) {
        root["db"] = data.toJsonArray();
    }
    // ----------------------------------------------------------------------
    // 【关键修改】优先处理字符串，尝试解析 JSON
    // ----------------------------------------------------------------------
    else if (data.typeId() == QMetaType::QString) {
        QString strData = data.toString();

        // 尝试将字符串解析为 JSON 对象或数组
        QJsonParseError err;
        QJsonDocument subDoc = QJsonDocument::fromJson(strData.toUtf8(), &err);

        if (err.error == QJsonParseError::NoError) {
            if (subDoc.isObject()) {
                root["db"] = subDoc.object();
                // writeLog("[DEBUG] 字符串成功解析为 JSON 对象");
            }
            else if (subDoc.isArray()) {
                root["db"] = subDoc.array();
                // writeLog("[DEBUG] 字符串成功解析为 JSON 数组");
            }
            else {
                root["db"] = strData;
            }
        } else {
            // 解析失败，说明是普通字符串
            root["db"] = strData;
        }
    }
    // 【新增】处理 QML 传过来的数组 (QVariantList) -> 转为 QJsonArray
    else if (data.canConvert<QVariantList>()) {
        root["db"] = QJsonArray::fromVariantList(data.toList());
    }
    // 【新增】处理 QML 传过来的对象 (QVariantMap) -> 转为 QJsonObject
    else if (data.canConvert<QVariantMap>()) {

        QJsonObject dbObj = QJsonObject::fromVariantMap(data.toMap());
        root["db"] = dbObj;
        // 【调试日志】看看转出来的 JSON 对不对
        // writeLog("C++ QVariantMap 转换结果:" + QJsonDocument(dbObj).toJson(QJsonDocument::Compact));
    }
    // 其他情况（字符串等）
    else {
        root["db"] = QJsonValue::fromVariant(data);
    }

    QJsonDocument doc(root);
    m_socket->write(doc.toJson(QJsonDocument::Compact));

    if(type != "Robot/moveToHeartbeat") {
        writeLog("发送: " + doc.toJson(QJsonDocument::Compact));
    }
}

void RobotClient::sendStringRequest(const QString &message)
{
    // 1. 检查连接状态
    if (!isConnected()) {
        writeLog("发送失败: 未连接");
        return;
    }

    // 2. 判空（可选，看你需求是否允许发空串）
    if (message.isEmpty()) {
        writeLog("发送忽略: 消息为空");
        return;
    }

    // 3. 将 QString 转换为 UTF-8 编码的字节流
    // 网络传输通常标准为 UTF-8
    QByteArray data = message.toUtf8();

    // 4. 写入 Socket
    qint64 bytesWritten = m_socket->write(data);

    // 【建议新增】强制刷新缓冲区，确保数据立刻发出去，而不是停在内存里
    m_socket->flush();

    // 5. 记录日志或处理错误
    if (bytesWritten == -1) {
        writeLog(QString("发送出错: %1").arg(m_socket->errorString()));
    } else {
        // 只有非心跳包才打印日志，避免刷屏
        // 这里假设发送字符串肯定不是心跳，直接打印
        writeLog(QString("发送原始字符串: %1").arg(message));
    }

    // 如果你的协议需要立即刷新缓冲区，可以调用 flush，
    // 但通常 Qt 会自动处理，不需要手动调用
    // m_socket->flush();
}

// 发送RunTo
void RobotClient::sendRunTo(int moveType, const QJsonObject &targetJson)
{
    if (!isConnected()) {
        writeLog("发送失败: 未连接");
        return;
    }

    // 1. 构建 Robot/moveTo 的 db 字段
    QJsonObject dbObj;
    dbObj["type"] = moveType;
    if (!targetJson.isEmpty()) {
        dbObj["target"] = targetJson;
    }

    // 2. 发送请求
    writeLog(QString(">>> 启动 RunTo (Type: %1)").arg(moveType));
    sendJsonRequest("Robot/moveTo", dbObj);

    // [新增] 每次发送新的 RunTo，重置非运行状态计数器
    m_nonRunToStateCount = 0;

    // 3.启动心跳定时器 (每 0.5s 发送一次)
    // 注意：无论机器人是否立即响应，我们开始发送指令后通常就需要准备发送心跳
    if (!m_heartbeatTimer->isActive()) {
        writeLog(">>> 开启心跳定时器");
        m_heartbeatTimer->start();
    }

}

// 心跳发送
void RobotClient::onHeartbeatTimer()
{
    if (!isConnected()) {
        m_heartbeatTimer->stop();
        return;
    }

    // 发送 Robot/moveToHeartbeat
    // 心跳包 db 为 null，sendJsonRequest 支持传空
    // writeLog(">>> 发送心跳..."); // 日志可能会刷屏，可视情况注释掉
    sendJsonRequest("Robot/moveToHeartbeat");
}

// 手动订阅
void RobotClient::subscribeTopic(const QString &topic)
{
    if (isConnected()) {
        sendStringRequest(topic); // 或者根据协议发送专门的订阅包
        writeLog("手动订阅: " + topic);
    }else {
        writeLog("未连接，无法订阅: " + topic);
    }

}

void RobotClient::subscribeAll(){
    if (!isConnected()) {
        writeLog("未连接，自动订阅取消");
        return;
    }

    QStringList topics = {
        "{\"ty\":\"publish/ProjectState\",\"tc\":0}",
        "{\"ty\":\"publish/VarUpdate\",\"tc\":0}",
        "{\"ty\":\"publish/RobotStatus\",\"tc\":0}",
        "{\"ty\":\"publish/RobotPosture\",\"tc\":0}",
        "{\"ty\":\"publish/RobotCoordinate\",\"tc\":0}",
        "{\"ty\":\"publish/Log\",\"tc\":0}",
        "{\"ty\":\"publish/Error\",\"tc\":0}"
    };

    // 【关键修改】使用延时发送，避免瞬间发出一坨数据导致粘包
    int delay = 0;

    for(const auto& topic : topics) {
        // QTimer::singleShot 是非阻塞的，不会卡住界面
        // 这里的逻辑是：第1条0ms发，第2条50ms发，第3条100ms发... 以此类推
        QTimer::singleShot(delay, this, [this, topic](){
            if(isConnected()) { // 发送前再次检查连接状态
                sendStringRequest(topic);
            }
        });

        // 间隔 50 毫秒，通常足够服务端处理上一条指令了
        // 如果还是不行，可以尝试改为 100
        delay += 50;
    }
    writeLog("已发送连接自动订阅指令");
}


// [重写] 更健壮的 onReadyRead：带调试日志 + 自动去除头部杂乱数据
void RobotClient::onReadyRead()
{
    QByteArray newData = m_socket->readAll();
    if (newData.isEmpty()) return;

    // [强制日志] 打印收到的字节数和前20个字符（转为Hex防止乱码干扰）
    // writeLog(QString(">>> 底层收到数据: %1 字节, 内容(Hex): %2")
    //              .arg(newData.size())
    //              .arg(QString(newData.toHex().left(40))));

    // 1. 追加数据
    m_receiveBuffer.append(newData);

    while (!m_receiveBuffer.isEmpty()) {

        // 2. 关键修正：找到第一个 '{' 的位置
        // 如果服务端发送的数据包含换行符 \r\n 或者其他协议头，必须跳过它们
        int firstBraceIndex = m_receiveBuffer.indexOf('{');

        if (firstBraceIndex == -1) {
            // 缓冲区里竟然没有 '{'？那这些数据肯定是垃圾数据或心跳包头
            // 稍微保留一点（防止数据还没传完），如果太长了就清空
            if (m_receiveBuffer.size() > 100) {
                 writeLog(">>> 警告: 缓冲区全是垃圾数据，清空");
                m_receiveBuffer.clear();
            }
            break; // 等待下一次 readReady
        }

        // 如果 '{' 不是在第0位，说明前面有垃圾数据（例如换行符），删掉前面的
        if (firstBraceIndex > 0) {
            writeLog("[DEBUG] 丢弃头部无效数据字节数");
            m_receiveBuffer.remove(0, firstBraceIndex);
        }

        // 3. 开始括号计数
        int openBrace = 0;
        int closeBrace = 0;
        int jsonEndIndex = -1;

        for (int i = 0; i < m_receiveBuffer.size(); ++i) {
            if (m_receiveBuffer.at(i) == '{') {
                openBrace++;
            } else if (m_receiveBuffer.at(i) == '}') {
                closeBrace++;
            }

            // 找到完整闭合
            if (openBrace > 0 && openBrace == closeBrace) {
                jsonEndIndex = i;
                break;
            }
        }

        if (jsonEndIndex == -1) {
            // 说明是个半包（数据还没收全），跳出循环等待下一次
            writeLog("[DEBUG] 数据包不完整，等待更多数据...");
            break;
        }

        // 4. 提取完整 JSON
        QByteArray jsonData = m_receiveBuffer.left(jsonEndIndex + 1);
        m_receiveBuffer.remove(0, jsonEndIndex + 1); // 移出缓冲区

        // 5. 解析
        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(jsonData, &err);

        if (err.error != QJsonParseError::NoError) {
            writeLog("[ERROR] JSON 解析失败: " + err.errorString());
            continue;
        }

        if (doc.isObject()) {
            // 成功解析！进入处理流程
            processOneMessage(doc.object());
        }
    }
}


// 接收并处理逻辑
void RobotClient::processOneMessage(const QJsonObject &root)
{
    QString type = root.value("ty").toString();

    // 调试日志：只要收到合法的 JSON 就打印 Type
    // qDebug() << "[DEBUG] 成功解析 JSON，类型(ty):" << type;

    // if (type != "Robot/moveToHeartbeat") {
    //    writeLog("收到: " + type);
    // }

    if (type.isEmpty()) return;

    if (type == "publish/ProjectState") {
        if (root.contains("db") && root.value("db").isObject())
            emit recvProjectStateMessage(root.value("db").toObject());
    }
    else if (type == "publish/VarUpdate") {
        if (root.contains("db") && root.value("db").isObject())
            emit recvVarUpdateMessage(root.value("db").toObject());
    }
    else if(type == "publish/RobotStatus") {
        // 这里加个日志，确认确实触发了信号
        // writeLog("[DEBUG] 触发 recvRobotStatusMessage 信号");
        if (root.contains("db") && root.value("db").isObject())
            emit recvRobotStatusMessage(root.value("db").toObject());
    }
    else if(type == "publish/RobotPosture") {
        if (root.contains("db") && root.value("db").isObject())
            emit recvRobotPostureMessage(root.value("db").toObject());
    }
    else if(type == "publish/RobotCoordinate") {
        if (root.contains("db") && root.value("db").isObject())
            emit recvRobotCoordinateMessage(root.value("db").toObject());
    }
    else if(type == "publish/Log") {
        // writeLog("[DEBUG] 触发 Log 信号");
        if (root.contains("db") && root.value("db").isArray())
            emit recvLogMessage(root);
    }
    else if(type == "publish/Error") {
        // writeLog("[DEBUG] 触发 Error 信号");
        if (root.contains("db") && root.value("db").isArray())
            emit recvErrorMessage(root);
    }
    else if(type == "Robot/moveToHeartbeat") {
        emit recvMoveToHeartbeatMessage();
    }
    else {
        emit recvNormalMessage(root);
    }
}

// [修改] 状态监测与高级心跳停止逻辑
void RobotClient::onhandleRobotStatus(const QJsonObject &db)
{
    if (!db.contains("state")) {
        m_currentRobotState = -1;
        return;
    }

    int newState = db.value("state").toInt();

    // 更新状态给 QML
    if (m_currentRobotState != newState) {
        m_currentRobotState = newState;
        emit robotStateChanged(newState);
        writeLog(QString("机器人状态变更: %1").arg(newState));
    }

    // ==========================================
    // [修改] 核心逻辑：带去抖动的心跳停止机制
    // ==========================================
    if (m_heartbeatTimer->isActive()) {
        if (newState == 4) { // 4 = RunTo
            // 只要收到一次 RunTo 状态，就重置计数器
            m_nonRunToStateCount = 0;
            // writeLog("保持心跳 (RunTo)...");
        } else {
            // 如果不是 RunTo，计数器 +1
            m_nonRunToStateCount++;

            // 只有连续 5 次以上检测到不是 RunTo，才停止心跳
            if (m_nonRunToStateCount > 5) {
                writeLog(QString("<<< 检测到非RunTo状态计数(%1) > 5，停止心跳发送。").arg(m_nonRunToStateCount));
                m_heartbeatTimer->stop();
                m_nonRunToStateCount = 0; // 归零以便下次使用
            }
        }
    }
}

// socket断连
void RobotClient::onSocketStateChanged(QAbstractSocket::SocketState socketState)
{
    bool connected = (socketState == QAbstractSocket::ConnectedState);
    emit connectionStatusChanged(connected);
    if (!connected) {
        m_currentRobotState = -1;
        m_heartbeatTimer->stop(); // 断连保护
        m_receiveBuffer.clear(); // 断连清空缓冲区
    }
}

// 更新的日志系统
void RobotClient::writeLog(const QString &msg)
{
    QString currentTime = QDateTime::currentDateTime().toString("HH:mm:ss.zzz");
    QString fullMsg = QString("[%1] %2").arg(currentTime, msg);

    // 1. 发送信号给 UI (保持原有功能)
    emit logGenerated(fullMsg);

    // 2. 写入本地文件 (新增功能)
    // 使用 QMutexLocker 自动加锁解锁，防止多线程同时写入导致崩溃或乱码
    QMutexLocker locker(&m_logMutex);

    QFile file(m_logFilePath);
    // 以 "追加" (Append) 和 "文本" (Text) 模式打开
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        // 设置编码为 UTF-8，防止中文乱码
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        out.setEncoding(QStringConverter::Utf8);
#else
        out.setCodec("UTF-8");
#endif
        out << fullMsg << "\n";
        file.close();
    } else {
        // 如果文件打开失败（极少情况），输出到控制台
        qDebug() << "Failed to write log to file:" << m_logFilePath;
    }
}

void RobotClient::onConnected()
{
    writeLog("机器人连接成功");
    subscribeAll();
    emit connected();
}

void RobotClient::onDisconnected()
{
    writeLog("机器人连接已断开");
    m_currentRobotState = -1;
    emit disconnected();
}

void RobotClient::onErrorOccurred(QAbstractSocket::SocketError error)
{
    QString errorMsg = QString("连接错误: %1").arg(m_socket->errorString());
    writeLog(errorMsg);

    QString userFriendlyError;
    switch (error) {
    case QAbstractSocket::ConnectionRefusedError:
        userFriendlyError = "连接被拒绝 - 机器人可能未启动";
        break;
    case QAbstractSocket::RemoteHostClosedError:
        userFriendlyError = "远程主机关闭连接";
        break;
    case QAbstractSocket::HostNotFoundError:
        userFriendlyError = "找不到指定的机器人主机";
        break;
    case QAbstractSocket::SocketTimeoutError:
        userFriendlyError = "连接超时";
        break;
    case QAbstractSocket::NetworkError:
        userFriendlyError = "网络错误";
        break;
    default:
        userFriendlyError =  QString("连接错误: %1").arg(m_socket->errorString());
        break;
    }
    emit connectionFailed(userFriendlyError);
}

void RobotClient::initLogSystem()
{
    // 1. 确定日志目录: exe所在目录/Logs
    QString logDir = QCoreApplication::applicationDirPath() + "/Logs";
    QDir dir(logDir);

    // 如果目录不存在，创建它
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    // 2. 获取当前目录下的所有 .txt 日志文件，按修改时间排序（旧 -> 新）
    QStringList filters;
    filters << "*.txt";
    dir.setNameFilters(filters);
    // QDir::Time: 按时间排序, QDir::Reversed: 反序(默认是从新到旧，Reversed变成从旧到新)
    // 注意：QDir::Time 默认是按修改时间排序。
    // 这里我们希望列表头部是最旧的文件（方便删除），尾部是最新的文件（方便检查大小）
    QFileInfoList fileList = dir.entryInfoList(filters, QDir::Files | QDir::NoSymLinks, QDir::Time | QDir::Reversed);

    // 3. 清理旧文件 (如果超过 50 个)
    // 你的需求：超过50个之后把最早的删掉。
    // 因为我们可能在下面创建一个新文件，所以这里如果已经>=50个了，就先删掉最旧的
    while (fileList.size() >= 50) {
        if (!fileList.isEmpty()) {
            QFile::remove(fileList.first().absoluteFilePath()); // 删除最旧的
            fileList.removeFirst(); // 从列表中移除
        }
    }

    // 4. 确定当前要写入的文件路径
    bool createNew = true;

    if (!fileList.isEmpty()) {
        // 获取最新的一个文件
        QFileInfo lastFile = fileList.last();

        // 检查大小 (10MB = 10 * 1024 * 1024 字节)
        if (lastFile.size() < 10 * 1024 * 1024) {
            // 如果小于 10MB，继续使用这个文件
            m_logFilePath = lastFile.absoluteFilePath();
            createNew = false;
        } else {
            // 如果大于 10MB，下次启动（也就是现在）创建新的
            createNew = true;
        }
    }

    if (createNew) {
        // 创建新文件名: log_yyyyMMdd_HHmmss.txt
        QString timeStr = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
        m_logFilePath = logDir + "/log_" + timeStr + ".txt";
    }

    // 打印调试信息（在控制台）
    qDebug() << "Log System Initialized. Path:" << m_logFilePath;
}






