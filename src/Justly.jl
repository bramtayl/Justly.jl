module Justly

using AudioSchedules:
    add!,
    AudioSchedule,
    Cycles,
    Hook,
    Line,
    Map,
    q_str,
    SawTooth,
    Scale,
    triples,
    Weaver,
    write_stateful!,
    write_buffer
import Base: isone, Rational, show
using Base.Threads: nthreads, @spawn
using PortAudio: PortAudioStream
using QML:
    exec,
    ListModel,
    loadqml,
    # to avoid QML bug
    QML,
    qmlfunction
using Qt5QuickControls2_jll: Qt5QuickControls2_jll
using SampledSignals: samplerate
using Test: @test
using Unitful: Hz, ms, s
using YAML: YAML, load
import YAML: _print

# reexport to avoid a QML bug
export QML

function write_channel(buffer, channel)
    buffer_at = 0
    for (stateful, stateful_to) in channel
        buffer_at = write_stateful!(stateful, stateful_to, buffer, buffer_at)
    end
    write_buffer(buffer, buffer_at)
end

"""
    pluck(duration; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)

The default envelope function used for [`make_schedule`](@ref).
An exponential decay with ramps on either side.
"""
function pluck(duration; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)
    ramp = peak / slope
    (0, Line => ramp, peak, Hook(decay, -slope) => duration - ramp, 0)
end
export pluck

"""
    pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)

A sustain with steep ramps on either side. Overlap is the proportion of the ramps that overlap.
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

const DEFAULT_BEAT_DURATION = 0.6s
const DEFAULT_INITIAL_KEY = 220Hz
const DEFAULT_MAKE_ENVELOPE = pedal
const DEFAULT_VOLUME = 0.15
const DEFAULT_RAMP = 0.1s
const DEFAULT_SAMPLE_RATE = 44100Hz
const DEFAULT_WAVE = SawTooth(7)

# we could just store intervals as a rational number
# but there's more than one way to represent a given rational
# so we don't want to lose user information
struct Interval
    numerator::Int
    denominator::Int
    octave::Int
end

isone(interval::Interval) = interval.numerator == 1 && interval.denominator == 1 && interval.octave == 0

function Rational(interval::Interval)
    interval.numerator // interval.denominator * (2 // 1)^interval.octave
end

function Interval(rational::Rational)
    octave = 0
    # first, get it in to the [1, 2) range
    while rational >= 2
        rational = rational / 2
        octave = octave + 1
    end
    while rational < 1
        rational = rational * 2
        octave = octave - 1
    end
    # then, divide the top by two if applicable
    if iseven(rational.num)
        rational = rational//2
        octave = octave + 1
    end
    Interval(rational.num, rational.den, octave)
end

function Interval(text::String)
    Interval(q_str(text))
end

function show(io::IO, interval::Interval)
    # just show not-obvious parts
    numerator = interval.numerator
    denominator = interval.denominator
    octave = interval.octave
    print(io, '"')
    show(io, numerator)
    if denominator != 1
        print(io, '/')
        show(io, denominator)
    end
    if octave != 0
        print(io, 'o')
        show(io, octave)
    end
    print(io, '"')
end

get_interval(something) = Interval(something.numerator, something.denominator, something.octave)

# it would be nice if we could have a nested interval
# but because this will be used as a list-model, we can't
# same goes for chords
mutable struct Note
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
end

function Note(; interval = 1//1, beats = 1)
    true_interval = Interval(interval)
    # convert strings and rationals to intervals first
    Note(true_interval.numerator, true_interval.denominator, true_interval.octave, beats)
end

"""
    Chord(dictionary::Dict)

A Julia representation of a chord. Pass a vector of `Chord`s to [`edit_song`](@ref).
"""
mutable struct Chord
    words::String
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
    notes::Vector{Note}
    # we need a separate field here for the list model
    notes_model::ListModel
end
export Chord

function Chord(;
    words = "",
    interval = 1//1,
    beats = 1,
    notes = Note[]
)
    true_interval = Interval(interval)
    Chord(words, true_interval.numerator, true_interval.denominator, true_interval.octave, beats, notes, ListModel(notes))
end

# overload the yaml print functions
# print them as if they were dicts
function _print(io::IO, note::Note, level::Int=0, ignore_level::Bool=false)
    empty = true
    interval = get_interval(note)
    if !isone(interval)
        _print(io, "interval" => interval, level, empty ? ignore_level : false)
        empty = false
    end
    beats = note.beats
    if !isone(beats)
        _print(io, "beats" => beats, level, empty ? ignore_level : false)
        empty = false
    end
    if empty
        println(io, "{}")
    end
end

function _print(io::IO, chord::Chord, level::Int=0, ignore_level::Bool=false)
    empty = true
    interval = get_interval(chord)
    if !isone(interval)
        _print(io, "interval" => interval, level, empty ? ignore_level : false)
        empty = false
    end
    words = chord.words
    if !isempty(words)
        _print(io, "words" => words, level, empty ? ignore_level : false)
        empty = false
    end
    beats = chord.beats
    if beats != 1
        _print(io, "beats" => beats, level, empty ? ignore_level : false)
        empty = false
    end
    notes = chord.notes
    if !isempty(notes)
        _print(io, "notes" => notes, level, empty ? ignore_level : false)
        empty = false
    end
    if empty
        println(io, "{}")
    end
end

# cumulative product of previous modulations
function update_key(chords, initial_key, chord_index)
    key = initial_key
    for chord in view(chords, 1:(chord_index + 1))
        key = key * Rational(get_interval(chord))
    end
    key
end

function parse_note(dictionary::Dict)
    Note(;
        interval = get(dictionary, "interval", 1//1), 
        beats = get(dictionary, "beats", 1)
    )
end

# TODO: add a special constructor to avoid Dict intermediates
function parse_chord(dictionary::Dict)
    note_dictionaries = get(dictionary, "notes", Dict{Any, Any}[])
    Chord(
        interval = get(dictionary, "interval", 1//1),
        words = get(dictionary, "words", ""), 
        beats = get(dictionary, "beats", 1),
        # empty lists will come in as nothing
        notes = if note_dictionaries === nothing
            Note[]
        else
            map(parse_note, note_dictionaries) 
        end
    )
end

# we are working with the model, not the underlying data, so qt can know what we're doing
function from_yaml!(chords_model, text)
    try
        # load first to catch errors early
        result = load(String(text))
        # TODO: does empty! work? PR?
        while length(chords_model) > 0
            delete!(chords_model, 1)
        end
        for dictionary in result
            push!(chords_model, parse_chord(dictionary))
        end
    catch an_error
        # TODO: more noisy error
        @warn sprint(showerror, an_error)
    end
    nothing
end

function press!(buffer, chords, presses, releases;
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    ramp = DEFAULT_RAMP,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE
)
    for (chord_index, voice_index) in presses
        buffer_at = 0
        if voice_index < 0
            whole_schedule = make_schedule(
                (@view chords[(chord_index + 1):end]);
                beat_duration = beat_duration,
                initial_key = update_key(chords, initial_key, chord_index - 1),
                make_envelope = make_envelope,
                sample_rate = sample_rate,
                volume = volume,
                wave = wave
            )
            for (stateful, stateful_to) in whole_schedule
                if isready(releases)
                    break
                end
                buffer_at = write_stateful!(stateful, stateful_to, buffer, buffer_at)
            end
        else
            # TODO: avoid allocating a schedule here
            dummy_schedule = AudioSchedule(; sample_rate = sample_rate)
            add!(dummy_schedule, Map(
                    Scale(volume),
                    Map(
                        wave,
                        Cycles(
                            update_key(chords, initial_key, chord_index) *
                            Rational(get_interval(chords[chord_index + 1].notes[voice_index + 1]))
                        ),
                    ),
                ),
                0s, 
                0, Line => ramp, 1, Line => ramp, 1, Line => ramp, 0
            )
            # all three will be pairs of iterators and number of frames
            (ramp_up, sustain, ramp_down) = dummy_schedule
            buffer_at = write_stateful!(ramp_up..., buffer, buffer_at)
            while !isready(releases)
                buffer_at = write_stateful!(sustain..., buffer, buffer_at)
            end
            buffer_at = write_stateful!(ramp_down..., buffer, buffer_at)
        end
        write_buffer(buffer, buffer_at)
        take!(releases)
    end
end

"""
    function edit_song(chords::Vector{Chord}; ramp = 0.1s, options...)

Open an interactive interface where you can interactively write Justly text. 
Once you have finished writing, you can copy the results to the clipboard as YAML.
Then, you can use [`make_schedule`](@ref) to play your song.
Might be slow at first while Julia is compiling.

`chords` should be a vector of [`Chord`]s to start editing.
`ramp` is the time it takes for a note to switch from on to off, in time units (like `s`).
`options` will be passed to [`make_schedule`](@ref).

The first interval in the chord will modulate the key, and tells how many beats before the next key change.
You can set beats to 0 to overlap, or to a negative number to "travel back in time".
The rest of the intervals in the chord will play notes with a given duration.
Their interval will show their relationship to the key.
You can use words to as a way to keep track of your position in a song, or to make performance notes.
For more information, see the README.

```julia
julia> using Justly

julia> chords = Chord[];

julia> edit_song(chords; test = true)
```
"""
function edit_song(chords; 
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    ramp = DEFAULT_RAMP,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
    test = false,
)
    if nthreads() < 2
        error("Justly needs at least 2 threads to function")
    end
    qmlfunction("to_yaml", let chords = chords
        () -> YAML.write(chords)
    end)

    chords_model = ListModel(chords)
    qmlfunction("from_yaml", let chords_model = chords_model
        text -> from_yaml!(chords_model, text)
    end)

    presses = Channel{Tuple{Int, Int}}(0)
    qmlfunction("press", let presses = presses
        (chord_index, voice_index) -> put!(presses, (chord_index, voice_index))
    end)

    releases = Channel{Nothing}(0)
    qmlfunction("release", let releases = releases
        () -> put!(releases, nothing)
    end)

    loadqml(joinpath(@__DIR__, "Justly.qml"), chords_model = chords_model, test = test)
    stream = PortAudioStream(0, 1, writer = Weaver(); warn_xruns = false)
    buffer = stream.sink_messanger.buffer
    press_task = @spawn press!(buffer, chords, presses, releases;
        beat_duration = beat_duration,
        initial_key = initial_key,
        make_envelope = make_envelope,
        ramp = ramp,
        sample_rate = sample_rate,
        volume = volume,
        wave = wave
    )
    try
        if test
            simple_yaml = "- notes:\n    - interval: \"1o1\"\n    - {}\n- {}\n"
            from_yaml!(chords_model, simple_yaml)
            # note: this is 1, 1 in julia
            put!(presses, (0, 0))
            put!(releases, nothing)
            put!(presses, (0, -1))
            put!(releases, nothing)
            @test String(YAML.write(chords)) == simple_yaml
        end
        exec()
        close(presses)
    finally
        wait(press_task)
    end
    close(releases)
    close(stream)
    nothing
end
export edit_song

function add_note!(a_schedule, note, clock, key;
    wave = DEFAULT_WAVE,
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME
)
    add!(
        a_schedule,
        Map(Scale(volume), Map(wave, Cycles(key * Rational(get_interval(note))))),
        clock,
        make_envelope(note.beats * beat_duration)...,
    )
end

function add_chord!(
    a_schedule, chord::Chord, clock, key; 
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE
)
    key = key * Rational(get_interval(chord))
    foreach(
        let a_schedule = a_schedule, 
            clock = clock, 
            key = key,
            wave = wave,
            beat_duration = beat_duration,
            make_envelope = make_envelope,
            volume = volume
            note -> add_note!(a_schedule, note, clock, key;
                wave = wave,
                beat_duration = beat_duration,
                make_envelope = make_envelope,
                volume = volume
            )
        end,
        chord.notes
    )
    key, clock + chord.beats * beat_duration
end

function add_chord!(a_schedule, dictionary::Dict, clock, key; options...)
    add_chord!(a_schedule, parse_chord(dictionary), clock, key; options...)
end

function add_chord!(a_schedule, chords::Vector, clock, key;
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE
)
    for chord in chords
        key, clock = add_chord!(a_schedule, chord, clock, key;
            beat_duration = beat_duration,
            make_envelope = make_envelope,
            volume = volume,
            wave = wave
        )
    end
    key, clock
end

"""
    function make_schedule(song;
        beat_duration = 0.6s,
        initial_key = 220Hz,
        make_envelope = pedal,
        sample_rate = 44100Hz,
        volume = 0.15,
        wave = SawTooth(7)
    )

Play music in Justly notation. 
- `song` can be in `YAML` or a list of [`Chord`](@ref)s.
- `beat_duration` is duration of a beat with time units (like `s`).
- `initial_key` is initial key of your song, in frequency units (like `Hz`). 
- `make_envelope` is should be a function to make an envelope, like [`pluck`](@ref) or [`pedal`](@ref).
- `sample_rate` is the sample rate in frequency units (like `Hz`).
- `volume` will be the volume that a single voice is played at, ranging from 0-1.
- `wave` should be a function which takes an angle in radians and returns an amplitude between 0 and 1. 

For example, to create a simple I-IV-I figure,

```jldoctest make_schedule
julia> using Justly

julia> using YAML: load

julia> make_schedule(load(\"""
            - words: "I"
              notes:
                - {}
                - interval: "3/2"
                - interval: "5/4o1"     
            - words: "IV"
              interval: "2/3"
              notes:
                - interval: "3/2"
                - interval: "5/4o1"
                - interval: "1o2"
            - words: "I"
              interval: "3/2"
              notes:
                - {}
                - interval: "3/2"
                - interval: "5/4o1"
              
         \"""))
1.85 s 44100.0 Hz AudioSchedule
```

Note also that Justly will unnest top-level lists, so you use YAML anchors to repeat themes.

```jldoctest make_schedule
julia> make_schedule(load(\"""
            - &fifth
                - notes:
                    - {}
                    - interval: "3/2"
            - *fifth
        \"""))
1.25 s 44100.0 Hz AudioSchedule
```
"""
function make_schedule(song; 
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE
)
    clock = 0s
    key = initial_key
    a_schedule = AudioSchedule(; sample_rate = sample_rate)
    for chord in song
        key, clock =
            add_chord!(a_schedule, chord, clock, key; 
                beat_duration = beat_duration,
                make_envelope = make_envelope,
                volume = volume,
                wave = wave
        )
    end
    a_schedule
end
export make_schedule

end
