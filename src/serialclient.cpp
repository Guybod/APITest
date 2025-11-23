#include "SerialClient.h"
#include <QDebug>

SerialClient::SerialClient(QObject *parent) : QObject(parent)
{
    m_serial = new QSerialPort(this);
    connect(m_serial, &QSerialPort::readyRead, this, &SerialClient::onReadyRead);
    connect(m_serial, &QSerialPort::errorOccurred, this, &SerialClient::onError);
    refreshPorts();
}

SerialClient::~SerialClient()
{
    close();
}

bool SerialClient::isConnected() const
{
    return m_serial->isOpen();
}

QStringList SerialClient::portList() const
{
    return m_availablePorts;
}

// 定义常量列表，方便前端直接用
QStringList SerialClient::baudList() const {
    return {"9600", "19200", "38400", "57600", "115200", "230400", "460800", "921600"};
}
QStringList SerialClient::dataBitsList() const { return {"5", "6", "7", "8"}; }
QStringList SerialClient::parityList() const { return {"None", "Even", "Odd", "Space", "Mark"}; }
QStringList SerialClient::stopBitsList() const { return {"1", "1.5", "2"}; }

void SerialClient::refreshPorts()
{
    m_availablePorts.clear();
    const auto infos = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : infos) {
        m_availablePorts.append(info.portName());
    }
    emit portsChanged();
}

void SerialClient::open(const QString &portName, const QString &baudRate,
                        const QString &dataBits, const QString &parity, const QString &stopBits)
{
    if (m_serial->isOpen()) m_serial->close();

    m_serial->setPortName(portName);
    m_serial->setBaudRate(baudRate.toInt());

    // Data Bits
    if (dataBits == "5") m_serial->setDataBits(QSerialPort::Data5);
    else if (dataBits == "6") m_serial->setDataBits(QSerialPort::Data6);
    else if (dataBits == "7") m_serial->setDataBits(QSerialPort::Data7);
    else m_serial->setDataBits(QSerialPort::Data8);

    // Parity
    if (parity == "Even") m_serial->setParity(QSerialPort::EvenParity);
    else if (parity == "Odd") m_serial->setParity(QSerialPort::OddParity);
    else if (parity == "Space") m_serial->setParity(QSerialPort::SpaceParity);
    else if (parity == "Mark") m_serial->setParity(QSerialPort::MarkParity);
    else m_serial->setParity(QSerialPort::NoParity);

    // Stop Bits
    if (stopBits == "1.5") m_serial->setStopBits(QSerialPort::OneAndHalfStop);
    else if (stopBits == "2") m_serial->setStopBits(QSerialPort::TwoStop);
    else m_serial->setStopBits(QSerialPort::OneStop);

    if (m_serial->open(QIODevice::ReadWrite)) {
        emit connectionStatusChanged(true);
    } else {
        emit errorOccurred("无法打开串口: " + m_serial->errorString());
    }
}

void SerialClient::close()
{
    if (m_serial->isOpen()) {
        m_serial->close();
        emit connectionStatusChanged(false);
    }
}

void SerialClient::send(const QString &content, bool isHex)
{
    if (!m_serial->isOpen()) {
        emit errorOccurred("未连接串口");
        return;
    }

    QByteArray dataToSend;
    if (isHex) {
        // 优化：自动清理非HEX字符（如空格、换行），容错处理
        QString cleanHex = content;
        cleanHex.remove(QRegularExpression("[^0-9A-Fa-f]"));
        dataToSend = QByteArray::fromHex(cleanHex.toUtf8());
    } else {
        dataToSend = content.toUtf8();
    }

    m_serial->write(dataToSend);
}

void SerialClient::onReadyRead()
{
    QByteArray data = m_serial->readAll();
    if (data.isEmpty()) return;

    // 优化：C++ 处理好两种格式，QML 直接选用，性能最高
    // 1. 文本模式：转 UTF8
    QString textMsg = QString::fromUtf8(data);

    // 2. HEX 模式：转大写，并用空格分隔 (例如: "AA BB CC")
    // .toHex(' ') 是 Qt 5.14+ 引入的便捷方法，如果你的 Qt 版本低，去掉 ' '
    QString hexMsg = data.toHex(' ').toUpper();

    emit messageReceived(textMsg, hexMsg);
}

void SerialClient::onError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError) return;
    // 资源错误通常意味着设备被拔出
    if (error == QSerialPort::ResourceError || error == QSerialPort::PermissionError) {
        if(m_serial->isOpen()) close();
    }
}
