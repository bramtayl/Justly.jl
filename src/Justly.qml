import QtQuick 2.5
import QtQuick.Window 2.5
import QtQuick.Controls 2.5
import org.julialang 1.0

ApplicationWindow {
    visible: true
    ScrollView {
        anchors.fill: parent
        Column {
            AddButton {
                onClicked: {
                    chords.insert(0, []);
                }
            }
            ListTemplate {
                id: chords_view
                model: chords
                delegate: Chord { }
            }
            PlayButton {
                onClicked: {
                    Julia.play_song()
                }
            }
            Button {
                contentItem: HeaderTemplate {
                    text: "📋"
                }
                onClicked: {
                    yaml.text = Julia.make_yaml()
                    yaml.select(0, yaml.length - 1)
                    yaml.copy()
                }
            }
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
    TextEdit {
        id: yaml
        visible: false
        text: ""
    }
}
