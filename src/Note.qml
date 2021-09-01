import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Row {
    Button {
        text: "+"
        onClicked: {
            notes_model.insert(index, [])
            yaml.text = Julia.to_yaml()
        }
    }
    Column {
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "−"
            onClicked: {
                notes_model.remove(index)
                yaml.text = Julia.to_yaml()
            }
        }
        Interval {}
        Row {
            Button {
                text: "▶️"
                onPressed: {
                    Julia.press(chord_index, index)
                }
                onCanceled: {
                    Julia.release()
                }
                onReleased: {
                    Julia.release()
                }
            }
            Beats { }
        }
    }
}