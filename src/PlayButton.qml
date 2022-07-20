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