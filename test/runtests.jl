using Justly
using Documenter: doctest

doctest(Justly)
ENV["QT_QPA_PLATFORM"] = "xcb"
chords = Chord[]
edit_song(chords; test = true)
