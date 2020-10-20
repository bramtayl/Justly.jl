import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    spacing: default_spacing
    DisplayText {
        text: "𝄞"
    }
    SmallText {
        text: "×"
    }
    Column {
        spacing: default_spacing / 2
        SpinBox {
            value: numerator
            from: 1
            editable: true
            onValueModified: {
                numerator = value
                update_yaml()
            }
        }
        ToolSeparator {
            orientation: Qt.Horizontal
            width: parent.width
        }
        SpinBox {
            value: denominator
            from: 1
            editable: true
            onValueModified: {
                denominator = value
                update_yaml()
            }
        }
    }
    SmallText {
        text: "×"
    }
    DisplayText {
        text: "2"
    }
    SpinBox {
        value: octave
        from: -99
        editable: true
        onValueModified: {
            octave = value
            update_yaml()
        }
    }
}