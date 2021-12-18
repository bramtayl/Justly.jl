import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    color: "white"
    property int button_side: 40
    property int button_text_size: 16
    property int default_spacing: 5
    property string add_text: "+"
    property string remove_text: "−"
    Column {
        height: parent.height
        width: parent.width
        Row {
            id: options_bar
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
                        Julia.to_yaml()
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
                        Julia.to_yaml()
                    }
                    stepSize: 1
                    from: 36
                    value: Julia.get_initial_midi_code()
                    to: 72
                }
            }
        }
        ScrollView {
            width: parent.width
            height: parent.height - options_bar.height
            clip: true
            ListView {
                id: chords_view
                height: parent.height
                width: parent.width
                clip: true
                model: chords_model
                snapMode: ListView.SnapToItem
                delegate: Chord { }
                footer: Button {
                    implicitWidth: button_side
                    implicitHeight: button_side
                    text: add_text
                    font.pointSize: button_text_size
                    onClicked: {
                        chords_model.append([])
                        Julia.to_yaml()
                    }
                }
            }
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
