module Justly

import AudioSchedules: AudioSchedule
using AudioSchedules:
    Cycles,
    Grow,
    fill_all_task_ios,
    Line,
    make_series,
    Map,
    SawTooth,
    Scale,
    triples,
    Weaver,
    write_buffer,
    write_series!
import Base: getproperty, parse, print, Rational, setproperty!, show
using Base.Meta: ParseError
using Base.Threads: nthreads, @spawn
using PortAudio: PortAudioStream
using QML:
    exec,
    ListModel,
    addrole,
    loadqml,
    # to avoid QML bug
    QML,
    qmlfunction,
    setconstructor
using Qt5QuickControls2_jll: Qt5QuickControls2_jll
using SampledSignals: samplerate
using Test: @test
using Unitful: Hz, ms, s, minute, uconvert

using YAML: load_file, write_file
import YAML: _print

# reexport to avoid a QML bug
export QML

const TIME = typeof(0.0s)
const FREQUENCY = typeof(0.0Hz)

function property_model(a_vector, property_names)
    list_model = ListModel(a_vector, false)
    for property_name in property_names
        addrole(
            list_model,
            String(property_name),
            let property_name = property_name
                item -> getproperty(item, property_name)
            end,
            let property_name = property_name, stdout = stdout
                (items, value, index) -> try
                    setproperty!(items[index], property_name, value)
                catch an_error
                    # errors will be ignored, so print them at least
                    showerror(stdout, an_error)
                end
            end,
        )
    end
    setconstructor(list_model, eltype(a_vector))
    list_model
end

"""
    pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1/2)

You can use `pedal` to make an envelope with a sustain and ramps at the beginning and end. 
`overlap` is the proportion of the ramps that overlap.
"""
function pedal(duration; attack_duration = 0.05s, decay = -3/s)
    sustain_duration = duration - attack_duration
    if duration < attack_duration
        (
            0,
            Line => duration / 2,
            1,
            Line => duration / 2,
            0
        )
    else
        (
            0,
            Line => attack_duration,
            1,
            Grow => sustain_duration,
            1.0 * exp(sustain_duration * decay),
            Line => attack_duration,
            0
        )
    end
end
export pedal

function throw_parse_error(text, description, line_number)
    throw(ParseError(string("Can't parse $text as $description on line $line_number")))
end

include("Interval.jl")
include("Note.jl")
include("Chord.jl")
include("Song.jl")
include("AudioSchedule.jl")

function get_dummy_envelope(song, frequency)
    ramp = song.ramp
    sample_rate = song.sample_rate
    map(
        (((wave, _, duration),) -> make_series(wave, sample_rate)[1:round(Int, duration * sample_rate)]),
        triples(
            Map(Scale(song.volume), Map(song.wave, Cycles(frequency))),
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

# cumulative product of previous modulations
function update_key(song, chord_index)
    key = song.initial_key
    for chord in view(song.chords, 1:(chord_index + 1))
        key = key * Rational(chord.modulation.interval)
    end
    key
end

function press!(task_ios, song, presses, releases, buffer)
    for (chord_index, voice_index) in presses
        buffer_at = 0
        if voice_index < 0
            Base.GC.enable(false)
            # todo: reduce allocations
            for series in collect(AudioSchedule(
                song;
                chords = (@view song.chords[(chord_index + 1):end]),
                initial_key = update_key(song, chord_index - 1),
            ))
                if isready(releases)
                    break
                end
                buffer_at = write_series!(task_ios, series, buffer, buffer_at)
            end
            write_buffer(buffer, buffer_at)
            Base.GC.enable(true)
            take!(releases)
        else
            Base.GC.enable(false)
            # all three will be pairs of iterators and number of frames
            (ramp_up, sustain, ramp_down) = get_dummy_envelope(
                song,
                update_key(song, chord_index) *
                Rational(song.chords[chord_index + 1].notes[voice_index + 1].interval),
            )
            buffer_at = write_series!(task_ios, ramp_up, buffer, buffer_at)
            buffer_at = write_series!(task_ios, sustain, buffer, buffer_at)
            buffer_at = write_series!(task_ios, ramp_down, buffer, buffer_at)
            write_buffer(buffer, buffer_at)
            Base.GC.enable(true)
        end
    end
end

const A440_MIDI_CODE = 69
const C0_MIDI_CODE = 12

function get_midi_code(frequency)
    A440_MIDI_CODE + 12 * log(frequency / 440Hz) / log(2)
end

function get_note_parts(midi_code)
    fldmod(round(Int, midi_code) - C0_MIDI_CODE, 12)
end

function get_frequency(midi_code)
    2.0^((midi_code - A440_MIDI_CODE) / 12) * 440Hz
end

const NOTE_NAMES =
    ("C", "C♯/D♭", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B")

function get_midi_name(midi_code)
    octave, degree = get_note_parts(midi_code)
    string("Initial key: ", NOTE_NAMES[degree + 1], "<sub>", octave, "</sub>")
end

"""
    function edit_song(song_file; 
        ramp = 0.1s, 
        number_of_tasks = nthreads() - 2, 
        test = false, 
        keyword_arguments...
    )

Use to edit songs interactively. 
The interface might be slow at first while Julia is compiling.

- `song_file` is a YAML string or a vector of [`Chord`](@refs)s. Will be created if it doesn't exist.
- `number_of_tasks` is the number of tasks to use to process data. Defaults to 2 less than the number of threads; we need 1 master thread for QML and 1 master thread for AudioSchedules.
- If `test` is true, will open the editor briefly to test it.
- `keyword_arguments` will be passed to [`read_justly`](@ref).

For more information, see the `README`.

```jldoctest
julia> using Justly

julia> edit_song(joinpath(pkgdir(Justly), "test", "song.justly"); test = true)
```
"""
function edit_song(
    song_file;
    number_of_tasks = nthreads() - 2,
    test = false,
    keyword_arguments...,
)
    if nthreads() < 3
        error("Justly needs at least 3 threads to function")
    end

    song = if isfile(song_file)
        read_justly(song_file; keyword_arguments...)
    else
        Song(; keyword_arguments...)
    end

    qmlfunction("get_midi_name", get_midi_name)

    qmlfunction("get_initial_midi_code", let song = song
        () -> get_initial_midi_code(song)
    end)

    qmlfunction(
        "update_initial_midi_code",
        let song = song
            midi_code -> update_initial_midi_code!(song, midi_code)
        end,
    )

    qmlfunction("get_beats_per_minute", let song = song
        () -> get_beats_per_minute(song)
    end)

    qmlfunction(
        "update_beats_per_minute",
        let song = song
            beats_per_minute -> update_beats_per_minute!(song, beats_per_minute)
        end,
    )

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

    print_function = let song = song
        io -> print(io, song)
    end

    qmlfunction("to_yaml", let song_file = song_file, print_function = print_function
        () -> open(print_function, song_file, write = true)
    end)

    stream = PortAudioStream(0, 1, writer = Weaver(); warn_xruns = false)
    buffer = stream.sink_messenger.buffer
    task_ios = fill_all_task_ios(buffer; number_of_tasks = number_of_tasks)
    loadqml(
        joinpath(@__DIR__, "Song.qml");
        chords_model = property_model(
            song.chords,
            (:numerator, :denominator, :octave, :beats, :words, :notes_model),
        ),
        test = test,
    )
    press_task = Task(
        let task_ios = task_ios,
            song = song,
            presses = presses,
            releases = releases,
            buffer = buffer

            () -> press!(task_ios, song, presses, releases, buffer)
        end,
    )
    press_task.sticky = false
    schedule(press_task)
    try
        exec()
        if test
            # note: this is 1, 1 in julia
            put!(presses, (0, 0))
            put!(presses, (0, -1))
            put!(releases, nothing)
        end
    catch an_error
        # can't error while QML is running, so just message
        println("Front-end errored:")
        showerror(stdout, an_error)
    finally
        close(presses)
        try
            wait(press_task)
        catch an_error
            # can't error while QML is running, so just message
            println("Back-end errored:")
            showerror(stdout, an_error)
        finally
            close(releases)
            close(stream)
        end
    end
    nothing
end
export edit_song

end
