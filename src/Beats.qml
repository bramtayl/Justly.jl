import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "for"
    }
    SpinBox {
        editable: true
        from: -99
        value: beats
        onValueModified: {
            beats = value
            yaml.text = Julia.to_yaml()
        }
    }
}