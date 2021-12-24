import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    color: "white"
    property int small_height: 25
    property int small_width: 35
    property int small_spacing: 5
    property string add_text: "+"
    property string remove_text: "−"
    ColumnLayout {
        height: parent.height
        width: parent.width
        Row {
            Column {
                Text {
                    text: "Tempo: " + beats_per_minute_slider.value.toFixed(0) + "bpm"
                }
                Slider {
                    id: beats_per_minute_slider
                    from: 100
                    value: Julia.get_beats_per_minute()
                    to: 800
                    onMoved: {
                        Julia.update_beats_per_minute(value)
                    }
                }
            }
            Column {
                Text {
                    id: initial_midi_name_text
                    textFormat: Text.RichText
                    text: Julia.get_midi_name(initial_midi_code_slider.value)
                }
                Slider {
                    id: initial_midi_code_slider
                    snapMode: Slider.SnapAlways
                    onMoved: {
                        Julia.update_initial_midi_code(value)
                    }
                    stepSize: 1
                    from: 36
                    value: Julia.get_initial_midi_code()
                    to: 72
                }
            }
        }
        ListView {
            id: chords_view
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            model: chords_model
            snapMode: ListView.SnapToItem
            delegate: Chord { }
            footer: SmallButton {
                text: add_text
                onClicked: {
                    chords_model.append([])
                }
            }
            ScrollBar.vertical: ScrollBar {
                active: true
            }
        }
    }
    onClosing: {
        Julia.to_yaml()
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
