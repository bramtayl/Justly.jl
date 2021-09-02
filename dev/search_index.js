var documenterSearchIndex = {"docs":
[{"location":"#Justly","page":"Public interface","title":"Justly","text":"","category":"section"},{"location":"","page":"Public interface","title":"Public interface","text":"","category":"page"},{"location":"","page":"Public interface","title":"Public interface","text":"Modules = [Justly]","category":"page"},{"location":"#Justly.Chord","page":"Public interface","title":"Justly.Chord","text":"mutable struct Chord\n\nA Julia representation of a chord. Pass a vector of Chords to edit_song.\n\n\n\n\n\n","category":"type"},{"location":"#Justly.edit_song-Tuple{Any}","page":"Public interface","title":"Justly.edit_song","text":"function edit_song(song; ramp = 0.1s, options...)\n\nUse to edit songs interactively.  The interface might be slow at first while Julia is compiling.\n\nsong is a YAML string or a vector of Chords.\nramp is the onset/offset time, in time units (like s).\noptions will be passed to make_schedule.\n\nFor more information, see the README.\n\nTry running ENV[\"QT_QPA_PLATFORM\"] = \"xcb\" on Wayland.\n\njulia> using Justly\n\njulia> song = Chord[];\n\njulia> edit_song(song)\n\n\n\n\n\n","category":"method"},{"location":"#Justly.make_schedule-Tuple{Any}","page":"Public interface","title":"Justly.make_schedule","text":"function make_schedule(song;\n    beat_duration = 0.6s,\n    initial_key = 220Hz,\n    make_envelope = pedal,\n    sample_rate = 44100Hz,\n    volume = 0.15,\n    wave = SawTooth(7)\n)\n\nCreate an AudioSchedule from your song.\n\nsong is a YAML string or a vector of Chords.\nbeat_duration is the duration of a beat, with time units (like s).\ninitial_key is initial key of your song, in frequency units (like Hz). \nmake_envelope is a function to make an envelope, like pluck or pedal.\nsample_rate is the sample rate, in frequency units (like Hz).\nvolume, ranging from 0-1, is the volume that a single voice is played at.\nwave is a function which takes an angle in radians and returns an amplitude between -1 and 1.\n\nFor more information, see the README.\n\nFor example, to create a simple I-IV-I figure,\n\njulia> using Justly\n\njulia> using YAML: load\n\njulia> make_schedule(\"\"\"\n            - words: \"I\"\n              notes:\n                - {}\n                - interval: \"3/2\"\n                - interval: \"5/4o1\"     \n            - words: \"IV\"\n              interval: \"2/3\"\n              notes:\n                - interval: \"3/2\"\n                - interval: \"5/4o1\"\n                - interval: \"o2\"\n            - words: \"I\"\n              interval: \"3/2\"\n              notes:\n                - {}\n                - interval: \"3/2\"\n                - interval: \"5/4o1\"\n              \n         \"\"\")\n1.85 s 44100.0 Hz AudioSchedule\n\nTop-level lists will be unnested, so you can use YAML anchors to repeat themes.\n\njulia> make_schedule(\"\"\"\n            - &fifth\n                - notes:\n                    - {}\n                    - interval: \"3/2\"\n            - *fifth\n        \"\"\")\n1.25 s 44100.0 Hz AudioSchedule\n\n\n\n\n\n","category":"method"},{"location":"#Justly.pedal-Tuple{Any}","page":"Public interface","title":"Justly.pedal","text":"pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)\n\nYou can use pedal to make an envelope with a sustain and ramps at the beginning and end.  overlap is the proportion of the ramps that overlap.\n\n\n\n\n\n","category":"method"},{"location":"#Justly.pluck-Tuple{Any}","page":"Public interface","title":"Justly.pluck","text":"pluck(duration; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)\n\nYou can use pluck to make an envelope with an exponential decay and ramps at the beginning and end.\n\n\n\n\n\n","category":"method"}]
}
