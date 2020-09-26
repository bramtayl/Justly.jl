import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    spacing: window.spacing
    Column {
        spacing: parent.spacing
        RemoveButton {
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                notes_model.remove(index)
            }
        }
        Column {
            spacing: parent.spacing
            Interval {
                key_text: "key ×"
            }
            Beats {
                beat_text: "play for"
            }
            PlayButton {
                onPressed: {
                    Julia.press(chord_index, index)
                }
                onReleased: {
                    Julia.release()
                }
            }
        }
    }
    AddButton {
        onClicked: {
            notes_model.insert(index + 1, [])
        }
    }
}