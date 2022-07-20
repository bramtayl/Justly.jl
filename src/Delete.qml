import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    property var selectable_parent
    enabled: selectable_parent.selection_end > selectable_parent.selection_start
    text: "Delete selection"
    onPressed: {
        selectable_parent.delete_selection()
    }
}