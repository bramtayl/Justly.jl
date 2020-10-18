import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

Column {
    spacing: default_spacing
    property int chord_index: index
    Row {
        spacing: default_spacing
        RemoveButton {
            anchors.verticalCenter: parent.verticalCenter
            model: julia_arguments.chords_model
        }
        Column {
            spacing: default_spacing
            Row {
                spacing: default_spacing
                PlayButton {
                    onPressed: {
                        Julia.play(index)
                    }
                }
                SmallText {
                    text: "from"
                }
            }
            Row {
                spacing: default_spacing
                DisplayText {
                    text: "𝄞"
                }
                SmallText {
                    text: "="
                }
                Interval { }
            }
            Row {
                spacing: default_spacing
                anchors.right: parent.right
                DisplayText {
                    text: "⏸"
                }
                Beats { }
            }
            Row {
                spacing: default_spacing
                SmallText {
                    text: "words:"
                }
                TextField {
                    text: words
                    onEditingFinished: {
                        words = text
                    }
                }
            }
        }
        StartButton {
            model: notes_model
        }
        ListTemplate {
            orientation: ListView.Horizontal
            model: notes_model
            delegate: Note { }
        }
    }
    InsertButton {
        model: julia_arguments.chords_model
    }
}