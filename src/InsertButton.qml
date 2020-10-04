import org.julialang 1.0

AddButton {
    onClicked: {
        model.insert(index + 1, []);
        Julia.to_yaml();
        yaml.text = julia_arguments.observable_yaml
    }
}