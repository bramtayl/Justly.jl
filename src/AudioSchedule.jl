function add_note!(a_schedule, song, note, time, key)
    push!(
        a_schedule,
        Map(Scale(song.volume * note.volume / 100), Map(song.wave, Cycles(key * Rational(note.interval)))),
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

function AudioSchedule(song::Song; chords = song.chords, initial_key = song.initial_key)
    time = 0s
    a_schedule = AudioSchedule(; sample_rate = song.sample_rate)
    key = initial_key
    for chord in chords
        time, key = add_chord!(a_schedule, song, chord, time, key)
    end
    a_schedule
end
