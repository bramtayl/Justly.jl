import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    spacing: default_spacing
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
                    Julia.press(chord_index, index)
                }
            }
            Beats { }
        }
    }
    InsertButton {
        model: notes_model
    }
}