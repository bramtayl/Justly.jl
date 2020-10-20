module Justly

# TODO: play the rest

using AudioSchedules:
    add!,
    AudioSchedule,
    Cycles,
    duration,
    FREQUENCY,
    Hook,
    Line,
    Map,
    Plan,
    q_str,
    SawTooth,
    Scale,
    TIME,
    triples
import Base: Dict
import Base.Iterators: takewhile
using Base.Threads: Event, @spawn
using Observables: Observable, on
using PortAudio: PortAudioStream
using Observables: Observable
using QML:
    addrole,
    @emit,
    exec,
    force_model_update,
    get_julia_data,
    JuliaPropertyMap,
    ListModel,
    load,
    QQmlPropertyMap,
    @qmlfunction,
    qmlfunction,
    setconstructor,
    to_string
using SampledSignals: samplerate
using Test: @test
using Unitful: Hz, ms, s
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
function pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1 / 2)
    ramp = peak / slope
    (
        0,
        Line => ramp,
        peak,
        Line => (duration - ramp - ramp + ramp * overlap),
        peak,
        Line => ramp,
        0,
    )
end
export pedal

mutable struct Note
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
end

Note() = Note(1, 1, 0, 1)

function represent(rational::Rational)
    octave = 0
    while rational >= 2
        rational = rational / 2
        octave = octave + 1
    end
    while rational < 1
        rational = rational * 2
        octave = octave - 1
    end
    if iseven(rational.num)
        rational = rational//2
        octave = octave + 1
    end
    rational.num, rational.den, octave
end

"""
    Chord(dictionary::Dict)

A Julia representation of a chord. Pass a vector of `Chord`s to [`justly_interactive`](@ref).
"""
mutable struct Chord
    words::String
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
    notes::Vector{Note}
    notes_model::ListModel
end
export Chord

function Chord(dictionary::Dict)
    interval, beats = interval_beats(dictionary)
    note_dictionaries = dictionary["notes"]
    notes = if note_dictionaries !== nothing
        map(Note, note_dictionaries)
    else
        Note[]
    end
    Chord(dictionary["words"], represent(interval)..., beats, notes, ListModel(notes))
end

function interval_beats(note::Union{Note, Chord})
    (note.numerator / note.denominator * 2.0^note.octave, note.beats)
end

function interval_beats(note::Dict)
    q_str(note["interval"]), note["beats"]
end

function Note(note::Dict)
    interval, beats = interval_beats(note)
    Note(represent(interval)..., beats)
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
        "interval" => string(if numerator != 1
            (numerator,)
        else
            ()
        end..., if denominator != 1
            '/', denominator
        else
            ()
        end..., if octave != 0
            'o', octave
        else
            ()
        end...),
        "beats" => note.beats,
    )
end

function Dict(note::Note)
    Dict(interval_string_beats(note)...)
end

function Dict(chord::Chord)
    Dict(
        "words" => chord.words,
        interval_string_beats(chord)...,
        "notes" => map(Dict, chord.notes),
    )
end

function update_key(chords, initial_key, chord_index)
    key = initial_key
    for chord in view(chords, 1:(chord_index + 1))
        key = key * interval_beats(chord)[1]
    end
    key
end

# TODO: continue after compilation

function to_yaml(chords)
    YAML.write(map(Dict, chords))
end

function release!(releases, event_id)
    println(event_id)
    notify(releases[event_id])
end

function from_yaml!(chords_model, text)
    try
        # load first to catch errors early
        result = YAML.load(String(text))
        while length(chords_model) > 0
            delete!(chords_model, 1)
        end
        for dictionary in result
            push!(chords_model, Chord(dictionary))
        end
    catch an_error
        # TODO: more noisy error
        @warn sprint(showerror, an_error)
    end
    nothing
end

function reader(intermediate, play_options, sink)
    write(sink, AudioSchedule(intermediate, play_options.sample_rate))
end

function lock_reader(intermediate, play_options, privilege, sink)
    lock(
        () -> reader(intermediate, play_options, sink),
        privilege
    )
end

function press_feeder!(intermediate, ramp_up, sustain)
    # make a small schedule, break it apart into pieces,
    # and put back together but repeat the sustain while holding
    put!(intermediate, ramp_up)
    try
        while true
            put!(intermediate, sustain)
        end
    finally
        close(intermediate)
    end
end

function at_sample_rate(sample_rate, (stateful, start, duration))
    stateful, round(Int, duration * sample_rate)
end

function press_task(chords, play_options, privilege, released, sink, chord_index, voice_index)
    ramp = play_options.ramp
    sample_rate = play_options.sample_rate
    (ramp_up, sustain, ramp_down) = map(
        triple -> at_sample_rate(sample_rate, triple),
        triples(
            sample_rate,
            Map(
                Scale(1 / play_options.max_voices),
                Map(
                    play_options.wave,
                    Cycles(
                        update_key(chords, play_options.initial_key, chord_index) *
                        interval_beats(chords[chord_index + 1].notes[voice_index + 1])[1],
                    ),
                ),
            ),
            0s, 0, Line => ramp, 1, Line => ramp, 1, Line => ramp, 0
        ),
    )
    @sync begin
        intermediate = Channel{Tuple{Any, Int}}(0)
        @async lock_reader(intermediate, play_options, privilege, sink)
        @async press_feeder!(intermediate, ramp_up, sustain)
        # both will run in the backgrond until released
        wait(released)
        put!(intermediate, ramp_down)
        close(intermediate)
    end
end

function press(chords, play_options, privilege, releases, sink, chord_index, voice_index)
    released = Event()
    push!(releases, released)
    @spawn press_task(chords, play_options, privilege, released, sink, chord_index, voice_index)
    length(releases)
end

function play_feeder!(intermediate, chords, play_options, index)
    plan = justly(
        (@view chords[(index + 1):end]),
        PlayOptions(
            beat_duration = play_options.beat_duration,
            initial_key = update_key(chords, play_options.initial_key, index - 1),
            latency = play_options.latency,
            make_envelope = play_options.make_envelope,
            max_voices = play_options.max_voices,
            ramp = play_options.ramp,
            sample_rate = play_options.sample_rate,
            wave = play_options.wave
        )
    )
    try
        for stateful_samples in plan
            put!(intermediate, stateful_samples)
        end
        close(intermediate)
    catch an_error
        if !(an_error isa InvalidStateException)
            rethrow(an_error)
        end
    end
end

function play_task(chords, play_options, privilege, released, sink, index)
    @sync begin
        intermediate = Channel{Tuple{Any, Int}}(0)
        @async play_feeder!(intermediate, chords, play_options, index)
        @async lock_reader(intermediate, play_options, privilege, sink)
        wait(released)
        close(intermediate)
    end
end

function play(chords, play_options, privilege, releases, sink, index)
    released = Event()
    push!(releases, released)
    @spawn play_task(chords, play_options, privilege, released, sink, index)
    length(releases)
end

function justly_interactive(chords, chords_model, play_options, privilege, releases, stream, test)
    sink = stream.sink
    qmlfunction("press", (chord_index, voice_index) -> press(chords, play_options, privilege, releases, sink, chord_index, voice_index))
    qmlfunction("play", index -> play(chords, play_options, privilege, releases, sink, index))
    load(joinpath(@__DIR__, "Justly.qml"), chords_model = chords_model, test = test)
    exec()
    if test
        simple_yaml = "- beats: 1\n  interval: \"\"\n  notes:\n    - beats: 1\n      interval: \"\"\n  words: \"\"\n"
        from_yaml!(chords_model, simple_yaml)
        # note: this is 1, 1 in julia
        press!(0, 0)
        release!()
        play(0)
        release!()
        @test String(to_yaml!()) == simple_yaml
    end
end

struct PlayOptions{Wave, MakeEnvelope}
    beat_duration::TIME
    initial_key::FREQUENCY
    latency::TIME
    make_envelope::MakeEnvelope
    max_voices::Int
    ramp::TIME 
    sample_rate::FREQUENCY
    wave::Wave
end

"""
    PlayOptions(;
        beat_duration = 0.6s, 
        initial_key = 220Hz, 
        latency = 1.0ms, 
        make_envelope = pedal, 
        max_voices = 6, 
        ramp = 0.1s, 
        sample_rate = 44100Hz, 
        wave = SawTooth(7)
    )

Options for playing music with `justly` and `justly_interactive`.

`beat_duration` should be in time units, like `s`.
`initial_key` should be in frequency units, like `Hz`.
`latency` will be passed to `PortAudioStream`. Consider using a relatively large number. Use time units (like `ms`).
`make_envelope` should be a function that takes a duration in units of time (like `s`) and returns a tuple of envelope segments that can be splatted into `AudioSchedules.add!`. 
To avoid peaking, do not exceed `max_voices` playing at once.
`ramp` should be in time units (like `s`), and will control the ramp time for note previews.
The `sample_rate` should be in freqeuncy units, like `Hz`.
`wave` should be a function which takes an angle in radians and returns and amplitude between 0 and 1.
"""
PlayOptions(;
    beat_duration = 0.6s,
    initial_key = 220Hz,
    latency = 1.0ms,
    make_envelope = pedal,
    max_voices = 6,
    ramp = 0.1s,
    sample_rate = 44100Hz,
    wave = SawTooth(7)
) = PlayOptions(convert(TIME, beat_duration), convert(FREQUENCY, initial_key), convert(TIME, latency), make_envelope, max_voices, convert(TIME, ramp), convert(FREQUENCY, sample_rate), wave)
export PlayOptions

"""
    function justly_interactive(chords::Vector{Chord}, play_options::PlayOptions;; test = false)

Open an interactive interface where you can interactively write Justly text. Once you have
finished writing, you can copy the results to the clipboard as YAML. Then, you can use
[`play_justly`](@ref) to play them. The first time a song is played, you will get delays
while Julia compiles.

`chords` should be a vector of [`Chord`]s to start editing. 
play_options should be a set of [`PlayOptions`](@ref).

The first interval in the chord will modulate the key, and tells how many beats before the
next chord. You can set beats to 0 to overlap, or to a negative number to "time-travel" back
in time. The rest of the intervals in the chord will play notes with a given duration. Their
interval will show their relationship to the key. You can use words to as a way to
keep track of your position in a song, or to make performance notes, but they are optional.
For more information, see the README.

```jldoctest
julia> using Justly

julia> chords = Chord[];

julia> justly_interactive(chords, PlayOptions(); test = true)
```
"""
function justly_interactive(chords, play_options; test = false)
    releases = Event[]
    chords_model = ListModel(chords)
    privilege = ReentrantLock()
    qmlfunction("release", event_id -> release!(releases, event_id))
    qmlfunction("to_yaml", () -> to_yaml(chords))
    qmlfunction("from_yaml", text -> from_yaml!(chords_model, text))
    PortAudioStream(
        stream -> justly_interactive(chords, chords_model, play_options, privilege, releases, stream, test),
        samplerate = play_options.sample_rate / Hz, 
        latency = play_options.latency / ms
    )
    nothing
end
export justly_interactive

get_notes(chord::Chord) = chord.notes
get_notes(chord::Dict) = chord["notes"]

function play!(
    chord, clock, key, plan, play_options
)
    beat_duration = play_options.beat_duration
    modulation, ahead = interval_beats(chord)
    key = key * modulation
    for note in get_notes(chord)
        interval, beats = interval_beats(note)
        add!(
            plan,
            Map(Scale(1 / play_options.max_voices), Map(play_options.wave, Cycles(key * interval))),
            clock,
            play_options.make_envelope(beats * beat_duration)...,
        )
    end
    key, clock + ahead * beat_duration
end

function play!(chords::Vector, clock, key, plan, play_options)
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
            - words: "I"
              interval: "1"
              beats: 1
              notes:
                - beats: 1
                  interval: "1"
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"     
            - words: "IV"
              interval: "2/3"
              beats: 1
              notes:
                - beats: 1
                  interval: "3/2"
                - beats: 1
                  interval: "5/4o1"
                - beats: 1
                  interval: "1o2"
            - words: "I"
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
Plan with triggers at (0.0 s, 0.1 s, 0.9500000000000001 s, 1.0 s, 1.05 s, 1.1 s, 1.9500000000000002 s, 2.0 s, 2.0500000000000003 s, 2.1 s, 2.95 s, 3.0500000000000003 s)
```

Note also that top-level lists will be unnested, allowing for
repetition using YAML anchors. 

```jldoctest justly
julia> justly(SAMPLE_RATE, YAML.load(\"""
            - &fifth
                - words: ""
                  interval: "1"
                  beats: 1
                  notes:
                    - beats: 1
                      interval: "1"
                    - beats: 1
                      interval: "3/2"
            - *fifth
        \"""))
Plan with triggers at (0.0 s, 0.1 s, 0.9500000000000001 s, 1.0 s, 1.05 s, 1.1 s, 1.9500000000000002 s, 2.0500000000000003 s)
```
"""
function justly(song, play_options)
    clock = 0s
    key = play_options.initial_key
    plan = Plan(play_options.sample_rate)
    for chord in song
        key, clock =
            play!(chord, clock, key, plan, play_options)
    end
    plan
end
export justly

end
