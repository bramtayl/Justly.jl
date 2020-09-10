module Justly

using AudioSchedules:
    add!, AudioSchedule, Cycles, Hook, Line, Map, Plan, q_str, SawTooth, Scale, seek_peak
using PortAudio: PortAudioStream
using Observables: Observable
using QML: addrole, exec, get_julia_data, ListModel, load, @qmlfunction, qmlfunction, setconstructor
using SampledSignals: samplerate
using Test: @test
using Unitful: Hz, s
using YAML: YAML

"""
    const Justly.WAVE = AudioSchedules.SawTooth(7)

The default sound wave used for [`justly](@ref) and [`justly_interactive`](@ref).
"""
const WAVE = SawTooth(7)

"""
    pluck(duration; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)

The default envelope function used for [`justly`](@ref). An exponential decay
with steep ramps on either side.
"""
function pluck(duration; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)
    ramp = peak / slope
    (0, Line => ramp, peak, Hook(decay, -slope) => duration - ramp, 0)
end
export pluck

"""
    const Justly.ENVELOPE = pluck(1s)

The default envelope used for [`justly_interactive`](@ref).
"""
const ENVELOPE = pluck(1s)

mutable struct Note
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
end

Note() = Note(1, 1, 0, 1)

interval(note::Note) = note.numerator / note.denominator * 2^note.octave

mutable struct Chord
    notes::Vector{Note}
    lyrics::String
    notes_model::ListModel
end

function Chord()
    notes = [Note()]
    Chord(notes, "", ListModel(notes))
end

function as_dict(note::Note)
    Dict(
        "interval" => string(
            note.numerator,
            '/',
            note.denominator,
            'o',
            note.octave,
        ),
        "beats" => note.beats,
    )
end

function as_dict(chord::Chord)
    Dict(
        "notes" => map(as_dict, chord.notes),
        "lyrics" => chord.lyrics,
    )
end

function make_yaml(chords)
    YAML.write(map(as_dict, chords))
end

function play_note(sink, wave, make_envelope, initial_key, chords, chord_index, voice_index)
    key = initial_key
    julia_chord_index = chord_index + 1
    julia_voice_index = voice_index + 1
    for chord in view(chords, 1:julia_chord_index)
        key = key * interval(chord.notes[1])
    end
    frequency = key * interval(chords[julia_chord_index].notes[julia_voice_index])
    plan = Plan(samplerate(sink)Hz)
    add!(plan, Map(wave, Cycles(frequency)), 1s, make_envelope...)
    schedule = AudioSchedule(plan)
    write(sink, read(schedule, length(schedule)))
end

"""
    function justly_interactive(;
        wave = WAVE,
        make_envelope = Justly.ENVELOPE,
        initial_key = 440Hz,
        test = false
    )

Open an interactive interface where you can interactively write Justly text. Once you have
finished writing, you can copy the results to the clipboard as YAML. Then, you can use
[`play_justly`](@ref) to play them.

`wave` should be a function which takes an angle in radians
and returns and amplitude between 0 and 1. `make_envelope` should be a function that takes
a duration in units of time (like `s`) and returns a tuple of envelope segments that can
be splatted into `AudioSchedules.add!`. `initial_key` should be in frequency units, like `Hz`.

The first interval in the chord will modulate the key, and tells how many beats before the
next chord. You can set beats to 0 to overlap, or to a negative number to "time-travel" back
in time. The rest of the intervals in the chord will play notes with a given duration. Their
interval will show their relationship to the key. You can use lyrics to as a way to
keep track of your position in a song, or to make performance notes, but they are optional.
For more information, see the README.

Set `test` to true if you would like to test the GUI but not use it.

```jldoctest
julia> using Justly

julia> justly_interactive(test = true)
```
"""
function justly_interactive(;
    wave = WAVE,
    make_envelope = ENVELOPE,
    initial_key = 440Hz,
    test = false
)

    stream = PortAudioStream(samplerate = 44100)
    sink = stream.sink
    chords = Chord[]
    inner_play_note = let sink = sink, wave = wave, make_envelope = make_envelope, initial_key = initial_key, chords = chords
        (chord_index, voice_index) -> play_note(sink, wave, make_envelope, initial_key, chords, chord_index, voice_index)
    end
    qmlfunction("play_note", inner_play_note)
    inner_make_yaml = let chords = chords
        () -> make_yaml(chords)
    end
    qmlfunction("make_yaml", inner_make_yaml)
    
    load(joinpath(@__DIR__, "Justly.qml"); 
        chords = ListModel(chords), 
        test = test
    )
    
    exec()
    if test
        push!(chords, Chord())
        # note: this is 1, 1 in julia
        inner_play_note(0, 0)
        @test inner_make_yaml() == "- notes:\n    - beats: 1\n      interval: \"1/1o0\"\n  lyrics: \"\"\n"
    end
    close(stream)
    nothing
end
export justly_interactive

function parse_note(note)
    q_str(note["interval"]), note["beats"]
end

function play!(plan::Plan, chord_lyrics, wave, make_envelope, key, clock, beat_duration)
    notes = chord_lyrics["notes"]
    modulation, ahead = parse_note(notes[1])
    key = key * modulation
    for note in notes[2:end]
        ratio, beats = parse_note(note)
        add!(
            plan,
            Map(wave, Cycles(key * ratio)),
            clock,
            make_envelope(beats * beat_duration)...,
        )
    end
    key, clock + ahead * beat_duration
end
function play!(plan::Plan, chords_lyrics::Vector, wave, make_envelope, key, clock, beat_duration)
    for chord_lyrics in chords_lyrics
        key, clock =
            play!(plan, chord_lyrics, wave, make_envelope, key, clock, beat_duration)
    end
    key, clock
end

"""
    function justly(sample_rate, song;
        wave = Justly.WAVE,
        make_envelope = pluck,
        initial_key = 440Hz,
        clock = 0s,
        beat_duration = 1s
    )

Play music in Justly notation. `song` can be read in using `YAML` generated with
[`justly_interactive`](@ref). `wave` should be a function which takes an angle in radians
and returns and amplitude between 0 and 1. `make_envelope` should be a function that takes
a duration in units of time (like `s`) and returns a tuple of envelope segments that can
be splatted into `AudioSchedules.add!`. `initial_key` should the frequency of the initial
key for your song, in units of frequency (like `Hz`). `beat_duration` should specify the
amount of duration of a beat with units of time (like `s`).

For example, to create a simple I-IV-I figure,

```jldoctest justly
julia> using Justly

julia> using YAML

julia> using Unitful: Hz

julia> const SAMPLE_RATE = 44100Hz;

julia> play(justly(SAMPLE_RATE, YAML.load(\"""
            - notes:
                - beats: 1
                  interval: "1"
                - beats: 1
                  interval: "1"
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
              lyrics: ""
            - notes:
                - beats: 1
                  interval: "2/3"
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
                - beats: 1
                  interval: "1o2"
              lyrics: ""
            - notes:
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "1"
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
              lyrics: ""
         \""")));
```

Note also that top-level lists will be unnested, allowing for
repetition using YAML anchors. 

```jldoctest justly
julia> justly(SAMPLE_RATE, YAML.load(\"""
            - &fifth
                - notes:
                    - beats: 1
                      interval: "1"
                    - beats: 1
                      interval: "3/2"
                  lyrics: ""
            - *fifth
        \"""))
AudioSchedule
```
"""
function justly(
    sample_rate,
    song;
    wave = WAVE,
    make_envelope = pluck,
    initial_key = 440Hz,
    clock = 0s,
    beat_duration = 1s,
)
    key = initial_key
    plan = Plan(sample_rate)
    for chord_lyrics in song
        key, clock =
            play!(plan, chord_lyrics, wave, make_envelope, key, clock, beat_duration)
    end
    schedule = AudioSchedule(plan)
    map(Scale(1 / seek_peak(schedule)), schedule)
end
export justly

"""
    play(it)

Open a stream with PortAudio, read and play `it`, then close the stream.
"""
function play(it)
    stream = PortAudioStream(samplerate = samplerate(it))
    write(stream.sink, read(it, length(it)))
    close(stream)
end
export play

end
