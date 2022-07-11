import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Row {
    spacing: default_spacing
    // insert new note before this one
    AddButton {
        onClicked: {
            notes_model.insert(index, [])
        }
    }
    Column {
        spacing: default_spacing
        RemoveButton {
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                notes_model.remove(index)
            }
        }
        Column {
            spacing: default_spacing
            Interval { }
            SpinBox {
                from: -99
                value: beats
                editable: true
                onValueModified: {
                    beats = value
                }
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
                        // should be zeros after that, but sometimes there's
                        // floating-point noise
                        volume_text.text = value.toFixed(1)
                    }
                }
                Text {
                    id: volume_text
                    // center text next to larger control
                    anchors.verticalCenter: parent.verticalCenter
                    // just one decimal
                    // should be zeros after that, but sometimes there's
                    // floating-point noise
                    text: volume_slider.value.toFixed(1)
                }
            }
            ComboBox {
                model: instruments_model
                currentIndex: instrument_number
                onActivated: {
                    instrument_number = index
                }
            }
        }
        PlayButton {
            // center under note
            anchors.horizontalCenter: parent.horizontalCenter
            onPressed: {
                // add 1 for 1-based indexing
                Julia.press_note(chord_index + 1, index + 1)
            }
            onReleased: {
                // wait for julia to be ready
                Julia.release()
            }
            onCanceled: {
                // release if canceled too
                Julia.release()
            }
        }
    }
}