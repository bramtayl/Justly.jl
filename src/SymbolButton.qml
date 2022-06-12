import QtQuick 2.5
import QtQuick.Controls 2.15

Button {
    property color up_color
    property color down_color
    property string button_text
    contentItem: Text {
        font.pointSize: 15
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: button_text
    }
    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        color: down ? down_color : up_color
    }
}