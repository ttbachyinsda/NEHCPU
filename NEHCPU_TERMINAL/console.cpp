#include "console.h"

#include <QScrollBar>

#include <QtCore/QDebug>

Console::Console(QWidget *parent)
    : QPlainTextEdit(parent)
    , localEchoEnabled(false)
{
    QPlainTextEdit::zoomIn(2.3);
    QPlainTextEdit::setUndoRedoEnabled(true);
    document()->setMaximumBlockCount(100);
    QPalette p = palette();
    p.setColor(QPalette::Base, Qt::black);
    p.setColor(QPalette::Text, Qt::green);
    setPalette(p);

}

void Console::putData(const QByteArray &data)
{
    if (data[0] == '\b')
    {
        QPlainTextEdit::undo();
    } else
        insertPlainText(QString(data));

    QScrollBar *bar = verticalScrollBar();
    bar->setValue(bar->maximum());
}

void Console::setLocalEchoEnabled(bool set)
{
    localEchoEnabled = set;
}

void Console::keyPressEvent(QKeyEvent *e)
{
    QChar c = '\b';
    QByteArray s;
    s.append(c);
    switch (e->key()) {
    case Qt::Key_Backspace:
        QPlainTextEdit::keyPressEvent(e);
        emit getData(s);
        break;
    case Qt::Key_Left:
    case Qt::Key_Right:
    case Qt::Key_Up:
    case Qt::Key_Down:
        break;
    default:
        emit getData(e->text().toLocal8Bit());
    }
}

void Console::mousePressEvent(QMouseEvent *e)
{
    Q_UNUSED(e)
    setFocus();
}

void Console::mouseDoubleClickEvent(QMouseEvent *e)
{
    Q_UNUSED(e)
}

void Console::contextMenuEvent(QContextMenuEvent *e)
{
    Q_UNUSED(e)
}
