module Justly

import AudioSchedules: AudioSchedule
using AudioSchedules:
    Cycles,
    @envelope,
    Grow,
    Line,
    make_series,
    Map,
    SawTooth,
    Scale,
    write_buffer,
    write_series!
import Base: parse, print, push!, Rational, show
using Base: catch_backtrace
using Base.Meta: ParseError
using Base.Threads: @spawn
using FunctionWrappers: FunctionWrapper
using Observables: Observable
using PortAudio: Buffer, PortAudioStream
using QML:
    addrole,
    exec,
    JuliaPropertyMap,
    ListModel,
    loadqml,
    # to avoid QML bug
    QML,
    qmlfunction,
    setconstructor
using Qt5QuickControls2_jll: Qt5QuickControls2_jll
using YAML: load_file, write_file
using Unitful: Hz, s
# reexport to avoid a QML bug
export QML

"""
    default_wave(x)

A wave with many overtones, namely,

    sin(x) +
    0.2sin(2x) +
    0.166sin(3x) +
    0.133sin(4x) +
    0.1sin(5x) +
    0.066sin(6x) +
    0.033sin(7x)
"""
function default_wave(x)
    sin(x) +
    0.2sin(2x) +
    0.166sin(3x) +
    0.133sin(4x) +
    0.1sin(5x) +
    0.066sin(6x) +
    0.033sin(7x)
end

export default_wave

const FLOAT_SECONDS = typeof(0.0s)

precompile(default_wave, (Float64,))

# make sure to show user the line number
function throw_parse_error(text, description, line_number)
    throw(ParseError(string("Can't parse $text as $description on line $line_number")))
end

const INSTRUMENT_ARGUMENT_TYPES =
    (AudioSchedule, typeof(0.0s), typeof(1.0s), Float64, typeof(440.0Hz))

"""
    pulse!(audio_schedule, start_time, duration, volume, frequency;
        ramp_duration = 0.07s,
        decay_rate = -4/s
    )

A function for an [`Instrument`](@ref).

Uses the wave function [`default_wave`](@ref).
Add an envelope with an exponential `decay_rate` and ramps of `ramp_duration` at the beginning and end.
"""
function pulse!(
    audio_schedule,
    start_time,
    duration,
    volume,
    frequency;
    ramp_duration = 0.07s,
    decay_rate = -4 / s,
)
    sustain_duration = duration - ramp_duration
    push!(
        audio_schedule,
        Map(default_wave, Cycles(frequency)),
        start_time,
        if duration < ramp_duration
            @envelope(0, Line => duration / 2, volume, Line => duration / 2, 0)
        else
            @envelope(
                0,
                Line => ramp_duration,
                volume,
                Grow => sustain_duration,
                volume * exp(sustain_duration * decay_rate),
                Line => ramp_duration,
                0
            )
        end,
    )
end

precompile(pulse!, INSTRUMENT_ARGUMENT_TYPES)

export pulse!

"""
    sustain!(audio_schedule, start_time, duration, volume, frequency;
        ramp_duration = 0.07s
    )

A function for an [`Instrument`](@ref).

Uses the wave function [`default_wave`](@ref).
Add an envelope with ramps of `ramp_duration` at the beginning and end.
"""
function sustain!(
    audio_schedule,
    start_time,
    duration,
    volume,
    frequency;
    ramp_duration = 0.07s,
)
    sustain_duration = duration - ramp_duration
    push!(
        audio_schedule,
        Map(default_wave, Cycles(frequency)),
        start_time,
        if duration < ramp_duration
            @envelope(0, Line => duration / 2, volume, Line => duration / 2, 0)
        else
            @envelope(
                0,
                Line => ramp_duration,
                volume,
                Line => sustain_duration,
                volume,
                Line => ramp_duration,
                0
            )
        end,
    )
end

precompile(sustain!, INSTRUMENT_ARGUMENT_TYPES)

include("Instrument.jl")
include("Interval.jl")
include("Modulation.jl")
include("Note.jl")
include("Chord.jl")
include("Song.jl")

function precompile_schedule(audio_schedule, buffer)
    for series in audio_schedule
        write_series!(buffer, view(series, 1:1), 0)
    end
end

precompile(precompile_schedule, (AudioSchedule, Buffer{Float32}))

function play_sounds!(song, presses, releases, buffer, audio_schedule)
    chords = song.chords
    for (press_type, press_arguments) in presses
        if press_type === :chord
            (chord_index,) = press_arguments
            buffer_at = 0
            push!(audio_schedule, song; from_chord = chord_index)

            precompiling_observable = song.precompiling_observable
            precompiling_observable[] = true
            precompile_schedule(audio_schedule, buffer)
            precompiling_observable[] = false

            Base.GC.enable(false)
            for series in audio_schedule
                if isready(releases)
                    break
                end
                buffer_at = write_series!(buffer, series, buffer_at)
            end
            write_buffer(buffer, buffer_at)
            Base.GC.enable(true)

            empty!(audio_schedule)
            take!(releases)
        elseif press_type === :note
            (chord_index, note_index) = press_arguments
            buffer_at = 0
            # cumulative product of previous modulations
            volume = song.volume_observable[]
            frequency = (song.frequency_observable[])Hz
            for chord in chords[1:chord_index]
                volume = volume * chord.modulation.volume
                frequency = frequency * Rational(chord.modulation.interval)
            end

            note = song.chords[chord_index].notes[note_index]
            note.instrument.note_function!(
                audio_schedule,
                0.0s,
                0.5s,
                volume * note.volume,
                frequency * Rational(note.interval),
            )
            Base.GC.enable(false)
            for series in audio_schedule
                buffer_at = write_series!(buffer, series, buffer_at)
            end
            write_buffer(buffer, buffer_at)
            Base.GC.enable(true)

            empty!(audio_schedule)
            take!(releases)
        else
            throw(ArgumentError("Press type $press_type not recognized"))
        end
    end
end

precompile(
    play_sounds!,
    (Song, Channel{Tuple{Symbol, Tuple}}, Channel{Nothing}, Buffer{Float32}, AudioSchedule),
)

"""
    function edit_justly(song_file, instruments = DEFAULT_INSTRUMENTS; 
        test = false
    )

Use to edit songs interactively. 
The interface might be slow at first while Julia is compiling.

- `song_file` is a YAML file. Will be created if it doesn't exist.
- `instruments` are a vector of [`Instrument`](@ref)s, with the default [`DEFAULT_INSTRUMENTS`](@ref).

For more information, see the `README`.

```julia
julia> using Justly

julia> edit_justly(joinpath(pkgdir(Justly), "examples", "simple.yml"); test = true)

julia> edit_justly(joinpath(pkgdir(Justly), "not_a_folder", "simple.yml"))
ERROR: ArgumentError: Folder doesn't exist!
[...]
```
"""
function edit_justly(song_file, instruments = DEFAULT_INSTRUMENTS; test = false)
    song = if isfile(song_file)
        read_justly(song_file, instruments)
    else
        dir_name = dirname(song_file)
        if !(isempty(dir_name)) && !(isdir(dir_name))
            throw(ArgumentError("Folder doesn't exist!"))
        end
        @info "Creating file $song_file"
        Song(instruments)
    end

    presses = Channel{Tuple{Symbol, Tuple}}(0)
    qmlfunction("press_chord", let presses = presses
        chord_index -> put!(presses, (:chord, (chord_index,)))
    end)

    qmlfunction(
        "press_note",
        let presses = presses
            (chord_index, note_index) -> put!(presses, (:note, (chord_index, note_index)))
        end,
    )

    releases = Channel{Nothing}(0)
    qmlfunction("release", let releases = releases
        () -> put!(releases, nothing)
    end)

    stream = PortAudioStream(0, 1; latency = 0.2, warn_xruns = false)
    buffer = stream.sink_messenger.buffer

    audio_schedule = AudioSchedule()

    instruments = song.instruments

    # precompile note
    for instrument in instruments
        instrument.note_function!(
            audio_schedule,
            0.0s,
            0.5s,
            song.volume_observable[],
            (song.frequency_observable[])Hz,
        )
    end
    # precompile song
    push!(audio_schedule, song)
    precompile_schedule(audio_schedule, buffer)
    empty!(audio_schedule)

    press_task = @spawn play_sounds!($song, $presses, $releases, $buffer, $audio_schedule)

    loadqml(
        joinpath(@__DIR__, "Song.qml");
        test = test,
        chords_model = make_list_model(song.chords, instruments),
        instruments_model = make_list_model(instruments),
        julia_arguments = JuliaPropertyMap(
            "volume" => song.volume_observable,
            "frequency" => song.frequency_observable,
            "tempo" => song.tempo_observable,
            "precompiling" => song.precompiling_observable,
        ),
    )

    try
        exec()
    catch an_error
        @warn "QML frozen. You must restart julia!"
        showerror(stdout, an_error, catch_backtrace())
    finally
        if test
            # play the first note of the first chord
            precompile_schedule(audio_schedule, buffer)
            put!(presses, (:note, (1, 1)))
            put!(releases, nothing)
            # play the first chord
            put!(presses, (:chord, (1,)))
            put!(releases, nothing)
        end
        close(presses)
        close(releases)
        close(stream)
        wait(press_task)
        write_justly(song_file, song)
    end
    nothing
end
export edit_justly

precompile(edit_justly, (String,))

end

# TODO:
# undo/redo 
# copy/paste
# change tempo?
