import QtQuick 2.5
import QtQuick.Controls 2.5
import org.julialang 1.0

Grid {
    spacing: window.spacing
    horizontalItemAlignment: Grid.AlignHCenter
    columns: 2
    TextField {
        text: lyrics
        visible: index == 0
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
        spacing: window.spacing
        Rectangle {
            width: note.width + 2 * window.spacing
            height: note.height + 2 * window.spacing
            color: "lightgoldenrodyellow"
            Row {
                id: note
                spacing: window.spacing
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: window.spacing
                Column {
                    spacing: window.spacing
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
        }
        Row {
            spacing: window.spacing
            PlayButton {
                visible: index > 0
                onClicked: {
                    Julia.play_note(chord_index, index)
                }
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