
struct Song
    instruments::Vector{Instrument}
    chords::Vector{Chord}
    # use observables so changes in qml will propagate back
    volume_observable::Observable{Float64}
    frequency_observable::Observable{Float64}
    tempo_observable::Observable{Float64}
    precompiling_observable::Observable{Bool}
end

function Song(
    instruments;
    chords = Chord[],
    volume = 0.2,
    frequency = 200.0,
    tempo = 200.0,
    precompiling = false,
)
    Song(
        instruments,
        chords,
        Observable(volume),
        Observable(frequency),
        Observable(tempo),
        Observable(precompiling),
    )
end

function as_dict(song::Song)
    Dict(
        "volume" => song.volume_observable[],
        "frequency" => song.frequency_observable[],
        "tempo" => song.tempo_observable[],
        "chords" => map(as_dict, song.chords),
    )
end

function from_dict(::Type{Song}, dict, instruments)
    Song(
        instruments;
        volume = dict["volume"],
        frequency = dict["frequency"],
        tempo = dict["tempo"],
        chords = map(dict["chords"]) do dict
            from_dict(Chord, dict, instruments)
        end,
    )
end

"""
    read_justly(file, instruments = DEFAULT_INSTRUMENTS)

Create a `Song` from a song file.

`instruments` are a vector of [`Instrument`](@ref)s, with the default [`DEFAULT_INSTRUMENTS`](@ref).

```jldoctest read_justly
julia> using Justly

julia> song = read_justly(joinpath(pkgdir(Justly), "examples", "simple.yml"));
```

You can add a song to an `AudioSchedule` at a start time.
You can use this to overlap multiple songs at differnt times.

```jldoctest read_justly
julia> using AudioSchedules: AudioSchedule, Hz, s

julia> audio_schedule = AudioSchedule(sample_rate = 44100Hz)
0.0 s 44100.0 Hz AudioSchedule

julia> push!(audio_schedule, song, 0.0s)

julia> push!(audio_schedule, song, 1.0s)

julia> audio_schedule
2.27 s 44100.0 Hz AudioSchedule
```
"""
function read_justly(file, instruments = DEFAULT_INSTRUMENTS)
    from_dict(Song, load_file(file), instruments)
end

precompile(read_justly, (String, Vector{Instrument}))

function write_justly(file, song)
    write_file(file, as_dict(song))
end

export read_justly

mutable struct PlayState
    volume::Float64
    frequency::typeof(0.0Hz)
    beat_duration::typeof(0.0s)
    time::typeof(0.0s)
end

function PlayState(song::Song, time)
    PlayState(
        song.volume_observable[],
        (song.frequency_observable[])Hz,
        (60 / song.tempo_observable[])s,
        time,
    )
end

function update_play_state!(play_state, chord)
    play_state.frequency = play_state.frequency * Rational(chord.modulation.interval)
    play_state.volume = play_state.volume * chord.modulation.volume
    nothing
end

function add_notes!(audio_schedule, play_state, notes)
    for note in notes
        note.instrument.note_function!(
            audio_schedule,
            play_state.time,
            note.beats * play_state.beat_duration,
            play_state.volume * note.volume,
            play_state.frequency * Rational(note.interval),
        )
    end
    nothing
end

function add_chord!(audio_schedule, play_state, chord)
    add_notes!(audio_schedule, play_state, chord.notes)
    play_state.time = play_state.time + chord.modulation.beats * play_state.beat_duration
    nothing
end

function push!(audio_schedule::AudioSchedule, song::Song, start_time = 0.0s)
    play_state = PlayState(song, start_time)
    for chord in song.chords
        update_play_state!(play_state, chord)
        add_chord!(audio_schedule, play_state, chord)
    end
    nothing
end

precompile(push!, (AudioSchedule, Song, typeof(0.0s)))

@noinline function add_notes!(
    audio_schedule,
    song,
    chord_index,
    first_note_index,
    last_note_index,
)
    chords = song.chords
    play_state = PlayState(song, 0.0s)
    for chord in chords[1:(chord_index - 1)]
        update_play_state!(play_state, chord)
    end
    chord = chords[chord_index]
    update_play_state!(play_state, chord)
    add_notes!(audio_schedule, play_state, chord.notes[first_note_index:last_note_index])
    nothing
end

precompile(add_notes!, (AudioSchedule, Song, Int, Int, Int))

@noinline function add_chords!(
    audio_schedule,
    song,
    first_chord_index,
    last_chord_index = length(song.chords),
)
    play_state = PlayState(song, 0.0s)
    chords = song.chords
    for chord in chords[1:(first_chord_index - 1)]
        update_play_state!(play_state, chord)
    end
    for chord in chords[first_chord_index:last_chord_index]
        update_play_state!(play_state, chord)
        add_chord!(audio_schedule, play_state, chord)
    end
    nothing
end

precompile(add_chords!, (AudioSchedule, Song, Int, Int))
