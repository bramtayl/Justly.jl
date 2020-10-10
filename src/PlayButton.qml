import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Button {
    id: button
    background: Square {
        id: background
        color: pressed ? "goldenrod" : "yellow"
    }
    onReleased: {
        Julia.release()
    }
    contentItem: ButtonText {
        text: "▶️"
    }
}