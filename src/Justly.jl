module Justly

import AudioSchedules: AudioSchedule
using AudioSchedules:
    compile,
    Cycles,
    @envelope,
    Grow,
    Line,
    make_series,
    Map,
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

include("Instrument.jl")
include("Interval.jl")
include("Modulation.jl")
include("Note.jl")
include("Chord.jl")
include("Song.jl")

function add_press!(audio_schedule, song, press_type, @nospecialize press_arguments)
    if press_type == "play notes"
        add_notes!(audio_schedule, song, press_arguments...)
    elseif press_type == "play chords"
        add_chords!(audio_schedule, song, press_arguments...)
    else
        throw(ArgumentError("Press type \"$press_type\" not recognized"))
    end
end

function consume!(presses, stream, song, audio_schedule)
    precompiling_observable = song.precompiling_observable
    for (press_type, press_arguments) in presses
        audio_schedule.is_on[] = true
        add_press!(audio_schedule, song, press_type, press_arguments)
        precompiling_observable[] = true
        compile(stream, audio_schedule)
        precompiling_observable[] = false
        GC.enable(false)
        write(stream, audio_schedule)
        GC.enable(true)
        empty!(audio_schedule)
    end
end

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

julia> edit_justly(joinpath(pkgdir(Justly), "examples", "simple.yml"))
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
    instruments = song.instruments
    presses = Channel{Tuple{String, Tuple}}(0)

    stream = PortAudioStream(0, 1; latency = 0.2, warn_xruns = false)
    try
        audio_schedule = AudioSchedule(; sample_rate = (stream.sample_rate)Hz)
        # precompile the whole song
        push!(audio_schedule, song)
        compile(stream, audio_schedule)
        empty!(audio_schedule)
        consume_task = @spawn consume!($presses, $stream, $song, $audio_schedule)
        try
            qmlfunction(
                "press",
                let presses = presses
                    (action_type, arguments...) -> put!(presses, (action_type, arguments))
                end,
            )
            qmlfunction("release", let is_on = audio_schedule.is_on
                () -> is_on[] = false
            end)
            loadqml(
                joinpath(@__DIR__, "Song.qml");
                test = test,
                chords_model = make_list_model(song.chords, instruments),
                instruments_model = make_list_model(instruments),
                empty_notes_model = make_list_model(Note[], instruments),
                julia_arguments = JuliaPropertyMap(
                    "volume" => song.volume_observable,
                    "frequency" => song.frequency_observable,
                    "tempo" => song.tempo_observable,
                    "precompiling" => song.precompiling_observable,
                ),
            )
            exec()
            if test
                # precompile before each play
                # play the second note of the second chord
                put!(presses, ("play notes", (2, 2, 2)))
                # play the second chord
                put!(presses, ("play chords", (2, 2)))
                # play starting with the second chord
                put!(presses, ("play chords", (2,)))
            end
        catch an_error
            showerror(stdout, an_error, catch_backtrace())
        finally
            close(presses)
            wait(consume_task)
        end
    finally
        close(stream)
    end
    write_justly(song_file, song)
end
export edit_justly

precompile(edit_justly, (String,))

end

# TODO:
# undo/redo 
# copy/paste
# change tempo?
