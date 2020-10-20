import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Button {
    id: button
    property var event_id
    background: Square {
        id: background
        color: pressed ? "goldenrod" : "yellow"
    }
    onReleased: {
        Julia.release(event_id)
    }
    onCanceled: {
        Julia.release(event_id)
    }
    contentItem: ButtonText {
        text: "▶️"
    }
}