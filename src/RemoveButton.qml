import QtQuick.Controls 2.15
import org.julialang 1.0

Button {
    id: button
    property var model
    background: Circle {
        id: background
        color: button.down ? "firebrick" : "red"
    }
    contentItem: ButtonText {
        text: "−"
    }
    onClicked: {
        model.remove(index)
        update_yaml()
    }
}