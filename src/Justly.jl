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

const FLOAT_SECONDS = typeof(0.0s)

# make sure to show user the line number
function throw_parse_error(text, description, line_number)
    throw(ParseError(string("Can't parse $text as $description on line $line_number")))
end

"""
    pluck(duration; ramp_duration = 0.05s, decay_rate = -4/s)

You can use `pluck` to make an envelope with an exponential decay_rate and ramps at the beginning and end.

- `ramp_duration` is the duration of the ramps at the beginning and end.
- `decay_rate` is the continuous negative decay rate.
"""
function pluck(duration; ramp_duration = 0.07s, decay_rate = -4/s)
    sustain_duration = duration - ramp_duration
    if duration < ramp_duration
        @envelope(
            0,
            Line => duration / 2,
            1,
            Line => duration / 2,
            0
        )
    else
        @envelope(
            0,
            Line => ramp_duration,
            1,
            Grow => sustain_duration,
            1.0 * exp(sustain_duration * decay_rate),
            Line => ramp_duration,
            0
        )
    end
end
export pluck

precompile(pluck, (FLOAT_SECONDS,))

include("Interval.jl")
include("Note.jl")
include("Chord.jl")
include("Song.jl")

function precompile_schedule(audio_schedule, song, buffer)
    for series in audio_schedule
        write_series!(buffer, view(series, 1:1), 0)
    end
end

precompile(precompile_schedule, (AudioSchedule, DEFAULT_SONG, Buffer{Float32}))

function add_one_note!(audio_schedule, song, volume, frequency)
    push!(audio_schedule,
        Map(
            Scale(volume),
            Map(song.wave, Cycles(frequency))
        ),
        0.0s,
        song.make_envelope(0.5s),
    )
end

function play_sounds!(song, presses, releases, buffer, audio_schedule)
    for (chord_index, note_index) in presses
        buffer_at = 0
        if note_index < 0
            push!(audio_schedule, song; from_chord = chord_index)

            precompile_schedule(audio_schedule, song, buffer)
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
            volume = song.volume_observable[]
            frequency = (song.frequency_observable[])Hz
            for chord in song.chords[1:chord_index] 
                volume = volume * chord.volume
                frequency = frequency * Rational(chord.interval)
            end
            note = song.chords[chord_index].notes[note_index]
            add_one_note!(
                audio_schedule,
                song,
                volume * note.volume,
                frequency * Rational(note.interval)
            )            
            precompile_schedule(audio_schedule, song, buffer)
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
    DEFAULT_SONG,
    Channel{Tuple{Int, Int}},
    Channel{Nothing},
    Buffer{Float32},
    AudioSchedule
))

# TODO: precompile

"""
    function edit_song(song_file; 
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

julia> edit_song(joinpath(pkgdir(Justly), "examples", "simple.justly"); test = true)

julia> edit_song(joinpath(pkgdir(Justly), "not_a_folder", "simple.justly"); test = true)
ERROR: ArgumentError: Folder doesn't exist!
[...]
```
"""
function edit_song(
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

    # precompile song
    push!(audio_schedule, song)
    precompile_schedule(audio_schedule, song, buffer)
    empty!(audio_schedule)

    # precompile note
    add_one_note!(
        audio_schedule,
        song,
        song.volume_observable[],
        (song.frequency_observable[])Hz
    )
    precompile_schedule(audio_schedule, song, buffer)
    empty!(audio_schedule)

    press_task = @spawn play_sounds!($song, $presses, $releases, $buffer, $audio_schedule)

    loadqml(
        joinpath(@__DIR__, "Song.qml");
        test = test,
        chords_model = list_model(song.chords),
        observables = JuliaPropertyMap(
            "volume" => song.volume_observable,
            "frequency" => song.frequency_observable,
            "tempo" => song.tempo_observable,
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
            precompile_schedule(audio_schedule, song, buffer)
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
export edit_song

precompile(edit_song, (String,))

end
