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
    RowLayout {
        height: parent.height
        width: parent.width
        ColumnLayout {
            height: parent.height
            Layout.alignment: Qt.AlignTop
            Button {
                text: "↓"
                font.pointSize: button_text_size
                implicitHeight: button_side
                implicitWidth: button_side
                onClicked: {
                    yaml.text = Julia.from_yaml(yaml.text)
                }
            }
            ScrollView {
                Layout.fillHeight: true
                Layout.maximumHeight: implicitHeight
                TextArea {
                    id: yaml
                    height: parent.height
                    selectByMouse: true
                    Component.onCompleted: {
                        yaml.text = Julia.to_yaml()
                    }
                }
            }
        }
        ListView {
            id: chords_view
            clip: true
            Layout.fillHeight: true
            Layout.fillWidth: true
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
                    yaml.text = Julia.to_yaml()
                }
            }
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
