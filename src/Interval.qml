import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    spacing: default_spacing
    Column {
        SpinBox {
            id: numerator_control
            from: 1
            value: numerator
            editable: true
            onValueModified: {
                numerator = value
            }
        }
        ToolSeparator {
            orientation: Qt.Horizontal
            // implicit to avoid a loop?
            implicitWidth: parent.width
        }
        SpinBox {
            id: denominator_control
            from: 1
            value: denominator
            editable: true
            onValueModified: {
                denominator = value
            }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "×2"
    }
    Row {
        SpinBox {
            from: -99
            value: octave
            editable: true
            onValueModified: {
                octave = value
            }
        }
    }
}