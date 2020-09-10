import QtQuick 2.5
import QtQuick.Window 2.5
import QtQuick.Controls 2.5
import QtQml.Models 2.5
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int spacing: 10
    color: "white"
    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: song.width + window.spacing * 2
        contentHeight: song.height + window.spacing * 2
        Column {
            id: song
            spacing: window.spacing
            anchors.margins: window.spacing
            anchors.left: parent.left
            anchors.top: parent.top
            Button {
                text: "Copy"
                onClicked: {
                    yaml.text = Julia.make_yaml()
                    yaml.select(0, yaml.length - 1)
                    yaml.copy()
                }
            }
            Row {
                spacing: window.spacing
                Button {
                    text: "+"
                    onClicked: {
                        chords.insert(0, []);
                    }
                }
            }
            ListView {
                id: chords_view
                spacing: window.spacing
                width: contentItem.childrenRect.width
                height: contentItem.childrenRect.height
                clip: true
                model: chords
                delegate: Column {
                    property int chord_index: index
                    spacing: window.spacing
                    Row {
                        spacing: window.spacing
                        Button {
                            text: "-"
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                chords.remove(index)
                            }
                        }
                        Column {
                            spacing: window.spacing
                            Row {
                                spacing: window.spacing
                                TextField {
                                    text: lyrics
                                    onEditingFinished: {
                                        lyrics = text
                                    }
                                }
                            }
                            ListView {
                                spacing: window.spacing
                                implicitWidth: contentItem.childrenRect.width
                                implicitHeight: contentItem.childrenRect.height
                                orientation: ListView.Horizontal
                                model: notes_model
                                delegate: Grid {
                                    horizontalItemAlignment: Grid.AlignHCenter
                                    spacing: window.spacing
                                    columns: 2
                                    Button {
                                        opacity: index > 0
                                        text: "-"
                                        onClicked: {
                                            if (index > 0) {
                                                notes_model.remove(index)
                                            }
                                        }
                                    }
                                    Button {
                                        text: "+"
                                        onClicked: {
                                            notes_model.insert(index + 1, [])
                                        }
                                    }
                                    Row {
                                        spacing: window.spacing
                                        Column {
                                            spacing: window.spacing
                                            Row {
                                                spacing: window.spacing
                                                Column {
                                                    spacing: window.spacing
                                                    SpinBox {
                                                        value: numerator
                                                        from: 1
                                                        editable: true
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
                                                        editable: true
                                                        onValueModified: {
                                                            denominator = value
                                                        }
                                                    }
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "2"
                                                }
                                                SpinBox {
                                                    value: octave
                                                    from: -99
                                                    editable: true
                                                    onValueModified: {
                                                        octave = value
                                                    }
                                                }
                                            }
                                            Row {
                                                spacing: window.spacing
                                                Button {
                                                    visible: index > 0
                                                    text: "▶"
                                                    onClicked: {
                                                        Julia.play_note(chord_index, index)
                                                    }
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "for"
                                                }
                                                SpinBox {
                                                    value: beats
                                                    from: -99
                                                    editable: true
                                                    onValueModified: {
                                                        beats = value
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Row {
                        spacing: window.spacing
                        Button {
                            text: "+"
                            onClicked: {
                                chords.insert(index + 1, []);
                            }
                        }
                    }
                }
            }
            TextEdit {
                id: yaml
                visible: false
                text: ""
            }
        }
    }
    Timer {
        running: test
        onTriggered: Qt.quit()
    }
}
