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
            TextField {
                text: lyrics
                onEditingFinished: {
                    lyrics = text
                }
            }
            RowTemplate {
                TextTemplate {
                    text: "key = key ×"
                }
                Interval {}
            }
            RowTemplate {
                TextTemplate {
                    text: "wait for"
                }
                Beats {}
            }
        }
        ToolSeparator {
            height: parent.height
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