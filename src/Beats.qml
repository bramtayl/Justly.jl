import QtQuick 2.5
import QtQuick.Controls 2.15

SpinBox {
    value: beats
    from: -99
    onValueModified: {
        beats = value
    }
}