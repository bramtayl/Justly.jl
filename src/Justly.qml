import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int default_spacing: 12
    property var button_size: 40
    property var large_text_size: 18
    property var small_text_size: 12
    property var positive_color: "white"
    property var negative_color: "black"
    color: negative_color
    ScrollView {
        anchors.fill: parent
        padding: default_spacing
        ColumnTemplate {
            StartButton {
                model: julia_arguments.chords_model
            }
            ListTemplate {
                id: chords_view
                model: julia_arguments.chords_model
                delegate: Chord { }
            }
            Button {
                text: "Import"
                onClicked: {
                    julia_arguments.observable_yaml = yaml.text
                    Julia.from_yaml()
                }
            }
            TextArea {
                id: yaml
                selectByMouse: true
                font.pointSize: small_text_size
                background: Rectangle {
                    color: positive_color
                    border.color: yaml.focus ? "steelblue" : "transparent"
                    border.width: 2
                }
            } 
        }
        Component.onCompleted: {
            Julia.to_yaml();
            yaml.text = julia_arguments.observable_yaml
        }
    }
    Timer {
        running: julia_arguments.test
        onTriggered: Qt.quit()
    }
}
