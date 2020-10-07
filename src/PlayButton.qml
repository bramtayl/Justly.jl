import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: button
    background: Square {
        id: background
        color: button.down ? "goldenrod" : "yellow"
    }
    contentItem: ButtonText {
        text: "▶️"
    }
}