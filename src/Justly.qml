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
        Column {
            spacing: window.spacing
            Row {
                spacing: parent.spacing
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
