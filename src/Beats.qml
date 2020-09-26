import QtQuick 2.5
import QtQuick.Controls 2.15

Row {
    property string beat_text
    spacing: parent.spacing
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: beat_text
    }
    SpinBox {
        value: beats
        from: -99
        onValueModified: {
            beats = value
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "beat(s)"
    }
}