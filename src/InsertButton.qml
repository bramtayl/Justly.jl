import org.julialang 1.0

AddButton {
    onClicked: {
        model.insert(index, [])
        update_yaml()
    }
}