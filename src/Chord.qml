import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Grid {
    x: default_spacing
    y: default_spacing
    id: chord_grid
    spacing: default_spacing
    flow: Grid.TopToBottom
    verticalItemAlignment: Grid.AlignVCenter
    rows: 2
    Text {
        text: "Edit"
    }
    Button {
        text: "Notes"
        onClicked: {
            notes_view.chord_index = index
            notes_view.selection_start = 0
            notes_view.selection_end = 0
            notes_view.model = notes_model
            notes_window.visible = true
            chords_window.visible = false
        }
    }
    Text {
        text: "Words"
    }
    TextField {
        text: words
        onEditingFinished: {
            words = text
        }
    }
    Text {
        text: "Modulation"
    }
    Interval { }
    Text {
        text: "Beats till next chord"
    }
    Beats { }
    Text {
        text: "Volume change"
    }
    Volume { }
}