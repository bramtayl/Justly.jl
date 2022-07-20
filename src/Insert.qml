import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    property var selectable_parent
    enabled: selectable_parent.selection_start == selectable_parent.selection_end
    text: "Insert new"
    onPressed: {
        selectable_parent.insert_new()
    }
}