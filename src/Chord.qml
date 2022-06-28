import QtQuick 2.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Column {
    id: chord_column
    spacing: default_spacing
    // leave room for the scroll bar
    width: chords_list_view.width - default_spacing - default_spacing
    // save the chord index before we add in note indices
    property int chord_index: index
    AddButton {
        onClicked: {
            chords_model.insert(index, [])
        }
    }
    // Layout so that the column (and the ListView in it) can expand to the edge
    RowLayout {
        id: chord_object
        spacing: default_spacing
        width: parent.width
        RemoveButton {
            id: remove_button
            onClicked: {
                chords_model.remove(index)
            }
        }
        Column {
            spacing: default_spacing
            Layout.fillWidth: true
            // brief summary
            Row {
                visible: !selected
                spacing: default_spacing
                Button {
                    text: "Edit chord"
                    onClicked: {
                        selected = true
                    }
                }
                Text {
                    // center next to button
                    anchors.verticalCenter: parent.verticalCenter
                    text: words
                }
            }
            // full chord
            // Layout so that the column (and the ListView in it) can expand to the edge
            RowLayout {
                spacing: default_spacing
                visible: selected
                width: parent.width
                Modulation {
                    id: modulation
                }
                ToolSeparator {
                    implicitHeight: Math.max(modulation.height, notes.height)
                }
                ListView {
                    id: notes
                    spacing: default_spacing
                    Layout.fillWidth: true
                    // add extra space for the scroll bar
                    // why do we need 3?
                    height: modulation.height + default_spacing + default_spacing + default_spacing
                    orientation: ListView.Horizontal
                    model: notes_model
                    delegate: Note { }
                    footer: Row {
                        // manually add spacing before footer
                        Item {
                            width: default_spacing
                            height: 1
                        }
                        AddButton {
                            onClicked: {
                                notes_model.append([])
                            }
                        }
                    }
                    clip: true
                    ScrollBar.horizontal: ScrollBar {
                        // always show the scroll bar so the users know they can
                        // scroll
                        policy: ScrollBar.AlwaysOn
                    }
                }
            }
        }
    }
}