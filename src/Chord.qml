import QtQuick 2.5

Grid {
    property int chord_index: index
    spacing: window.spacing
    verticalItemAlignment: Grid.AlignVCenter
    columns: 2
    RemoveButton {
        onClicked: {
            chords.remove(index)
        }
    }
    ListTemplate {
        orientation: ListView.Horizontal
        model: notes_model
        delegate: Note { }
    }
    AddButton {
        onClicked: {
            chords.insert(index + 1, []);
        }
    }
}