import QtQuick 2.5
import QtQuick.Controls 2.15

Column {
    spacing: window.spacing
    property int chord_index: index
    Row {
        spacing: parent.spacing
        RemoveButton {
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                chords.remove(index)
            }
        }
        Column {
            spacing: parent.spacing
            TextField {
                text: lyrics
                onEditingFinished: {
                    lyrics = text
                }
            }
            Row {
                spacing: parent.spacing
                Interval {
                    key_text: "key = key ×"
                }
            }
            Beats {
                beat_text: "wait for"
            }
        }
        ToolSeparator {
            height: parent.height
        }
        AddButton {
            onClicked: {
                notes_model.insert(0, []);
            }
        }
        ListTemplate {
            orientation: ListView.Horizontal
            model: notes_model
            delegate: Note { }
        }
    }
    AddButton {
        onClicked: {
            chords.insert(index + 1, []);
        }
    }
}