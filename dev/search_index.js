var documenterSearchIndex = {"docs":
[{"location":"#Justly","page":"Public interface","title":"Justly","text":"","category":"section"},{"location":"","page":"Public interface","title":"Public interface","text":"","category":"page"},{"location":"","page":"Public interface","title":"Public interface","text":"Modules = [Justly]","category":"page"},{"location":"#Justly.edit_song-Tuple{Any}","page":"Public interface","title":"Justly.edit_song","text":"function edit_song(song_file; \n    ramp = 0.1s, \n    number_of_tasks = nthreads() - 2, \n    test = false, \n    keyword_arguments...\n)\n\nUse to edit songs interactively.  The interface might be slow at first while Julia is compiling.\n\nsong_file is a YAML string or a vector of Chords. Will be created if it doesn't exist.\nnumber_of_tasks is the number of tasks to use to process data. Defaults to 2 less than the number of threads; we need 1 master thread for QML and 1 master thread for AudioSchedules.\nIf test is true, will open the editor briefly to test it.\nkeyword_arguments will be passed to read_justly.\n\nFor more information, see the README.\n\njulia> using Justly\n\njulia> edit_song(joinpath(pkgdir(Justly), \"test\", \"test_song_file.justly\"); test = true)\n\n\n\n\n\n","category":"method"},{"location":"#Justly.pedal-Tuple{Any}","page":"Public interface","title":"Justly.pedal","text":"pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)\n\nYou can use pedal to make an envelope with a sustain and ramps at the beginning and end.  overlap is the proportion of the ramps that overlap.\n\n\n\n\n\n","category":"method"},{"location":"#Justly.read_justly-Tuple{Any}","page":"Public interface","title":"Justly.read_justly","text":"function read_justly(song_file;\n    wave = SawTooth(7),\n    make_envelope = pedal,\n    ramp = 0.1s,\n    sample_rate = 44100.0Hz,\n    volume = 0.1\n)\n\nCreate a Song from a song file.\n\nmake_envelope is a function to make an envelope, like pedal.\nramp is the onset/offset time, in time units (like s).\nsample_rate is the sample rate, in frequency units (like Hz).\nvolume, ranging from 0-1, is the volume that a single voice is played at.\nwave is a function which takes an angle in radians and returns an amplitude between -1 and 1.\n\njulia> using Justly\n\njulia> song = read_justly(joinpath(pkgdir(Justly), \"test\", \"test_song_file.justly\"));\n\njulia> print(song)\n220.0 Hz; 800.0 bpm\nfirst chord # 1 for 1: 1 for 1, 3/2 for 10\n\nYou can create an AudioSchedule from a song.\n\njulia> using AudioSchedules: AudioSchedule\n\njulia> AudioSchedule(song)\n0.8 s 44100.0 Hz AudioSchedule\n\n\n\n\n\n","category":"method"}]
}
