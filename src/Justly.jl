module Justly

using AudioSchedules:
    add!,
    AudioSchedule,
    Cycles,
    fill_all_task_ios,
    Hook,
    Line,
    Map,
    QUOTIENT,
    SawTooth,
    Scale,
    triples,
    Weaver,
    write_buffer,
    write_series!
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
using YAML: load, load_file, write_file
import YAML: _print

# reexport to avoid a QML bug
export QML

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
    octave = INTERVAL_DEFAULTS.octave,
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
        get_parse(a_match, :octave),
    )
end

function Interval(interval::Interval)
    interval
end

@inline function print_no_default(io, interval, prefix, property)
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
    print_no_default(io, interval, '/', :denominator)
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

@inline function getproperty(note::Note, property::Symbol)
    if property === :interval
        get_interval(note)
    else
        getfield(note, property)
    end
end

function Note(; interval = CHORD_DEFAULTS.interval, beats = CHORD_DEFAULTS.beats)
    # convert strings and rationals to intervals first
    Note(interval_pieces(Interval(interval))..., beats)
end

"""
mutable struct Chord

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

@inline function getproperty(chord::Chord, property::Symbol)
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
    notes = Note[],
)
    Chord(words, interval_pieces(Interval(interval))..., beats, notes, ListModel(notes))
end

@inline function print_no_default(io, note_or_chord, property, level, ignore_level, empty)
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
function _print(io::IO, note::Note, level::Int = 0, ignore_level::Bool = false)
    empty = true
    empty = print_no_default(io, note, :interval, level, ignore_level, empty)
    empty = print_no_default(io, note, :beats, level, ignore_level, empty)
    print_empty(io, empty)
end

function _print(io::IO, chord::Chord, level::Int = 0, ignore_level::Bool = false)
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
        beats = get_default(dictionary, :beats),
    )
end

# TODO: add a special constructor to avoid Dict intermediates
function parse_chord(dictionary)
    Chord(;
        interval = get_default(dictionary, :interval),
        words = get_default(dictionary, :words),
        beats = get_default(dictionary, :beats),
        # empty lists will come in as nothing
        notes = map(parse_note, get(dictionary, :notes, Dict{Symbol, Any}[])),
    )
end

function add_chord!(song, dictionary::Dict)
    push!(song, parse_chord(dictionary))
end

function add_chord!(song, new_chords::Vector)
    for chord in new_chords
        add_chord!(song, chord)
    end
end

function duration_to_samples(sample_rate, wave, duration)
    wave, round(Int, duration * sample_rate)
end

function precompile_song(
    task_ios,
    song,
    buffer;
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
)
    for (series, _) in make_schedule(
        song;
        beat_duration = beat_duration,
        initial_key = initial_key,
        make_envelope = make_envelope,
        sample_rate = sample_rate,
        volume = volume,
        wave = wave,
    )
        write_series!(task_ios, series, 1, buffer, 0)
    end
end

function get_dummy_envelope(
    frequency;
    ramp = DEFAULT_RAMP,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
)
    map(
        function ((wave, start_time, duration),)
            duration_to_samples(sample_rate, wave, duration)
        end,
        triples(
            sample_rate,
            Map(Scale(volume), Map(wave, Cycles(frequency))),
            0s,
            0,
            Line => ramp,
            1,
            Line => 0.5s,
            1,
            Line => ramp,
            0,
        ),
    )
end

function press!(
    task_ios,
    song,
    presses,
    releases,
    buffer;
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    ramp = DEFAULT_RAMP,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
)
    (ramp_up, sustain, ramp_down) = get_dummy_envelope(
        440Hz;
        ramp = ramp,
        sample_rate = sample_rate,
        volume = volume,
        wave = wave,
    )
    write_series!(task_ios, ramp_up[1], 1, buffer, 0)
    write_series!(task_ios, sustain[1], 1, buffer, 0)
    write_series!(task_ios, ramp_down[1], 1, buffer, 0)
    precompile_song(
        task_ios,
        song,
        buffer;
        beat_duration = beat_duration,
        initial_key = initial_key,
        make_envelope = make_envelope,
        sample_rate = sample_rate,
        volume = volume,
        wave = wave,
    )
    for (chord_index, voice_index) in presses
        buffer_at = 0
        if voice_index < 0
            precompile_song(
                task_ios,
                song,
                buffer;
                beat_duration = beat_duration,
                initial_key = initial_key,
                make_envelope = make_envelope,
                sample_rate = sample_rate,
                volume = volume,
                wave = wave,
            )
            # run once to precompile
            for (series, series_total) in make_schedule(
                (@view song[(chord_index + 1):end]);
                beat_duration = beat_duration,
                initial_key = update_key(song, initial_key, chord_index - 1),
                make_envelope = make_envelope,
                sample_rate = sample_rate,
                volume = volume,
                wave = wave,
            )
                if isready(releases)
                    break
                end
                buffer_at = write_series!(task_ios, series, series_total, buffer, buffer_at)
            end
        else
            # all three will be pairs of iterators and number of frames
            (ramp_up, sustain, ramp_down) = get_dummy_envelope(
                update_key(song, initial_key, chord_index) *
                Rational(song[chord_index + 1].notes[voice_index + 1].interval);
                ramp = ramp,
                sample_rate = sample_rate,
                volume = volume,
                wave = wave,
            )
            buffer_at = write_series!(task_ios, ramp_up..., buffer, buffer_at)
            while !isready(releases)
                buffer_at = write_series!(task_ios, sustain..., buffer, buffer_at)
            end
            buffer_at = write_series!(task_ios, ramp_down..., buffer, buffer_at)
        end
        write_buffer(buffer, buffer_at)
        take!(releases)
    end
end

"""
    function edit_song(song_file; 
        ramp = 0.1s, 
        number_of_tasks = nthreads() - 2, 
        test = false, 
        options...
    )

Use to edit songs interactively. 
The interface might be slow at first while Julia is compiling.

- `song_file` is a YAML string or a vector of [`Chord`](@refs)s. Will be created if it doesn't exist.
- `ramp` is the onset/offset time, in time units (like `s`).
- `number_of_tasks` is the number of tasks to use to process data. Defaults to 2 less than the number of threads; we need 1 master thread for QML and 1 master thread for AudioSchedules.
- If `test` is true, will open the editor briefly to test it.
- `options` will be passed to [`make_schedule`](@ref).

For more information, see the `README`.

Try running `ENV["QT_QPA_PLATFORM"] = "xcb"` on [Wayland](https://github.com/barche/QML.jl/issues/125).

```julia
julia> using Justly

julia> write("test_song.yml", \"""
- interval: "2/3"
  notes:
    - interval: "3/2"
\""")

julia> edit_song("test_song.yml")

julia> rm("test_song.yml")
```
"""
function edit_song(
    song_file;
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    number_of_tasks = nthreads() - 2,
    ramp = DEFAULT_RAMP,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
    test = false,
)
    if nthreads() < 3
        error("Justly needs at least 3 threads to function")
    end

    song = Chord[]
    if isfile(song_file)
        parsed = load_file(song_file; dicttype = Dict{Symbol, Any})
        if !(parsed isa Vector)
            throw(ArgumentError("Isn't a list of chords"))
        end
        for chord in parsed
            add_chord!(song, chord)
        end
    end

    chords_model = ListModel(song)

    presses = Channel{Tuple{Int, Int}}(0)

    qmlfunction(
        "press",
        let presses = presses
            (chord_index, voice_index) -> put!(presses, (chord_index, voice_index))
        end,
    )

    releases = Channel{Nothing}(0)
    qmlfunction("release", let releases = releases
        () -> put!(releases, nothing)
    end)

    qmlfunction("to_yaml", let song_file = song_file, song = song
        () -> write_file(song_file, song)
    end)

    loadqml(joinpath(@__DIR__, "Justly.qml"), chords_model = chords_model, test = test)
    stream = PortAudioStream(0, 1, writer = Weaver(); warn_xruns = false)
    buffer = stream.sink_messanger.buffer
    task_ios = fill_all_task_ios(buffer; number_of_tasks = number_of_tasks)
    press_task = Task(
        let task_ios = task_ios,
            song = song,
            presses = presses,
            releases = releases,
            buffer = buffer,
            beat_duration = beat_duration,
            initial_key = initial_key,
            make_envelope = make_envelope,
            ramp = ramp,
            sample_rate = sample_rate,
            volume = volume,
            wave = wave

            () -> press!(
                task_ios,
                song,
                presses,
                releases,
                buffer;
                beat_duration = beat_duration,
                initial_key = initial_key,
                make_envelope = make_envelope,
                ramp = ramp,
                sample_rate = sample_rate,
                volume = volume,
                wave = wave,
            )
        end,
    )
    press_task.sticky = false
    schedule(press_task)
    if test
        # note: this is 1, 1 in julia
        put!(presses, (0, 0))
        put!(releases, nothing)
        put!(presses, (0, -1))
        put!(releases, nothing)
    end
    try
        try
            exec()
        finally
            # to catch errors in the task
            close(presses)
            wait(press_task)
        end
    catch an_error
        println("QML errored:")
        showerror(stdout, an_error)
    end
    close(releases)
    close(stream)
    nothing
end
export edit_song

function add_note!(
    a_schedule,
    note,
    clock,
    key;
    wave = DEFAULT_WAVE,
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME,
)
    add!(
        a_schedule,
        Map(Scale(volume), Map(wave, Cycles(key * Rational(note.interval)))),
        clock,
        make_envelope(note.beats * beat_duration)...,
    )
end

function add_chord!(
    a_schedule,
    chord::Chord,
    clock,
    key;
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
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

            note -> add_note!(
                a_schedule,
                note,
                clock,
                key;
                wave = wave,
                beat_duration = beat_duration,
                make_envelope = make_envelope,
                volume = volume,
            )
        end,
        chord.notes,
    )
    key, clock + chord.beats * beat_duration
end

function add_chord!(a_schedule, dictionary::Dict, clock, key; options...)
    add_chord!(a_schedule, parse_chord(dictionary), clock, key; options...)
end

function add_chord!(
    a_schedule,
    song::Vector,
    clock,
    key;
    beat_duration = DEFAULT_BEAT_DURATION,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
)
    for chord in song
        key, clock = add_chord!(
            a_schedule,
            chord,
            clock,
            key;
            beat_duration = beat_duration,
            make_envelope = make_envelope,
            volume = volume,
            wave = wave,
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
function make_schedule(
    song;
    beat_duration = DEFAULT_BEAT_DURATION,
    initial_key = DEFAULT_INITIAL_KEY,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    wave = DEFAULT_WAVE,
)
    clock = 0s
    key = initial_key
    a_schedule = AudioSchedule(; sample_rate = sample_rate)
    for chord in song
        key, clock = add_chord!(
            a_schedule,
            chord,
            clock,
            key;
            beat_duration = beat_duration,
            make_envelope = make_envelope,
            volume = volume,
            wave = wave,
        )
    end
    a_schedule
end

function make_schedule(song::AbstractString; kwargs...)
    make_schedule(load(song; dicttype = Dict{Symbol, Any}); kwargs...)
end
export make_schedule

end
