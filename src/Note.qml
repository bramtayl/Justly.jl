import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.julialang 1.0

Row {
    SmallButton {
        text: "+"
        onClicked: {
            notes_model.insert(index, [])
            Julia.to_yaml()
        }
    }
    Column {
        spacing: small_spacing
        SmallButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: remove_text
            onClicked: {
                notes_model.remove(index)
                Julia.to_yaml()
            }
        }
        Interval {
            id: interval
        }
        Row {
            SmallButton {
                text: "▶️"
                onPressed: {
                    Julia.press(chord_index, index)
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
                    Julia.to_yaml()
                }
            }
        }
        RowLayout {
            width: interval.width
            Text {
                text: "🔊 "
            }
            Slider {
                Layout.fillWidth: true
                snapMode: Slider.SnapAlways
                stepSize: 1
                value: volume
                from: 0
                to: 100
                onMoved: {
                    volume = value
                    Julia.to_yaml()
                }
            }
        }
    }
}