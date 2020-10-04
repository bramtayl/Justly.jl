import QtQuick.Controls 2.15
import org.julialang 1.0

SpinBox {
    value: beats
    from: -99
    onValueModified: {
        beats = value;
        Julia.to_yaml();
        yaml.text = julia_arguments.observable_yaml
    }
}