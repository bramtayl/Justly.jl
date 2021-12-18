function add_note!(a_schedule, song, note, time, key)
    add!(
        a_schedule,
        Map(Scale(song.volume), Map(song.wave, Cycles(key * Rational(note.interval)))),
        time,
        song.make_envelope(note.beats * song.beat_duration)...,
    )
end

function add_chord!(a_schedule, song, chord, time, key)
    modulation = chord.modulation
    key = key * Rational(modulation.interval)
    for note in chord.notes
        add_note!(a_schedule, song, note, time, key)
    end
    time + modulation.beats * song.beat_duration, key
end

function add_chord!(a_schedule, song, chord_vectors::Vector, time, key)
    for chords in chord_vectors
        key, time = add_chord!(a_schedule, song, chords, time, key)
    end
    time, key
end

function make_schedule(song::Song; chords = song.chords, initial_key = song.initial_key)
    time = 0s
    a_schedule = AudioSchedule(; sample_rate = song.sample_rate)
    key = initial_key
    for chord in chords
        time, key = add_chord!(a_schedule, song, chord, time, key)
    end
    a_schedule
end

"""
    function read_song(song_file;
        wave = SawTooth(7),
        make_envelope = pedal,
        ramp = 0.1s,
        sample_rate = 44100.0Hz,
        volume = 0.1
    )

Create an `AudioSchedule` from a song file.

- `make_envelope` is a function to make an envelope, like [`pedal`](@ref).
- `ramp` is the onset/offset time, in time units (like `s`).
- `sample_rate` is the sample rate, in frequency units (like `Hz`).
- `volume`, ranging from 0-1, is the volume that a single voice is played at.
- `wave` is a function which takes an angle in radians and returns an amplitude between -1 and 1.

Top-level chord lists will be unnested, so you can use YAML anchors to repeat themes.

```jldoctest make_schedule
julia> using Justly

julia> read_song(joinpath(pkgdir(Justly), "test", "test_song_file.yml"))
0.65 s 44100.0 Hz AudioSchedule
```
"""
function read_song(song_file; keyword_arguments...)
    make_schedule(
        from_yamlable(
            Song,
            load_file(song_file);
            keyword_arguments...,
        ),
    )
end

export read_song
