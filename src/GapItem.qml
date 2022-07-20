import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Column {
    id: gap_item
    property var item
    property var selectable_parent
    Gap {
        width: rectangle.width
        gap_index: index
        selectable_parent: gap_item.selectable_parent
    }
    MouseArea {
        width: rectangle.width
        height: rectangle.height
        onPressed: {
            if (mouse.modifiers & Qt.ShiftModifier) {
                selectable_parent.select_item_range(index)
            } else {
                selectable_parent.select_item(index)
            }
        }
        Rectangle {
            id: rectangle
            width: item.width + 2 * default_spacing
            height: item.height  + 2 * default_spacing
            color: (selectable_parent.selection_start <= index & index < selectable_parent.selection_end) ? "light gray" : "white"
            data: item
        }
    }
}
