import QtQuick 2.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Column {
    property int chord_index: index
    width: chords_view.width
    Button {
        text: "+"
        onClicked: {
            chords_model.insert(index, [])
            yaml.text = Julia.to_yaml()
        }
    }
    RowLayout {
        width: parent.width
        Button {
            text: "−"
            onClicked: {
                chords_model.remove(index)
                yaml.text = Julia.to_yaml()
            }
        }
        Column {
            id: modulation
            TextField {
                text: words
                onEditingFinished: {
                    words = text
                    yaml.text = Julia.to_yaml()
                }
            }
            Row {
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "key = "
                }
                Interval { }
            }
            Row {
                Button {
                    text: "▶️"
                    onPressed: {
                        Julia.press(index, -1)
                    }
                    onReleased: {
                        Julia.release()
                    }
                    onCanceled: {
                        Julia.release()
                    }
                }
                Beats { }
            }
        }
        ToolSeparator {
            implicitHeight: modulation.height
        }
        ListView {
            Layout.fillWidth: true
            // notes are slightly taller than modulations
            height: modulation.height + 15
            orientation: ListView.Horizontal
            model: notes_model
            delegate: Note { }
            footer: Button {
                text: "+"
                onClicked: {
                    notes_model.append([])
                    yaml.text = Julia.to_yaml()
                }
            }
            snapMode: ListView.SnapToItem
            clip: true
        }
    }
}