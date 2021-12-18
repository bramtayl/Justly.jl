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
import Base: getproperty, Rational, setproperty!, show
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

function my_list_model(a_vector, property_names)
    list_model = ListModel(a_vector, false)
    for property_name in property_names
        addrole(
            list_model,
            String(property_name),
            let property_name = property_name
                item -> getproperty(item, property_name)
            end,
            let property_name = property_name
                (items, value, index) -> setproperty!(items[index], property_name, value)
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
function pedal(duration; slope = 1 / 0.1s, peak = 1, overlap = 1 / 2)
    ramp = peak / slope
    ramp_overlap = ramp * overlap
    # if it's too short, there won't be a plateau
    middle = duration - ramp - ramp + ramp_overlap
    if middle <= 0s
        half_duration = (duration + ramp_overlap) / 2
        short_peak = half_duration * slope
        (0, Line => half_duration, short_peak, Line => half_duration, 0)
    else
        (0, Line => ramp, peak, Line => middle, peak, Line => ramp, 0)
    end
end
export pedal

include("Interval.jl")
include("Note.jl")
include("Chord.jl")
include("Song.jl")
include("read_song.jl")

function precompile_song(task_ios, song, buffer)
    for (series, _) in make_schedule(song)
        write_series!(task_ios, series, 1, buffer, 0)
    end
end

function get_dummy_envelope(song, frequency)
    ramp = song.ramp
    sample_rate = song.sample_rate
    map(
        (((wave, _, duration),) -> (wave, round(Int, duration * sample_rate))),
        triples(
            sample_rate,
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
    (ramp_up, sustain, ramp_down) = get_dummy_envelope(song, 440.0Hz)
    # each is a pair of waves and number of samples
    # set the first index of the buffer to match each wave
    write_series!(task_ios, ramp_up[1], 1, buffer, 0)
    write_series!(task_ios, sustain[1], 1, buffer, 0)
    write_series!(task_ios, ramp_down[1], 1, buffer, 0)
    precompile_song(task_ios, song, buffer)
    for (chord_index, voice_index) in presses
        buffer_at = 0
        if voice_index < 0
            precompile_song(task_ios, song, buffer)
            for (series, series_total) in make_schedule(
                song;
                chords = (@view song.chords[(chord_index + 1):end]),
                initial_key = update_key(song, chord_index - 1),
            )
                if isready(releases)
                    break
                end
                buffer_at = write_series!(task_ios, series, series_total, buffer, buffer_at)
            end
        else
            # all three will be pairs of iterators and number of frames
            (ramp_up, sustain, ramp_down) = get_dummy_envelope(
                song,
                update_key(song, chord_index) *
                Rational(song.chords[chord_index + 1].notes[voice_index + 1].interval),
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

const NOTE_NAMES =
    ("C", "C♯/D♭", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B")

function get_midi_name(midi_code)
    octave, degree = fldmod(round(Int, midi_code) - 12, 12)
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
- `keyword_arguments` will be passed to [`read_song`](@ref).

For more information, see the `README`.

```jldoctest
julia> using Justly

julia> edit_song(joinpath(pkgdir(Justly), "test", "test_song_file.yml"); test = true)
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
        from_yamlable(
            Song,
            load_file(song_file);
            keyword_arguments...,
        )
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

    qmlfunction("to_yaml", let song_file = song_file, song = song
        () -> write_file(song_file, to_yamlable(song))
    end)

    loadqml(
        joinpath(@__DIR__, "Song.qml");
        chords_model = my_list_model(
            song.chords,
            (:numerator, :denominator, :octave, :beats, :words, :notes_model),
        ),
        test = test,
    )
    stream = PortAudioStream(0, 1, writer = Weaver(); warn_xruns = false)
    buffer = stream.sink_messanger.buffer
    task_ios = fill_all_task_ios(buffer; number_of_tasks = number_of_tasks)
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
            put!(releases, nothing)
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
