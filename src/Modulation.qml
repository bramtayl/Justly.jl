import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Column {
    spacing: default_spacing
    Layout.alignment: Qt.AlignTop
    Row {
        spacing: default_spacing
        Button {
            text: "Hide chord"
            onClicked: {
                selected = false
            }
        }
        TextField {
            text: words
            onEditingFinished: {
                words = text
            }
        }
    }
    Grid {
        spacing: default_spacing
        // center text next to the larger control
        verticalItemAlignment: Grid.AlignVCenter
        // first column is the labels, second column is the
        // controls
        columns: 2
        Text {
            text: "Interval:"
        }
        Interval { }
        Text {
            text: "Beats:"
        }
        SpinBox {
            from: 1
            value: beats
            editable: true
            onValueModified: {
                beats = value
            }
        }
        Text {
            text: "Volume:"
        }
        Row {
            spacing: default_spacing
            Slider {
                id: volume_slider
                value: volume
                from: 0
                stepSize: 0.1
                to: 4
                onMoved: {
                    volume = value
                    // just one decimal
                    // should be zeros after that, but sometimes
                    // there's floating-point noise
                    volume_text.text = value.toFixed(1)
                }
            }
            Text {
                id: volume_text
                // center text next to large control
                anchors.verticalCenter: parent.verticalCenter
                // just one decimal
                // should be zeros after that, but sometimes
                // there's floating-point noise
                text: volume_slider.value.toFixed(1)
            }
        }
        Text {
            text: "Instrument name:"
        }
        Item {
            width: 1
            height: 40
        }
    }
    PlayButton {
        // center under note
        anchors.horizontalCenter: parent.horizontalCenter
        onPressed: {
            // add 1 for 1-based indexing
            // -1 is a sentinel meaning just a chord, no note
            // TODO: can we use nothing here?
            Julia.press_chord(index + 1)
        }
        onReleased: {
            // stop playing when the user releases the button
            Julia.release()
        }
        // release if canceled too
        onCanceled: {
            Julia.release()
        }
    }
}