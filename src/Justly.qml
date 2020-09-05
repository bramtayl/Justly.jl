import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQml.Models 2.15
import org.julialang 1.0

ApplicationWindow {
    visible: true
    id: window
    property int square_side: 40
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
            Row {
                spacing: window.spacing
                Button {
                    text: "Copy"
                    onClicked: {
                        yaml.text = Julia.make_yaml(chords)
                        yaml.select(0, yaml.length - 1)
                        yaml.copy()
                    }
                }
                TextField {
                    id: base_frequency
                    text: qsTr("440")
                }
                Text {
                    text: "hz"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                spacing: window.spacing
                Button {
                    text: "+"
                    onClicked: {
                        chords.insert(0, []);
                        Julia.update_frequencies(chords, base_frequency.text);
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
                                model: notes
                                delegate: Row {
                                    spacing: window.spacing
                                    Column {
                                        spacing: window.spacing
                                        Button {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: index > 0 ? "-" : ""
                                            width: window.square_side
                                            onClicked: {
                                                if (index > 0) {
                                                    notes.remove(index)
                                                }
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
                                                        TextField {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: numerator
                                                            width: window.square_side
                                                            onEditingFinished: {
                                                                numerator = text;
                                                                Julia.update_frequencies(chords, base_frequency.text);
                                                            }
                                                        }
                                                        ToolSeparator {
                                                            orientation: Qt.Horizontal
                                                            width: parent.width
                                                        }
                                                        TextField {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: denominator
                                                            width: window.square_side
                                                            onEditingFinished: {
                                                                denominator = text;
                                                                Julia.update_frequencies(chords, base_frequency.text);
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "2"
                                                    }
                                                    TextField {
                                                        anchors.horizontalCenter: parent.Top
                                                        text: octave
                                                        width: window.square_side
                                                        onEditingFinished: {
                                                            octave = text;
                                                            Julia.update_frequencies(chords, base_frequency.text);
                                                        }
                                                    }
                                                }
                                                Row {
                                                    spacing: window.spacing
                                                    Button {
                                                        text: "▶"
                                                        width: window.square_side
                                                        onClicked: {
                                                            Julia.sink_play_note(frequency)
                                                        }
                                                    }
                                                    TextField {
                                                        text: beats
                                                        width: window.square_side
                                                        onEditingFinished: {
                                                            beats = text
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Button {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizonalCenter
                                        text: "+"
                                        width: window.square_side
                                        onClicked: {
                                            notes.insert(index + 1, [])
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
                                Julia.update_frequencies(chords, base_frequency.text);
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
