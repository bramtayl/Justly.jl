import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    spacing: default_spacing
    SmallText {
        text: "for"
    }
    SpinBox {
        value: beats
        from: -99
        onValueModified: {
            beats = value
            update_yaml()
        }
    }
}