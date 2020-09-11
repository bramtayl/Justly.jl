import QtQuick 2.5
import QtQuick.Window 2.5
import QtQuick.Controls 2.5
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int spacing: 5
    color: "white"
    ScrollView {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.topMargin: 5
        Column {
            spacing: window.spacing
            Row {
                spacing: window.spacing
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
            AddButton {
                onClicked: {
                    chords.insert(0, []);
                }
            }
            ListTemplate {
                id: chords_view
                model: chords
                delegate: Chord { }
                spacing: window.spacing
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
