import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: button
    background: Square {
        id: background
        color: pressed ? "goldenrod" : "yellow"
    }
    onReleased: {
        julia_arguments.observable_sustaining = false
    }
    contentItem: ButtonText {
        text: "▶️"
    }
}