import QtQuick 2.15
import QtQuick.Controls 2.15
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
        spacing: parent.spacing
        Rectangle {
            width: note.width
            height: note.height
            color: "lightgoldenrodyellow"
            Row {
                id: note
                spacing: window.spacing
                padding: window.spacing
                Column {
                    spacing: parent.spacing
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
                Text {
                    text: "× 2"
                    anchors.verticalCenter: parent.verticalCenter
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
            spacing: parent.spacing
            PlayButton {
                visible: index > 0
                onPressed: {
                    Julia.press(chord_index, index)
                }
                onReleased: {
                    Julia.release()
                }
            }
            Text {
                text: " for "
                anchors.verticalCenter: parent.verticalCenter
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