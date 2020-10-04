import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int default_spacing: 12
    property var button_size: 40
    property var large_text: 18
    property var small_text: 12
    property var reverse_color: "white"
    property var dark: "black"
    color: dark
    ScrollView {
        anchors.fill: parent
        padding: default_spacing
        ColumnTemplate {
            RowTemplate {
                PlayButton {
                    onClicked: {
                        Julia.play()
                    }
                }
            }
            StartButton {
                model: julia_arguments.chords_model
            }
            ListTemplate {
                id: chords_view
                model: julia_arguments.chords_model
                delegate: Chord { }
            }
            TextArea {
                id: yaml
                selectByMouse: true
                font.pointSize: small_text
                onEditingFinished: {
                    julia_arguments.observable_yaml = text
                    Julia.from_yaml()
                }
                background: Rectangle {
                    color: reverse_color
                    border.color: yaml.focus ? "steelblue" : "transparent"
                    border.width: 2
                }
            } 
        }
    }
    Timer {
        running: julia_arguments.test
        onTriggered: Qt.quit()
    }
}
