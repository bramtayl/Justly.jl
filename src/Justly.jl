module Justly

using AudioSchedules:
    add!, AudioSchedule, Cycles, duration, Hook, Line, Map, Plan, q_str, SawTooth, Scale
using Base.Threads: @spawn
using PortAudio: PortAudioStream
using Observables: Observable
using QML:
    addrole,
    exec,
    get_julia_data,
    ListModel,
    load,
    @qmlfunction,
    qmlfunction,
    setconstructor
using SampledSignals: samplerate
using Test: @test
using Unitful: Hz, s
using YAML: YAML

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
    pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)

A sustain with steep ramps on either side. Increase overlap to make the sound more legato.
"""
function pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)
    ramp = peak / slope
    (0, Line => ramp, peak, Line => (duration - ramp - ramp + ramp * overlap), peak, Line => ramp, 0)
end
export pedal

mutable struct Note
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
end

Note() = Note(1, 1, 0, 1)

function interval_beats(note::Dict)
    q_str(note["interval"]), note["beats"]
end

mutable struct Chord
    lyrics::String
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
    notes::Vector{Note}
    notes_model::ListModel
end

function interval_beats(note::Union{Note, Chord})
    (note.numerator / note.denominator * 2.0^note.octave, note.beats)
end

function Chord()
    notes = Note[]
    Chord("", 1, 1, 0, 1, notes, ListModel(notes))
end

function interval_string_beats(note::Union{Chord, Note})
    numerator = note.numerator
    denominator = note.denominator
    octave = note.octave
    (
        "interval" => string(
            if numerator != 1
                (numerator,)
            else
                ()
            end...,
            if denominator != 1
                '/', denominator
            else
                ()
            end...,
            if octave != 0
                'o', octave
            else
                ()
            end...
        ),
        "beats" => note.beats
    )
end

function as_dict(note::Note)
    Dict(
        interval_string_beats(note)...
    )
end

function as_dict(chord::Chord)
    Dict(
        "lyrics" => chord.lyrics,
        interval_string_beats(chord)...,
        "notes" => map(as_dict, chord.notes),
    )
end

"""
    function justly_interactive(;
        sample_rate = 44100Hz,
        wave = SawTooth(7),
        max_voices = 6,
        make_envelope = pedal,
        initial_key = 220Hz,
        beat_duration = 0.6s,
        ramp = 0.1s,
    )

Open an interactive interface where you can interactively write Justly text. Once you have
finished writing, you can copy the results to the clipboard as YAML. Then, you can use
[`play_justly`](@ref) to play them.

`wave` should be a function which takes an angle in radians and returns and amplitude between 0 and 1.
To avoid peaking, do not exceed `max_voices` playing at once.
`make_envelope` should be a function that takes a duration in units of time (like `s`) and returns a tuple of envelope segments that can be splatted into `AudioSchedules.add!`. 
`initial_key` should be in frequency units, like `Hz`.
`beat_duration` should be in time units, like `s`.
`ramp` should be in time units, like `s`, and will control the ramp time for note previews.

The first interval in the chord will modulate the key, and tells how many beats before the
next chord. You can set beats to 0 to overlap, or to a negative number to "time-travel" back
in time. The rest of the intervals in the chord will play notes with a given duration. Their
interval will show their relationship to the key. You can use lyrics to as a way to
keep track of your position in a song, or to make performance notes, but they are optional.
For more information, see the README.

```jldoctest
julia> using Justly

julia> justly_interactive(test = true)
```
"""
function justly_interactive(;
    sample_rate = 44100Hz,
    wave = SawTooth(7),
    max_voices = 6,
    make_envelope = pedal,
    initial_key = 220Hz,
    beat_duration = 0.6s,
    ramp = 0.1s,
    test = false,
)
    speaker = ReentrantLock()
    sustain_end = Channel{Nothing}(0)
    stream = PortAudioStream(samplerate = sample_rate / Hz)
    sink = stream.sink
    chords = Chord[]

    inner_press! = function (qml_chord_index, qml_voice_index)
        key = initial_key
        julia_chord_index = qml_chord_index + 1
        for chord in view(chords, 1:julia_chord_index)
            key = key * interval_beats(chord)[1]
        end
        # make a small schedule, break it apart into pieces,
        # and put back together but repeat the sustain while holding
        plan = Plan(sample_rate)
        add!(
            plan,
            Map(
                Scale(1 / max_voices),
                Map(
                    wave,
                    Cycles(
                        key *
                        interval_beats(chords[julia_chord_index].notes[qml_voice_index + 1])[1]
                    )
                )
            ),
            0s,
            0,
            Line => ramp,
            1,
            Line => ramp,
            1,
            Line => ramp,
            0,
        )
        small_plan = AudioSchedule(plan)
        ramp_up = (small_plan.stateful, small_plan.has_left)
        small_channel = small_plan.channel
        sustain, ramp_down = small_channel
        # we can't do this on the main thread
        # because the main thread needs to listen for the release         
        @spawn begin
            lock(speaker) do
                write(
                    sink,
                    AudioSchedule(
                        # both producer and consumer can be on the same task
                        Channel{eltype(small_channel)}(0) do channel
                            put!(channel, ramp_up)
                            while !isready(sustain_end)
                                put!(channel, sustain)
                            end
                            take!(sustain_end)
                            put!(channel, ramp_down)
                        end,
                        sample_rate,
                    ),
                )
            end
        end
    end
    qmlfunction("press", inner_press!)

    inner_release! = function ()
        put!(sustain_end, nothing)
    end
    qmlfunction("release", inner_release!)

    inner_make_yaml = function ()
        YAML.write(map(as_dict, chords))
    end
    qmlfunction("make_yaml", inner_make_yaml)

    inner_play = function ()
        plan = justly(
            sample_rate,
            chords;
            wave = wave,
            max_voices = max_voices,
            make_envelope = make_envelope,
            initial_key = initial_key,
            beat_duration = beat_duration,
        )
        song = read(AudioSchedule(plan), duration(plan))
        @spawn begin
            lock(speaker) do
                write(sink, song)
            end
        end
    end
    qmlfunction("play", inner_play)

    load(joinpath(@__DIR__, "Justly.qml"); chords = ListModel(chords), test = test)

    exec()
    if test
        first_chord = Chord()
        push!(first_chord.notes, Note())
        push!(chords, first_chord)
        # note: this is 1, 1 in julia
        inner_press!(0, 0)
        inner_release!()
        inner_play()
        @test inner_make_yaml() ==
        "- beats: 1\n  interval: \"1\"\n  notes:\n    - beats: 1\n      interval: \"1\"\n  lyrics: \"\"\n" == "- beats: 1\n  interval: \"1\"\n  notes:\n    - beats: 1\n      interval: \"1\"\n  lyrics: \"\"\n"
    end
    close(sustain_end)
    close(stream)
    nothing
end
export justly_interactive

get_notes(chord::Chord) = chord.notes
get_notes(chord::Dict) = chord["notes"]

function play!(plan::Plan, chord, key, clock, wave, max_voices, make_envelope, beat_duration)
    modulation, ahead = interval_beats(chord)
    key = key * modulation
    for note in get_notes(chord)
        interval, beats = interval_beats(note)
        add!(
            plan,
            Map(Scale(1/max_voices), Map(wave, Cycles(key * interval))),
            clock,
            make_envelope(beats * beat_duration)...,
        )
    end
    key, clock + ahead * beat_duration
end
function play!(plan::Plan, chords::Vector, key, clock, arguments...)
    for chord in chords
        key, clock = play!(plan, chord, key, clock, arguments...)
    end
    key, clock
end

"""
    function justly(sample_rate, song;
        wave = SawTooth(7),
        max_voices = 6,
        make_envelope = pedal,
        initial_key = 440Hz,
        beat_duration = 1s
    )

Play music in Justly notation. 
`song` can be read in using `YAML` generated with [`justly_interactive`](@ref). 
`wave` should be a function which takes an angle in radians and returns and amplitude between 0 and 1. 
To avoid peaking, do not exceed `max_voices` playing at once.
`make_envelope` should be a function that takes a duration in units of time (like `s`) and returns a tuple of envelope segments that can be splatted into `AudioSchedules.add!`. 
`initial_key` should the frequency of the initial key for your song, in units of frequency (like `Hz`). 
`beat_duration` should specify the amount of duration of a beat with units of time (like `s`).

For example, to create a simple I-IV-I figure,

```jldoctest justly
julia> using Justly

julia> using YAML

julia> using Unitful: Hz

julia> const SAMPLE_RATE = 44100Hz;

julia> justly(SAMPLE_RATE, YAML.load(\"""
            - lyrics: "I"
              interval: "1"
              beats: 1
              notes:
                - beats: 1
                  interval: "1"
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
              
            - lyrics: "IV"
              interval: "2/3"
              beats: 1
              notes:
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
                - beats: 1
                  interval: "1o2"
            - lyrics: "I"
              interval: "3/2"
              beats: 1
              notes:
                - beats: 1
                  interval: "1"
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
              
         \"""))
Plan with triggers at (0.0 s, 0.01 s, 0.995 s, 1.0 s, 1.005 s, 1.01 s, 1.995 s, 2.0 s, 2.005 s, 2.01 s, 2.9949999999999997 s, 3.0049999999999994 s)
```

Note also that top-level lists will be unnested, allowing for
repetition using YAML anchors. 

```jldoctest justly
julia> justly(SAMPLE_RATE, YAML.load(\"""
            - &fifth
                - lyrics: ""
                  interval: "1"
                  beats: 1
                  notes:
                    - beats: 1
                      interval: "1"
                    - beats: 1
                      interval: "3/2"
            - *fifth
        \"""))
Plan with triggers at (0.0 s, 0.01 s, 0.995 s, 1.0 s, 1.005 s, 1.01 s, 1.995 s, 2.005 s)
```
"""
function justly(
    sample_rate,
    song;
    wave = SawTooth(7),
    max_voices = 6,
    make_envelope = pedal,
    initial_key = 440Hz,
    beat_duration = 1s,
)
    clock = 0s
    key = initial_key
    plan = Plan(sample_rate)
    for chord in song
        key, clock = play!(plan, chord, key, clock, wave, max_voices, make_envelope, beat_duration)
    end
    plan
end
export justly

end
