import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "key × "
    }
    Column {
        SmallSpinBox {
            from: 1
            value: numerator
            onValueModified: {
                numerator = value
            }
        }
        ToolSeparator {
            orientation: Qt.Horizontal
            width: parent.width
        }
        SmallSpinBox {
            from: 1
            value: denominator
            onValueModified: {
                denominator = value
            }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: " × 2 "
    }
    SmallSpinBox {
        from: -99
        value: octave
        onValueModified: {
            octave = value
        }
    }
}