import QtQuick 2.5
import QtQuick.Controls 2.15
import org.julialang 1.0

ColumnTemplate {
    property int chord_index: index
    RowTemplate {
        RemoveButton {
            anchors.verticalCenter: parent.verticalCenter
            model: julia_arguments.chords_model
        }
        ColumnTemplate {
            RowTemplate {
                PlayButton {
                    onClicked: {
                        Julia.play(index)
                    }
                }
                SmallText {
                    text: "from"
                }
            }
            RowTemplate {
                Key { }
                SmallText {
                    text: "="
                }
                Key { }
                Times { }
                Interval { }
            }
            RowTemplate {
                SmallText {
                    text: "words:"
                }
                TextField {
                    text: words
                    onEditingFinished: {
                        words = text
                    }
                }
                DisplayText {
                    text: "⏸"
                }
                For { }
                Beats { }
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