import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Grid {
    id: note_grid
    x: default_spacing
    y: default_spacing
    spacing: default_spacing
    flow: Grid.TopToBottom
    verticalItemAlignment: Grid.AlignVCenter
    rows: 2
    Text {
        text: "Instrument"
    }
    ComboBox {
        model: instruments_model
        currentIndex: instrument_number
        onActivated: {
            instrument_number = index
        }
    }
    Text {
        text: "Interval"
    }
    Interval { }
    Text {
        text: "Beats"
    }
    Beats { }
    Text {
        text: "Volume"
    }
    Volume { }
}
