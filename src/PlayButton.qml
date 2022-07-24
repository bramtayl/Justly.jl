import QtQuick 2.15
import QtQuick.Controls 2.15
import org.julialang 1.0

Button {
    onReleased: {
        // stop playing when the user releases the button
        Julia.release()
    }
        // release if canceled too
    onCanceled: {
        Julia.release()
    }
}