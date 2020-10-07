import QtQuick.Controls 2.15

Button {
    id: button
    property var model
    background: Circle {
        id: background
        anchors.centerIn: parent
        color: button.down ? "green" : "limegreen"
    }
    contentItem: ButtonText {
        text: "+"
        color: positive_color
    }
}