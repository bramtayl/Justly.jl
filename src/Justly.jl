module Justly

using AudioSchedules:
    add!,
    AudioSchedule,
    Cycles,
    Hook,
    Line,
    Map,
    QUOTIENT,
    SawTooth,
    Scale,
    triples,
    Weaver,
    write_stateful!,
    write_buffer
import Base: getproperty, Rational, show
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

You can use `pluck` to make an envelope with an exponential decay and ramps at the beginning and end.

"""
function pluck(duration; decay = -2.5 / s, slope = 1 / 0.005s, peak = 1)
    ramp = peak / slope
    (0, Line => ramp, peak, Hook(decay, -slope) => duration - ramp, 0)
end
export pluck

"""
    pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)

You can use `pedal` to make an envelope with a sustain and ramps at the beginning and end. 
`overlap` is the proportion of the ramps that overlap.
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

const INTERVAL_DEFAULTS = (numerator = 1, denominator = 1, octave = 0)

function Interval(;
    numerator = INTERVAL_DEFAULTS.numerator,
    denominator = INTERVAL_DEFAULTS.denominator,
    octave = INTERVAL_DEFAULTS.octave
)
    Interval(numerator, denominator, octave)
end

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
        rational = rational / 2
        octave = octave + 1
    end
    Interval(rational.num, rational.den, octave)
end

function get_parse(dictionary, property)
    result = dictionary[String(property)]
    if result === nothing
        getproperty(INTERVAL_DEFAULTS, property)
    else
        parse(Int, result)
    end
end

# TODO: reuse from AudioSchedules
function Interval(text::String)
    a_match = match(QUOTIENT, text)
    if a_match === nothing
        throw(Meta.ParseError("Can't parse interval $text"))
    end
    Interval(
        get_parse(a_match, :numerator),
        get_parse(a_match, :denominator),
        get_parse(a_match, :octave)
    )
end

function Interval(interval::Interval)
    interval
end

function print_no_default(io, interval, prefix, property)
    value = getproperty(interval, property)
    if value != getproperty(INTERVAL_DEFAULTS, property)
        print(io, prefix)
        show(io, value)
    end
end

function show(io::IO, interval::Interval)
    # just show not-obvious parts
    print(io, '"')
    show(io, interval.numerator)
    print_no_default(io, interval,  '/', :denominator)
    print_no_default(io, interval, 'o', :octave)
    print(io, '"')
end

function interval_pieces(note_or_chord)
    (note_or_chord.numerator, note_or_chord.denominator, note_or_chord.octave)
end

get_interval(note_or_chord) = Interval(interval_pieces(note_or_chord)...)

# it would be nice if we could have a nested interval
# but because this will be used as a list-model, we can't
# same goes for chords
mutable struct Note
    numerator::Int
    denominator::Int
    octave::Int
    beats::Int
end

const CHORD_DEFAULTS = (words = "", beats = 1, notes = Note[], interval = Interval())

function getproperty(note::Note, property::Symbol)
    if property === :interval
        get_interval(note)
    else
        getfield(note, property)
    end
end

function Note(; 
    interval = CHORD_DEFAULTS.interval,
    beats = CHORD_DEFAULTS.beats
)
    # convert strings and rationals to intervals first
    Note(interval_pieces(Interval(interval))..., beats)
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
    # we need a separate property here for the list model
    notes_model::ListModel
end
export Chord

function getproperty(chord::Chord, property::Symbol)
    if property === :interval
        get_interval(chord)
    else
        getfield(chord, property)
    end
end

function Chord(;
    words = CHORD_DEFAULTS.words,
    interval = CHORD_DEFAULTS.interval,
    beats = CHORD_DEFAULTS.beats,
    notes = Note[]
)
    Chord(words, interval_pieces(Interval(interval))..., beats, notes, ListModel(notes))
end

function print_no_default(io, note_or_chord, property, level, ignore_level, empty)
    value = getproperty(note_or_chord, property)
    if value != getproperty(CHORD_DEFAULTS, property)
        _print(io, property => value, level, if empty
            ignore_level
        else
            false
        end)
        false
    else
        empty
    end
end

function print_empty(io, empty)
    if empty
        println(io, "{}")
    end
end

# overload the yaml print functions
# print them as if they were dicts
function _print(io::IO, note::Note, level::Int=0, ignore_level::Bool=false)
    empty = true
    empty = print_no_default(io, note, :interval, level, ignore_level, empty)
    empty = print_no_default(io, note, :beats, level, ignore_level, empty)
    print_empty(io, empty)
end

function _print(io::IO, chord::Chord, level::Int=0, ignore_level::Bool=false)
    empty = true
    empty = print_no_default(io, chord, :interval, level, ignore_level, empty)
    empty = print_no_default(io, chord, :words, level, ignore_level, empty)
    empty = print_no_default(io, chord, :beats, level, ignore_level, empty)
    empty = print_no_default(io, chord, :notes, level, ignore_level, empty)
    print_empty(io, empty)
end

# cumulative product of previous modulations
function update_key(song, initial_key, chord_index)
    key = initial_key
    for chord in view(song, 1:(chord_index + 1))
        key = key * Rational(chord.interval)
    end
    key
end

function get_default(dictionary, property)
    get(dictionary, property, getproperty(CHORD_DEFAULTS, property))
end

function parse_note(dictionary)
    Note(;
        interval = get_default(dictionary, :interval), 
        beats = get_default(dictionary, :beats)
    )
end

# TODO: add a special constructor to avoid Dict intermediates
function parse_chord(dictionary)
    note_dictionaries = get(dictionary, :notes, Dict{Symbol, Any}[])
    Chord(;
        interval = get_default(dictionary, :interval),
        words = get_default(dictionary, :words), 
        beats = get_default(dictionary, :beats),
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
        result = load(String(text); dicttype=Dict{Symbol,Any})
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

function press!(buffer, song, presses, releases;
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
                (@view song[(chord_index + 1):end]);
                beat_duration = beat_duration,
                initial_key = update_key(song, initial_key, chord_index - 1),
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
                            update_key(song, initial_key, chord_index) *
                            Rational(song[chord_index + 1].notes[voice_index + 1].interval)
                        ),
                    ),
                ),
                0s, 
                0, Line => ramp, 1, Line => 0.5s, 1, Line => ramp, 0
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
    function edit_song(song; ramp = 0.1s, options...)

Use to edit songs interactively. 
The interface might be slow at first while Julia is compiling.

- `song` is a YAML string or a vector of [`Chord`](@refs)s.
- `ramp` is the onset/offset time, in time units (like `s`).
- `options` will be passed to [`make_schedule`](@ref).

For more information, see the `README`.

Try running `ENV["QT_QPA_PLATFORM"] = "xcb"` on [Wayland](https://github.com/barche/QML.jl/issues/125).

```julia
julia> using Justly

julia> song = Chord[];

julia> edit_song(song)
```
"""
function edit_song(song;
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
    qmlfunction("to_yaml", let song = song
        () -> YAML.write(song)
    end)

    chords_model = ListModel(song)
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
    press_task = @spawn press!(buffer, song, presses, releases;
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
            simple_yaml = "- notes:\n    - interval: \"3/2o1\"\n    - {}\n- {}\n"
            from_yaml!(chords_model, simple_yaml)
            # note: this is 1, 1 in julia
            put!(presses, (0, 0))
            put!(releases, nothing)
            put!(presses, (0, -1))
            put!(releases, nothing)
            @test String(YAML.write(song)) == simple_yaml
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
        Map(Scale(volume), Map(wave, Cycles(key * Rational(note.interval)))),
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
    key = key * Rational(chord.interval)
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

function add_chord!(a_schedule, song::Vector, clock, key;
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE
)
    for chord in song
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

Create an `AudioSchedule` from your song.
- `song` is a `YAML` string or a vector of [`Chord`](@ref)s.
- `beat_duration` is the duration of a beat, with time units (like `s`).
- `initial_key` is initial key of your song, in frequency units (like `Hz`). 
- `make_envelope` is a function to make an envelope, like [`pluck`](@ref) or [`pedal`](@ref).
- `sample_rate` is the sample rate, in frequency units (like `Hz`).
- `volume`, ranging from 0-1, is the volume that a single voice is played at.
- `wave` is a function which takes an angle in radians and returns an amplitude between -1 and 1.

For more information, see the `README`.

For example, to create a simple I-IV-I figure,

```jldoctest make_schedule
julia> using Justly

julia> using YAML: load

julia> make_schedule(\"""
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
                - interval: "o2"
            - words: "I"
              interval: "3/2"
              notes:
                - {}
                - interval: "3/2"
                - interval: "5/4o1"
              
         \""")
1.85 s 44100.0 Hz AudioSchedule
```

Top-level lists will be unnested, so you can use YAML anchors to repeat themes.

```jldoctest make_schedule
julia> make_schedule(\"""
            - &fifth
                - notes:
                    - {}
                    - interval: "3/2"
            - *fifth
        \""")
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

function make_schedule(song::AbstractString; kwargs...)
    make_schedule(load(song; dicttype=Dict{Symbol,Any}); kwargs...)
end
export make_schedule

end
