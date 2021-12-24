import QtQuick 2.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Column {
    property int chord_index: index
    width: chords_view.width
    SmallButton {
        text: add_text
        onClicked: {
            chords_model.insert(index, [])
        }
    }
    RowLayout {
        width: parent.width
        SmallButton {
            text: remove_text
            onClicked: {
                chords_model.remove(index)
            }
        }
        Column {
            id: modulation
            spacing: small_spacing
            TextField {
                text: words
                onEditingFinished: {
                    words = text
                }
                height: small_height
                width: parent.width
            }
            Row {
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "key = "
                }
                Interval { }
            }
            Row {
                SmallButton {
                    text: "▶️"
                    onPressed: {
                        Julia.press(index, -1)
                    }
                    onReleased: {
                        Julia.release()
                    }
                    // this doesn't seem to work?
                    onCanceled: {
                        Julia.release()
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: " for "
                }
                SmallSpinBox {
                    from: -99
                    value: beats
                    onValueModified: {
                        beats = value
                    }
                }
            }
        }
        ToolSeparator {
            implicitHeight: parent.height
        }
        ListView {
            id: notes
            Layout.fillWidth: true
            implicitHeight: contentItem.childrenRect.height
            orientation: ListView.Horizontal
            model: notes_model
            delegate: Note { }
            footer: SmallButton {
                text: add_text
                onClicked: {
                    notes_model.append([])
                }
            }
            snapMode: ListView.SnapToItem
            clip: true
        }
    }
}