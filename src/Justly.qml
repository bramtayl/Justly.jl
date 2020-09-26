import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int spacing: 10
    color: "white"
    ScrollView {
        anchors.fill: parent
        padding: window.spacing
        ColumnTemplate {
            RowTemplate {
                PlayButton {
                    onClicked: {
                        Julia.play()
                    }
                }
                Button {
                    text: "📋"
                    onClicked: {
                        yaml.text = Julia.make_yaml()
                        yaml.select(0, yaml.length - 1)
                        yaml.copy()
                    }
                }
            }
            StartButton {
                model: chords
            }
            ListTemplate {
                model: chords
                delegate: Chord { }
            }
            TextEdit {
                id: yaml
            }
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
