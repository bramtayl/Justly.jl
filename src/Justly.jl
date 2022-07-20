module Justly

import AudioSchedules: AudioSchedule
using AudioSchedules:
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

    audio_schedule = AudioSchedule()

    presses = Channel{Tuple{String, Tuple}}(0)
    
    instruments = song.instruments
    
    @sync begin
        produce_task = @spawn begin
            try
                qmlfunction("press", let presses = presses
                    (action_type, arguments...) -> put!(presses, (action_type, arguments))
                end)
                qmlfunction("release", let is_on = audio_schedule.is_on
                    () -> is_on[] = false
                end)
                loadqml(
                    joinpath(@__DIR__, "main.qml");
                    test = test,
                    chords_model = make_list_model(song.chords, instruments),
                    instruments_model = make_list_model(instruments),
                    empty_notes_model = make_list_model(Note[], instruments),
                    julia_arguments = JuliaPropertyMap(
                        "volume" => song.volume_observable,
                        "frequency" => song.frequency_observable,
                        "tempo" => song.tempo_observable,
                        "precompiling" => song.precompiling_observable
                    ),
                )
                exec()
                if $test
                    # play the first note of the first chord
                    put!($presses, ("play notes", (1, 1, 1)))
                    # play the first chord
                    put!($presses, ("play chords", (1,)))
                end
            catch an_error
                @warn "QML frozen. You must restart julia!"
                showerror($stdout, an_error, catch_backtrace())
            end
        end
        bind(presses, produce_task)
        PortAudioStream(0, 1; latency = 0.2, warn_xruns = false) do stream
            for (press_type, press_arguments) in presses
                audio_schedule.is_on[] = true
                if press_type == "play notes"
                    play_notes!(audio_schedule, song, press_arguments...)
                elseif press_type == "play chords"
                    play_chords!(audio_schedule, song, press_arguments...)
                else
                    throw(ArgumentError("Press type $press_type not recognized"))
                end
                write(stream, audio_schedule)
                empty!(audio_schedule)
            end
        end
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
