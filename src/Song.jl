
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

precompile(Song, (Vector{Chord},))

function as_dict(song::Song)
    Dict(
        "volume" => song.volume_observable[],
        "frequency" => song.frequency_observable[],
        "tempo" => song.tempo_observable[],
        "chords" => map(as_dict, song.chords),
    )
end

precompile(as_dict, (Song,))

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

precompile(from_dict, (Type{Chord}, Dict{String, Int}, Vector{Instrument}))

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
julia> using AudioSchedules: AudioSchedule, s

julia> audio_schedule = AudioSchedule()
0.0 s 44100.0 Hz AudioSchedule

julia> push!(audio_schedule, song, 0.0s)

julia> push!(audio_schedule, song, 1.0s)

julia> audio_schedule
1.9700000000000002 s 44100.0 Hz AudioSchedule
```
"""
function read_justly(file, instruments = DEFAULT_INSTRUMENTS)
    from_dict(Song, load_file(file), instruments)
end

precompile(read_justly, (String, Vector{Instrument}))

function write_justly(file, song)
    write_file(file, as_dict(song))
end

precompile(write_justly, (Song, String))

export read_justly

function push!(audio_schedule::AudioSchedule, song::Song, start_time = 0.0s; from_chord = 1)
    float_time = float(start_time)
    volume = song.volume_observable[]
    frequency = (song.frequency_observable[])Hz
    beat_duration = (60 / song.tempo_observable[])s
    for (index, chord) in enumerate(song.chords)
        frequency = frequency * Rational(chord.modulation.interval)
        volume = volume * chord.modulation.volume
        if index >= from_chord
            for note in chord.notes
                note.instrument.note_function!(
                    audio_schedule,
                    float_time,
                    note.beats * beat_duration,
                    volume * note.volume,
                    frequency * Rational(note.interval),
                )
            end
            float_time = float_time + chord.modulation.beats * beat_duration
        end
    end
    nothing
end

precompile(push!, (AudioSchedule, Song, FLOAT_SECONDS))
