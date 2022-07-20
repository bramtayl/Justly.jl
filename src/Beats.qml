import QtQuick 2.15
import QtQuick.Controls 2.15

SpinBox {
    from: 1
    value: beats
    editable: true
    onValueModified: {
        beats = value
    }
}