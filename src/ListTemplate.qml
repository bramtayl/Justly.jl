import QtQuick 2.15

ListView {
    spacing: default_spacing
    displaced: Transition {
        NumberAnimation {properties: "x,y"}
    }
    snapMode: ListView.SnapToItem
    clip: true
}