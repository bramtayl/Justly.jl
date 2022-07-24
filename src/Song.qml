import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import org.julialang 1.0

ApplicationWindow {
    property int default_spacing: 12
    id: chords_window
    visible: true
    color: "white"
    title: "Justly"
    width: chords_column.width + 2 * default_spacing
    height: 1000
    ColumnLayout {
        id: chords_column
        x: default_spacing
        y: default_spacing
        spacing: default_spacing
        height: parent.height - 2 * default_spacing
        Row {
            spacing: default_spacing
            Column {
                spacing: default_spacing
                Text {
                    text: "Starting frequency"
                }
                Row {
                    spacing: default_spacing
                    Slider {
                        id: frequency_slider
                        from: 60
                        to: 440
                        stepSize: 10
                        value: julia_arguments.frequency
                        onMoved: {
                            julia_arguments.frequency = value
                            frequency_text.text = value + " Hz"
                        }
                    }
                    Text {
                        id: frequency_text
                        anchors.verticalCenter: parent.verticalCenter
                        text: julia_arguments.frequency + " Hz"
                    }
                }
            }
            Column {
                spacing: default_spacing     
                Text {
                    text: "Tempo"
                }
                Row {
                    Slider {
                        id: tempo_slider
                        from: 100
                        to: 800
                        stepSize: 10
                        value: julia_arguments.tempo
                        onMoved: {
                            julia_arguments.tempo = value
                        }
                    }
                    Text {
                        id: tempo_text
                        anchors.verticalCenter: parent.verticalCenter
                        text: julia_arguments.tempo + " bpm"
                    }
                }
            }
            Column {
                spacing: default_spacing
                Text {
                    text: "Starting volume"
                }
                Row {
                    spacing: default_spacing
                    Slider {
                        id: volume_slider
                        from: 0.0
                        to: 0.2
                        stepSize: 0.01
                        value: julia_arguments.volume
                        onMoved: {
                            julia_arguments.volume = value
                        }
                    }
                    Text {
                        id: volume_text
                        anchors.verticalCenter: parent.verticalCenter
                        text: julia_arguments.volume
                    }
                }
            }
        }
        Row {
            spacing: default_spacing
            Insert {
                selectable_parent: chords_view
            }
            Delete {
                selectable_parent: chords_view
            }
            PlayButton {
                text: "Play selection"
                enabled: chords_view.selection_end > chords_view.selection_start
                onPressed: {
                    Julia.press("play chords", chords_view.selection_start + 1, chords_view.selection_end)
                }
            }
            PlayButton {
                text: "Play from"
                enabled: chords_view.selection_start == chords_view.selection_end
                onPressed: {
                    Julia.press("play chords", chords_view.selection_start + 1)
                }
            }
        }
        SelectableListView {
            id: chords_view
            model: chords_model
            delegate: GapItem {
                id: chords_delegate
                selectable_parent: chords_view
                item: Chord { }
            }
        }
    }  
    Window {
        id: notes_window
        visible: false
        color: "white"
        title: "Justly"
        width: notes_column.width + 2 * default_spacing
        height: 1000
        ColumnLayout {
            id: notes_column
            x: default_spacing
            y: default_spacing
            spacing: default_spacing
            height: parent.height - 2 * default_spacing
            Button {
                text: "Return to chords"
                onClicked: {
                    notes_window.close()
                    chords_window.visible = true
                }
            }
            Row {
                spacing: default_spacing
                Insert {
                    selectable_parent: notes_view
                }
                Delete {
                    selectable_parent: notes_view
                }
                PlayButton {
                    text: "Play selection"
                    enabled: notes_view.selection_end > notes_view.selection_start
                    onPressed: {
                        Julia.press("play notes", notes_view.chord_index + 1, notes_view.selection_start + 1, notes_view.selection_end)
                    }
                }
            }
            SelectableListView {
                id: notes_view
                property int chord_index: 0
                model: empty_notes_model
                delegate: GapItem {
                    selectable_parent: notes_view
                    item: Note { }
                }
            }
        }
    }
    Timer {
        running: test
        // close after 5 seconds
        interval: 5000
        onTriggered: Qt.quit()
    }
} 