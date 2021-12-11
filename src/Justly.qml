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
    ScrollView {
        width: parent.width
        height: parent.height
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
    Component.onCompleted: {
        // Julia.press(-1, -1)
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
