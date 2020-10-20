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
    RowLayout {
        width: parent.width - default_spacing
        height: parent.height - default_spacing - default_spacing
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: default_spacing
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
                    selectByMouse: true
                    height: parent.height
                    background: Rectangle {
                        color: positive_color
                    }
                    Component.onCompleted: {
                        update_yaml()
                    }
                }
            }
        }
        ListTemplate {
            id: chords_view
            model: chords_model
            Layout.fillWidth: true
            Layout.fillHeight: true
            delegate: Chord { }
            footer: AppendButton {
                model: chords_model
            }
            ScrollBar.vertical: ScrollBar { }
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
    function update_yaml() {
        yaml.text = Julia.to_yaml()
    }
}
