import QtQuick 2.5
import QtQuick.Controls 2.5
import org.julialang 1.0

Grid {
    columns: 2
    TextField {
        text: lyrics
        visible: index == 0
        width: note.width
        onEditingFinished: {
            lyrics = text
        }
    }
    RemoveButton {
        visible: index > 0
        onClicked: {
            if (index > 0) {
                notes_model.remove(index)
            }
        }
    }
    AddButton {
        onClicked: {
            notes_model.insert(index + 1, [])
        }
    }
    Column {
        id: note
        Row {
            TextTemplate {
                text: index == 0 ? "key = key × " : "key × "
            }
            Column {
                SpinBox {
                    value: numerator
                    from: 1
                    onValueModified: {
                        numerator = value
                    }
                }
                ToolSeparator {
                    orientation: Qt.Horizontal
                    width: parent.width
                }
                SpinBox {
                    value: denominator
                    from: 1
                    onValueModified: {
                        denominator = value
                    }
                }
            }
            TextTemplate {
                text: "× 2"
            }
            SpinBox {
                value: octave
                from: -99
                onValueModified: {
                    octave = value
                }
            }
        }
        Row {
            PlayButton {
                visible: index > 0
                onClicked: {
                    Julia.play_note(chord_index, index)
                }
            }
            TextTemplate {
                visible: index == 0
                text: "Wait"
            }
            TextTemplate {
                text: " for "
            }
            SpinBox {
                value: beats
                from: -99
                onValueModified: {
                    beats = value
                }
            }
        }
    }
}