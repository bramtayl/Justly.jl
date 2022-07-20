import QtQuick 2.15
import QtQuick.Controls 2.15

Row {
    spacing: default_spacing
    Slider {
        id: volume_slider
        value: volume
        from: 0
        stepSize: 0.01
        to: 4
        onMoved: {
            volume = value
            // just one decimal
            // should be zeros after that, but sometimes there's
            // floating-point noise
            volume_text.text = value.toFixed(1)
        }
    }
    Text {
        id: volume_text
        anchors.verticalCenter: parent.verticalCenter
        // just one decimal
        // should be zeros after that, but sometimes there's
        // floating-point noise
        text: volume.toFixed(1)
    }
}