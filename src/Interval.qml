import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "key × "
    }
    Column {
        SpinBox {
            editable: true
            from: 1
            value: numerator
            onValueModified: {
                numerator = value
                yaml.text = Julia.to_yaml()
            }
        }
        ToolSeparator {
            orientation: Qt.Horizontal
            width: parent.width
        }
        SpinBox {
            from: 1
            value: denominator
            editable: true
            onValueModified: {
                denominator = value
                yaml.text = Julia.to_yaml()
            }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: " × 2 "
    }
    SpinBox {
        editable: true
        from: -99
        value: octave
        onValueModified: {
            octave = value
            yaml.text = Julia.to_yaml()
        }
    }
}