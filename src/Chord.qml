import QtQuick 2.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Column {
    spacing: default_spacing
    property int chord_index: index
    width: chords_view.width
    InsertButton {
        model: julia_arguments.chords_model
    }
    RowLayout {
        width: parent.width - default_spacing
        spacing: default_spacing
        RemoveButton {
            Layout.alignment: Qt.AlignHCenter
            model: julia_arguments.chords_model
        }
        Column {
            id: modulation
            spacing: default_spacing
            Row {
                spacing: default_spacing
                PlayButton {
                    onPressed: {
                        Julia.play(index)
                    }
                }
                SmallText {
                    text: "from"
                }
            }
            Row {
                spacing: default_spacing
                DisplayText {
                    text: "𝄞"
                }
                SmallText {
                    text: "="
                }
                Interval { }
            }
            Row {
                spacing: default_spacing
                anchors.right: parent.right
                DisplayText {
                    text: "⏸"
                }
                Beats { }
            }
            Row {
                spacing: default_spacing
                SmallText {
                    text: "words:"
                }
                TextField {
                    text: words
                    onEditingFinished: {
                        words = text
                    }
                }
            }
        }
        ToolSeparator {
            orientation: Qt.Vertical
            Layout.alignment: Qt.AlignTop
            implicitHeight: modulation.height
        }
        ListTemplate {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            height: modulation.height
            orientation: ListView.Horizontal
            model: notes_model
            delegate: Note { }
            footer: AppendButton {
                model: notes_model
            }
            ScrollBar.horizontal: ScrollBar { }
        }
    }
}