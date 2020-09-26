import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

RowTemplate {
    ColumnTemplate {
        RemoveButton {
            anchors.horizontalCenter: parent.horizontalCenter
            model: notes_model
        }
        ColumnTemplate {
            RowTemplate {
                TextTemplate {
                    text: "key ×"
                }
                Interval {}
            }
            RowTemplate {
                PlayButton {
                    onPressed: {
                        Julia.press(chord_index, index)
                    }
                    onReleased: {
                        Julia.release()
                    }
                }
                TextTemplate {
                    text: "for"
                }
                Beats {}
            }
        }
    }
    InsertButton {
        model: notes_model
    }
}