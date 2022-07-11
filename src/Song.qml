import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int default_spacing: 12
    property string background_color: "white"
    property int small_button_width: 40

    // reasonably big by default
    width: 1000
    height: 1000
    
    // the whole window
    Rectangle {
        color: background_color
        anchors.fill: parent
        Item {
            // the whole window except the margins
            anchors.fill: parent
            anchors.topMargin: default_spacing
            anchors.leftMargin: default_spacing
            ListView {
                id: chords_list_view
                spacing: default_spacing
                // leave some room for the scroll bar
                height: parent.height - default_spacing
                width: parent.width
                model: chords_model
                delegate: Chord { }
                clip: true
                ScrollBar.vertical: ScrollBar {
                    // always show the scroll bar so the users know they can
                    // scroll
                    policy: ScrollBar.AlwaysOn
                }
                header: Column {
                    Grid {
                        spacing: default_spacing
                        // center text next to tne larger control
                        verticalItemAlignment: Grid.AlignVCenter
                        // one column for the label
                        // one for the control
                        // and one for the units
                        columns: 3
                        Text {
                            text: "Starting frequency:"
                        }
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
                            text: julia_arguments.frequency + " Hz"
                        }
                        Text {
                            text: "Tempo:"
                        }
                        Slider {
                            id: tempo_slider
                            from: 100
                            to: 800
                            stepSize: 10
                            value: julia_arguments.tempo
                            onMoved: {
                                julia_arguments.tempo = value
                                tempo_text.text = value + " bpm"
                            }
                        }
                        Text {
                            id: tempo_text
                            text: julia_arguments.tempo + " bpm"
                        }
                        Text {
                            text: "Volume"
                        }
                        Slider {
                            id: volume_slider
                            from: 0.0
                            to: 0.2
                            stepSize: 0.01
                            value: julia_arguments.volume
                            onMoved: {
                                julia_arguments.volume = value
                                volume_text.text = value
                            }
                        }
                        Text {
                            id: volume_text
                            text: julia_arguments.volume
                        }
                    }
                    // manually add spacing after the header
                    Item {
                        width: 1
                        height: default_spacing
                    }
                }
                footer: Column {
                    // manually add spacing before the footer
                    Item {
                        width: 1
                        height: default_spacing
                    }
                    AddButton {
                        onClicked: {
                            chords_model.append([])
                        }
                    }
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

