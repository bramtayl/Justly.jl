import org.julialang 1.0

AddButton {
    onClicked: {
        model.insert(index + 1, []);
        yaml.text = Julia.make_yaml()
    }
}