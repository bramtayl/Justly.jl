import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

RowTemplate {
    ColumnTemplate { 
        RemoveButton {
            anchors.horizontalCenter: parent.horizontalCenter
            model: notes_model
        }
        RowTemplate {
            Key { }
            Times { }
            Interval {}
        }
        RowTemplate {
            anchors.right: parent.right
            PlayButton {
                onPressed: {
                    Julia.press(chord_index, index)
                }
                onReleased: {
                    Julia.release()
                }
            }
            For { }
            Beats { }
        }
    }
    InsertButton {
        model: notes_model
    }
}