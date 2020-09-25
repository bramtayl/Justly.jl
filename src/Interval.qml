import QtQuick 2.5
import QtQuick.Controls 2.15

Row {
    spacing: parent.spacing
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "×"
    }
    Column {
        spacing: parent.spacing
        SpinBox {
            value: numerator
            from: 1
            onValueModified: {
                numerator = value
            }
        }
        ToolSeparator {
            orientation: Qt.Horizontal
            width: parent.width
        }
        SpinBox {
            value: denominator
            from: 1
            onValueModified: {
                denominator = value
            }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "2"
    }
    SpinBox {
        value: octave
        from: -99
        onValueModified: {
            octave = value
        }
    }
}