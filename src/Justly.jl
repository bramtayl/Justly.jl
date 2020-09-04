module Justly

using AudioSchedules:
    add!, AudioSchedule, Cycles, Hook, Line, Map, Plan, q_str, SawTooth, Scale, seek_peak
import Base: float
using PortAudio: PortAudioStream
using QML: addrole, exec, get_julia_data, ListModel, load, qmlfunction, setconstructor
using SampledSignals: samplerate
using Unitful: Hz, s
using YAML: YAML

const WAVE = SawTooth(7)

function wave(angle)
    WAVE(angle) / 4
end

function pluck(time; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)
    ramp = peak / slope
    (0, Line => ramp, peak, Hook(decay, -slope) => time - ramp, 0)
end

const ENVELOPE = pluck(1s)

mutable struct Note
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
    frequency::Float64
end

Note() = Note(1, 1, 0, 1, 440.0)

float(note::Note) = note.numerator / note.denominator * 2^note.octave

mutable struct Chord
    notes::ListModel
    lyrics::String
    selected::Bool
end

parse_int(something) = parse(Int, something)

@inline function getter_setter(fieldname)
    (@inline function (note)
        string(getproperty(note, fieldname))
    end),
    @inline function (notes, new_value, index)
        setproperty!(notes[index], fieldname, parse_int(new_value))
    end
end

function Chord()
    model = ListModel([Note()], false)
    setconstructor(model, Note)
    addrole(model, "numerator", getter_setter(:numerator)...)
    addrole(model, "denominator", getter_setter(:denominator)...)
    addrole(model, "octave", getter_setter(:octave)...)
    addrole(model, "beats", getter_setter(:beats)...)
    addrole(model, "frequency", function (note)
        note.frequency
    end)
    Chord(model, "", false)
end

get_notes(chord) = get_julia_data(chord.notes).values

"""
    write_justly(; test = false)

Open an interactive interface where you can interactively write Justly text. Once you have
finished writing, you can copy the results to the clipboard as YAML. Then, you can use
[`play_justly`](@ref) to play them.

The first interval in the chord will change the key, and tells how many beats before the
next chord. You can set beats to 0 to overlap, or to a negative number to "time-travel" back
in time. The rest of the intervals in the chord will play notes with a given duration. Their
interval will show their relationship to the key. You can use lyrics to as a way to
keep track of your position in a song, or to make performance notes, but they are optional.
For more information, see the README.

Set `test` to true if you would like to test the GUI but not use it.

```jldoctest
julia> using Justly

julia> write_justly(test = true)
```
"""
function write_justly(; test = false)
    stream = PortAudioStream(samplerate = 44100)
    sink = stream.sink
    chords = Chord[]
    chords_update_frequencies = 
        let chords = chords
            function (base_frequency)
                key = parse(Float64, base_frequency)
                for chord in chords
                    notes = get_notes(chord)
                    first_note = notes[1]
                    key = key * float(first_note)
                    first_note.frequency = key
                    for note in @view notes[2:end]
                        note.frequency = key * float(note)
                    end
                end
                nothing
            end
        end
    qmlfunction("chords_update_frequencies!", chords_update_frequencies)

    sink_play_note = let sink = sink
        function (frequency)
            plan = Plan(samplerate(sink)Hz)
            add!(plan, Map(wave, Cycles((frequency)Hz)), 1s, ENVELOPE...)
            schedule = AudioSchedule(plan)
            write(sink, read(schedule, length(schedule)))
        end
    end
    qmlfunction("sink_play_note", sink_play_note)

    chords_make_yaml = let chords = chords
        function ()
            YAML.write(map(
                function (chord)
                    Dict(
                        "notes" => map(
                            function (note)
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
                            end,
                            get_notes(chord),
                        ),
                        "lyrics" => chord.lyrics,
                    )
                end,
                chords,
            ))
        end
    end
    qmlfunction("chords_make_yaml", chords_make_yaml)

    load(joinpath(@__DIR__, "Justly.qml"); chords = ListModel(chords), test = test)
    exec()
    if test
        first_chord = Chord()
        push!(get_notes(first_chord), Note())
        push!(chords, first_chord)
        push!(get_notes(chords[1]), Note())
        chords_update_frequencies("440")
        sink_play_note(440)
        close(stream)
        chords_make_yaml()
    else
        close(stream)
    end
    nothing
end
export write_justly

function parse_note(note)
    q_str(note["interval"]), note["beats"]
end

function play!(plan, chord_lyrics, wave, make_envelope, key, clock, time_per_beat)
    notes = chord_lyrics["notes"]
    modulation, ahead = parse_note(notes[1])
    key = key * modulation
    for note in notes[2:end]
        ratio, beats = parse_note(note)
        add!(
            plan,
            Map(wave, Cycles(key * ratio)),
            clock,
            make_envelope(beats * time_per_beat)...,
        )
    end
    key, clock + ahead * time_per_beat
end
function play!(plan, chords_lyrics::Vector, wave, make_envelope, key, clock, time_per_beat)
    for chord_lyrics in chords_lyrics
        key, clock =
            play!(plan, chord_lyrics, wave, make_envelope, key, clock, time_per_beat)
    end
    key, clock
end

"""
    function justly(sample_rate, song;
        wave = SawTooth(7),
        make_envelope = pluck,
        key = 440Hz,
        clock = 0s,
        time_per_beat = 1s
    )

Play music in Justly notation. `song` can be read in using `YAML` generated with
[`write_justly`](@ref). Note also that top-level lists will be unnested, allowing for
repetition using YAML anchors. `wave` should be a function which takes an angle in radians
and returns and amplitude between 0 and 1. `make_envelope` should be a function that takes
a duration in units of time (like `s`) and returns a tuple of envelope segments that can
be splatted into `AudioSchedules.add!`. `initial_key` should the frequency of the initial
key for your song, in units of frequency (like `Hz`). `time_per_beat` should specify the
amount of duration of a beat with units of time (like `s`).

For example, to create a simple I-IV-I figure,

```jldoctest
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
"""
function justly(
    sample_rate,
    song;
    wave = SawTooth(7),
    make_envelope = pluck,
    initial_key = 440Hz,
    clock = 0s,
    time_per_beat = 1s,
)
    key = initial_key
    plan = Plan(sample_rate)
    for chord_lyrics in song
        key, clock =
            play!(plan, chord_lyrics, wave, make_envelope, key, clock, time_per_beat)
    end
    schedule = AudioSchedule(plan)
    map(Scale(1 / seek_peak(schedule)), schedule)
end
export justly

"""
    play(schedule)

Open a stream with PortAudio, play AudioSchedule, then close the stream.
"""
function play(schedule)
    stream = PortAudioStream(samplerate = schedule.sample_rate / Hz)
    write(stream.sink, read(schedule, length(schedule)))
    close(stream)
end
export play

end
