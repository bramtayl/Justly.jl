import QtQuick 2.5
import QtQuick.Controls 2.15

Row {
    spacing: parent.spacing
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "for"
    }
    SpinBox {
        value: beats
        from: -99
        onValueModified: {
            beats = value
        }
    }
}