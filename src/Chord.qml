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
            chord_model.insert(index, [])
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
                chord_model.remove(index)
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
                Column {
                    id: modulation
                    spacing: default_spacing
                    Layout.alignment: Qt.AlignTop
                    Row {
                        spacing: default_spacing
                        Button {
                            text: "Hide chord"
                            onClicked: {
                                selected = false
                            }
                        }
                        TextField {
                            text: words
                            onEditingFinished: {
                                words = text
                            }
                        }
                    }
                    Grid {
                        spacing: default_spacing
                        // center text next to the larger control
                        verticalItemAlignment: Grid.AlignVCenter
                        // first column is the labels, second column is the
                        // controls
                        columns: 2
                        Text {
                            text: "Interval:"
                        }
                        Interval { }
                        Text {
                            text: "Beats:"
                        }
                        SpinBox {
                            from: 1
                            value: beats
                            editable: true
                            onValueModified: {
                                beats = value
                                Julia.update_file()
                            }
                        }
                        Text {
                            text: "Volume:"
                        }
                        Row {
                            spacing: default_spacing
                            Slider {
                                id: volume_slider
                                value: volume
                                from: 0
                                stepSize: 0.1
                                to: 4
                                onMoved: {
                                    volume = value
                                    Julia.update_file()
                                    // just one decimal
                                    // should be zeros after that, but sometimes
                                    // there's floating-point noise
                                    volume_text.text = value.toFixed(1)
                                }
                            }
                            Text {
                                id: volume_text
                                // center text next to large control
                                anchors.verticalCenter: parent.verticalCenter
                                // just one decimal
                                // should be zeros after that, but sometimes
                                // there's floating-point noise
                                text: volume_slider.value.toFixed(1)
                            }
                        }
                    }
                    PlayButton {
                        // center under note
                        anchors.horizontalCenter: parent.horizontalCenter
                        onPressed: {
                            // add 1 for 1-based indexing
                            // -1 is a sentinel meaning just a chord, no note
                            // TODO: can we use nothing here?
                            Julia.press(index + 1, -1)
                        }
                        onReleased: {
                            // stop playing when the user releases the button
                            Julia.release()
                        }
                        // release if canceled too
                        onCanceled: {
                            Julia.release()
                        }
                    }
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