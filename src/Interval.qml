import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

RowTemplate {
    Column {
        spacing: default_spacing / 2
        SpinBox {
            value: numerator
            from: 1
            onValueModified: {
                numerator = value;
                Julia.to_yaml();
                yaml.text = julia_arguments.observable_yaml
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
                denominator = value;
                Julia.to_yaml();
                yaml.text = julia_arguments.observable_yaml
            }
        }
    }
    Times { }
    DisplayText {
        text: "2"
    }
    SpinBox {
        value: octave
        from: -99
        onValueModified: {
            octave = value;
            Julia.to_yaml();
            yaml.text = julia_arguments.observable_yaml
        }
    }
}