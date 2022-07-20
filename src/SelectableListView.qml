import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ListView {
    id: selectable_list
    property int selection_start: 0
    property int selection_end: 0
    clip: true
    Layout.fillHeight: true
    orientation: ListView.Vertical
    implicitWidth: contentItem.childrenRect.width
    footer: Gap {
        width: selectable_list.width
        gap_index: selectable_list.model.count
        selectable_parent: selectable_list
    }
    function insert_new() {
        selectable_list.model.insert(selection_start, [])
    }
    function delete_selection() {
        selectable_list.model.remove(selection_start, selection_end - selection_start)
        selection_end = selection_start
    }
    function select_gap(index) {
        selection_start = index
        selection_end = index
    }
    function select_gap_range(index) {
        if (selection_start > index) {
            selection_start = index
        } else {
            selection_end = index
        }
    }
    function select_item(index) {
        selection_start = index
        selection_end = index + 1
    }
    function select_item_range(index) {
        if (selection_start > index) {
            selection_start = index
        } else {
            selection_end = index + 1
        }
    }
}