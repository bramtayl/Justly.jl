import QtQuick 2.15
import QtQuick.Controls 2.15

MouseArea {
    property int gap_index
    property var selectable_parent
    height: 20
    onPressed: {
        if (mouse.modifiers & Qt.ShiftModifier) {
            selectable_parent.select_gap_range(gap_index)
        } else {
            selectable_parent.select_gap(gap_index)
        }  
    }
    Rectangle {
        anchors.fill: parent
        color: (selectable_parent.selection_start <= gap_index & gap_index <= selectable_parent.selection_end) ? "light gray" : "whitesmoke"
        Text {
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "•"
            font.pointSize: 12
        }
    }
}