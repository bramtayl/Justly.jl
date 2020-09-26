import QtQuick 2.15

ListView {
    spacing: window.spacing
    displaced: Transition {
        NumberAnimation {properties: "x,y"}
    }
    width: contentItem.childrenRect.width
    height: contentItem.childrenRect.height
}