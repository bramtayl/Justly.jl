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
    exec,
    ListModel,
    addrole,
    JuliaPropertyMap,
    loadqml,
    # to avoid QML bug
    QML,
    qmlfunction,
    setconstructor
using Qt5QuickControls2_jll: Qt5QuickControls2_jll
import SampledSignals: SampleBuf
using Unitful: Hz, s
# reexport to avoid a QML bug
export QML

"""
    default_wave(x)

A wave with many overtones.

    sin(x) +
    0.2sin(2x) +
    0.166sin(3x) +
    0.133sin(4x) +
    0.1sin(5x) +
    0.066sin(6x) +
    0.033sin(7x)
"""
function default_wave(x)
    sin(x) + 0.2sin(2x) + 0.166sin(3x) + 0.133sin(4x) + 0.1sin(5x) + 0.066sin(6x) + 0.033sin(7x)
end
export wave

const FLOAT_SECONDS = typeof(0.0s)

precompile(default_wave, (Float64,))

# make sure to show user the line number
function throw_parse_error(text, description, line_number)
    throw(ParseError(string("Can't parse $text as $description on line $line_number")))
end

const INSTRUMENT_ARGUMENT_TYPES = (
    AudioSchedule,
    typeof(0.0s),
    typeof(1.0s),
    Float64,
    typeof(440.0Hz)
)

"""
    pluck(duration; ramp_duration = 0.05s, decay_rate = -4/s)

You can use `pluck` to make an envelope with an exponential decay_rate and ramps at the beginning and end.

- `ramp_duration` is the duration of the ramps at the beginning and end.
- `decay_rate` is the continuous negative decay rate.
"""
function pulse(audio_schedule, start_time, duration, volume, frequency; ramp_duration = 0.07s, decay_rate = -4/s)
    sustain_duration = duration - ramp_duration
    push!(audio_schedule,
        Map(default_wave, Cycles(frequency)),
        start_time,
        if duration < ramp_duration
            @envelope(
                0,
                Line => duration / 2,
                volume,
                Line => duration / 2,
                0
            )
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
        end
    )
end

precompile(pulse, INSTRUMENT_ARGUMENT_TYPES)

"""
    pluck(duration; ramp_duration = 0.05s, decay_rate = -4/s)

You can use `pluck` to make an envelope with an exponential decay_rate and ramps at the beginning and end.

- `ramp_duration` is the duration of the ramps at the beginning and end.
- `decay_rate` is the continuous negative decay rate.
"""
function sustain(audio_schedule, start_time, duration, volume, frequency; ramp_duration = 0.07s)
    sustain_duration = duration - ramp_duration
    push!(audio_schedule,
        Map(default_wave, Cycles(frequency)),
        start_time,
        if duration < ramp_duration
            @envelope(
                0,
                Line => duration / 2,
                volume,
                Line => duration / 2,
                0
            )
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
        end
    )
end

precompile(sustain, INSTRUMENT_ARGUMENT_TYPES)

const INSTRUMENT_TYPE = 
    FunctionWrapper{Nothing, Tuple{INSTRUMENT_ARGUMENT_TYPES...}}

const DEFAULT_INSTRUMENTS = Dict{String, INSTRUMENT_TYPE}()
DEFAULT_INSTRUMENTS["pulse"] = pulse
DEFAULT_INSTRUMENTS["sustain"] = sustain

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
    volume_observable = song.volume_observable
    frequency_observable = song.frequency_observable
    precompiling_observable = song.precompiling_observable
    instruments = song.instruments
    instrument_names = song.instrument_names
    for (chord_index, note_index) in presses
        buffer_at = 0
        if note_index < 0
            push!(audio_schedule, song; from_chord = chord_index)

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
        else
            # cumulative product of previous modulations
            volume = volume_observable[]
            frequency = (frequency_observable[])Hz
            for chord in chords[1:chord_index] 
                volume = volume * chord.modulation.volume
                frequency = frequency * Rational(chord.modulation.interval)
            end

            note = song.chords[chord_index].notes[note_index]
            instruments[instrument_names[note.instrument_number]](
                audio_schedule,
                0.0s,
                0.5s,
                volume * note.volume,
                frequency * Rational(note.interval)
            )
            Base.GC.enable(false)
            for series in audio_schedule
                buffer_at = write_series!(buffer, series, buffer_at)
            end
            write_buffer(buffer, buffer_at)
            Base.GC.enable(true)
            
            empty!(audio_schedule)
            take!(releases)
        end
    end
end

precompile(play_sounds!, (
    Song,
    Channel{Tuple{Int, Int}},
    Channel{Nothing},
    Buffer{Float32},
    AudioSchedule
))

function list_model(instrument_names::Vector{String})
    list_model = ListModel(instrument_names, false)
    addrole(list_model, "text", identity)
    list_model
end

# TODO: precompile

"""
    function edit_justly(song_file; 
        test = false, 
        keywords...
    )

Use to edit songs interactively. 
The interface might be slow at first while Julia is compiling.

- `song_file` is a YAML string or a vector of [`Chord`](@refs)s. Will be created if it doesn't exist.
- `keywords` will be passed to [`read_justly`](@ref).

For more information, see the `README`.

```julia
julia> using Justly

julia> edit_justly(joinpath(pkgdir(Justly), "examples", "simple.justly"); test = true)

julia> edit_justly(joinpath(pkgdir(Justly), "not_a_folder", "simple.justly"); test = true)
ERROR: ArgumentError: Folder doesn't exist!
[...]
```
"""
function edit_justly(
    song_file;
    test = false,
    keyword_arguments...,
)
    song = if isfile(song_file)
        read_justly(song_file; keyword_arguments...)
    else
        @info "Creating file $song_file"
        dir_name = dirname(song_file)
        if !(isempty(dir_name)) && !(isdir(dir_name))
            throw(ArgumentError("Folder doesn't exist!"))
        end
        Song(Chord[]; keyword_arguments...)
    end

    instruments = song.instruments
    instrument_names = song.instrument_names

    presses = Channel{Tuple{Int, Int}}(0)
    qmlfunction(
        "press",
        let presses = presses
            (chord_index, note_index) -> put!(presses, (chord_index, note_index))
        end,
    )

    releases = Channel{Nothing}(0)
    qmlfunction("release", let releases = releases
        () -> put!(releases, nothing)
    end)

    qmlfunction("update_file", let song_file = song_file, song = song
        () -> open(
            let song = song
                io -> print(io, song)
            end,
            song_file,
            write = true
        )
    end)

    stream = PortAudioStream(0, 1;
        latency = 0.2,
        warn_xruns = false
    )
    buffer = stream.sink_messenger.buffer

    audio_schedule = AudioSchedule()

    # precompile note
    for instrument in values(instruments)
        instrument(
            audio_schedule,
            0.0s,
            0.5s,
            song.volume_observable[],
            (song.frequency_observable[])Hz
        )
    end
    precompile_schedule(audio_schedule, buffer)
    empty!(audio_schedule)

    # precompile song
    push!(audio_schedule, song)
    precompile_schedule(audio_schedule, buffer)
    empty!(audio_schedule)

    press_task = @spawn play_sounds!($song, $presses, $releases, $buffer, $audio_schedule)

    loadqml(
        joinpath(@__DIR__, "Song.qml");
        test = test,
        chords_model = list_model(song.chords),
        instrument_names_model = list_model(instrument_names),
        julia_arguments = JuliaPropertyMap(
            "volume" => song.volume_observable,
            "frequency" => song.frequency_observable,
            "tempo" => song.tempo_observable,
            "precompiling" => song.precompiling_observable
        )
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
            put!(presses, (1, 1))
            put!(releases, nothing)
            # play the first chord
            put!(presses, (1, -1))
            put!(releases, nothing)
        end
        close(presses)
        close(releases)
        close(stream)
        wait(press_task)
    end
    nothing
end
export edit_justly

precompile(edit_justly, (String,))

end
