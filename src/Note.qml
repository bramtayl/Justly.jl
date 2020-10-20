import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    spacing: default_spacing
    InsertButton {
        model: notes_model
    }
    Column {
        spacing: default_spacing
        RemoveButton {
            anchors.horizontalCenter: parent.horizontalCenter
            model: notes_model
        }
        Row {
            spacing: default_spacing
            DisplayText {
                text: "𝄞"
            }
            SmallText {
                text: "×"
            }
            Interval {}
        }
        Row {
            spacing: default_spacing
            anchors.right: parent.right
            PlayButton {
                onPressed: {
                    event_id = Julia.press(chord_index, index)
                }
            }
            Beats { }
        }
    }
}