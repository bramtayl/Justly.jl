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
        color: reverse_color
    }
    onClicked: {
        model.remove(index);
        Julia.to_yaml();
        yaml.text = julia_arguments.observable_yaml
    }
}