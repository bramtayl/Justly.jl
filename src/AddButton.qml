import QtQuick.Controls 2.15

Button {
    id: button
    property var model
    background: Circle {
        anchors.centerIn: parent
        color: button.down ? "green" : "limegreen"
    }
    contentItem: ButtonText {
        text: "+"
    }
}