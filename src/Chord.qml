import QtQuick 2.5
import QtQuick.Controls 2.15

ColumnTemplate {
    property int chord_index: index
    RowTemplate {
        RemoveButton {
            anchors.verticalCenter: parent.verticalCenter
            model: chords
        }
        ColumnTemplate {
            RowTemplate {
                SmallText {
                    text: "words:"
                }
                TextField {
                    text: lyrics
                    onEditingFinished: {
                        lyrics = text
                    }
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
                anchors.right: parent.right
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
        model: chords
    }
}