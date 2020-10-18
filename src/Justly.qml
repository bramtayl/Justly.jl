import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int default_spacing: 12
    property var large_text_size: 18
    property var positive_color: "white"
    property var negative_color: "black"
    color: negative_color
    ScrollView {
        anchors.fill: parent
        padding: default_spacing
        Row {
            spacing: default_spacing
            Column {
                spacing: default_spacing
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
                    background: Rectangle {
                        color: positive_color
                        border.color: yaml.focus ? "steelblue" : "transparent"
                        border.width: 2
                    }
                }
            }
            Column {
                spacing: default_spacing
                Button {
                    text: "Compile"
                    onClicked: {
                        Julia.compile()
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
            }

        }
        Component.onCompleted: {
            update_yaml()
        }
    }
    Timer {
        running: julia_arguments.test
        onTriggered: Qt.quit()
    }
    function update_yaml() {
        Julia.to_yaml()
        yaml.text = julia_arguments.observable_yaml
    }
}
