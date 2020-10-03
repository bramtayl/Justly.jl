import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int default_spacing: 12
    property var button_size: 40
    property var large_text: 24
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
                model: chords
            }
            ListTemplate {
                model: chords
                delegate: Chord { }
            }
            TextEdit {
                id: yaml
                selectByMouse: true
                readOnly: true
                color: reverse_color
                font.pointSize: small_text
            }         
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
