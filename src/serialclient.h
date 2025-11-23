#ifndef SERIALCLIENT_H
#define SERIALCLIENT_H

#include <QObject>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QStringList>
#include <QRegularExpression>

class SerialClient : public QObject
{
    Q_OBJECT
    // 暴露状态属性
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStatusChanged)

    // 暴露配置列表给 ComboBox 使用
    Q_PROPERTY(QStringList portList READ portList NOTIFY portsChanged)
    Q_PROPERTY(QStringList baudList READ baudList CONSTANT)
    Q_PROPERTY(QStringList dataBitsList READ dataBitsList CONSTANT)
    Q_PROPERTY(QStringList parityList READ parityList CONSTANT)
    Q_PROPERTY(QStringList stopBitsList READ stopBitsList CONSTANT)

public:
    explicit SerialClient(QObject *parent = nullptr);
    ~SerialClient();

    bool isConnected() const;

    // 获取列表数据的 Getter
    QStringList portList() const;
    QStringList baudList() const;
    QStringList dataBitsList() const;
    QStringList parityList() const;
    QStringList stopBitsList() const;

    // --- QML 调用接口 ---

    // 刷新可用串口
    Q_INVOKABLE void refreshPorts();

    // 打开串口 (参数传入字符串，内部自动转换)
    Q_INVOKABLE void open(const QString &portName, const QString &baudRate,
                          const QString &dataBits, const QString &parity, const QString &stopBits);

    // 关闭串口
    Q_INVOKABLE void close();

    // 发送数据 (content: 内容, isHex: 是否为16进制模式)
    Q_INVOKABLE void send(const QString &content, bool isHex);

signals:
    void connectionStatusChanged(bool isConnected);
    void portsChanged();

    // 关键优化：同时发送文本和Hex字符串，UI根据复选框决定显示哪个
    void messageReceived(const QString &textMsg, const QString &hexMsg);

    void errorOccurred(const QString &errorMsg);

private slots:
    void onReadyRead();
    void onError(QSerialPort::SerialPortError error);

private:
    QSerialPort *m_serial;
    QStringList m_availablePorts;
};

#endif // SERIALCLIENT_H
