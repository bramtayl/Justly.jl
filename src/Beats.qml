import QtQuick.Controls 2.15
import org.julialang 1.0

SpinBox {
    value: beats
    from: -99
    onValueModified: {
        beats = value;
        yaml.text = Julia.make_yaml()
    }
}