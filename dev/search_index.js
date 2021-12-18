var documenterSearchIndex = {"docs":
[{"location":"#Justly","page":"Public interface","title":"Justly","text":"","category":"section"},{"location":"","page":"Public interface","title":"Public interface","text":"","category":"page"},{"location":"","page":"Public interface","title":"Public interface","text":"Modules = [Justly]","category":"page"},{"location":"#Justly.Chord","page":"Public interface","title":"Justly.Chord","text":"mutable struct Chord\n\nA Julia representation of a chord. Pass a vector of Chords to edit_song.\n\n\n\n\n\n","category":"type"},{"location":"#Justly.edit_song-Tuple{Any}","page":"Public interface","title":"Justly.edit_song","text":"function edit_song(song_file; \n    ramp = 0.1s, \n    number_of_tasks = nthreads() - 2, \n    test = false, \n    keyword_arguments...\n)\n\nUse to edit songs interactively.  The interface might be slow at first while Julia is compiling.\n\nsong_file is a YAML string or a vector of Chords. Will be created if it doesn't exist.\nnumber_of_tasks is the number of tasks to use to process data. Defaults to 2 less than the number of threads; we need 1 master thread for QML and 1 master thread for AudioSchedules.\nIf test is true, will open the editor briefly to test it.\nkeyword_arguments will be passed to read_song.\n\nFor more information, see the README.\n\njulia> using Justly\n\njulia> edit_song(joinpath(pkgdir(Justly), \"test\", \"test_song_file.yml\"); test = true)\n\n\n\n\n\n","category":"method"},{"location":"#Justly.pedal-Tuple{Any}","page":"Public interface","title":"Justly.pedal","text":"pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)\n\nYou can use pedal to make an envelope with a sustain and ramps at the beginning and end.  overlap is the proportion of the ramps that overlap.\n\n\n\n\n\n","category":"method"},{"location":"#Justly.read_song-Tuple{Any}","page":"Public interface","title":"Justly.read_song","text":"function read_song(song_file;\n    wave = SawTooth(7),\n    make_envelope = pedal,\n    ramp = 0.1s,\n    sample_rate = 44100.0Hz,\n    volume = 0.1\n)\n\nCreate an AudioSchedule from a song file.\n\nmake_envelope is a function to make an envelope, like pedal.\nramp is the onset/offset time, in time units (like s).\nsample_rate is the sample rate, in frequency units (like Hz).\nvolume, ranging from 0-1, is the volume that a single voice is played at.\nwave is a function which takes an angle in radians and returns an amplitude between -1 and 1.\n\nTop-level chord lists will be unnested, so you can use YAML anchors to repeat themes.\n\njulia> using Justly\n\njulia> read_song(joinpath(pkgdir(Justly), \"test\", \"test_song_file.yml\"))\n0.65 s 44100.0 Hz AudioSchedule\n\n\n\n\n\n","category":"method"}]
}
