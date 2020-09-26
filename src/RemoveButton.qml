import QtQuick.Controls 2.15

RoundButton {
    property var model
    text: "−"
    onClicked: {
        model.remove(index)
    }
}