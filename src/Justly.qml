import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    RowLayout {
        height: parent.height
        width: parent.width
        ColumnLayout {
            height: parent.height
            Layout.alignment: Qt.AlignTop
            Button {
                text: "Import"
                onClicked: {
                    Julia.from_yaml(yaml.text)
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
                text: "+"
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
