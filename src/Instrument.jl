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

"""
    Instrument(note_function!, name)

Use an `Instrument` to play a note in the style of an instrument.

`note_function!` will be called as follows:

    note_function!(audio_schedule, start_time, duration, volume, frequency)

where

- `audio_schedule` is an `AudioSchedules.AudioSchedule` to add the note to.
- `start_time` is a start time in seconds, like `0.0s`.
- `duration` is a duration in seconds, like `1.0s`
- `volume` is a ratio between 0 and 1.
- `frequency` is the frequency of the note in hertz, like `440.0Hz`.
"""
struct Instrument
    note_function!::FunctionWrapper{Nothing, Tuple{INSTRUMENT_ARGUMENT_TYPES...}}
    name::String
end

export Instrument

function make_list_model(instruments::Vector{Instrument})
    list_model = ListModel(instruments, false)
    addrole(list_model, "text", instrument -> instrument.name)
    list_model
end

function get_instrument_number(instruments, instrument)
    instrument_number = findfirst(
        let instrument = instrument
            possible_instrument -> possible_instrument === instrument
        end,
        instruments,
    )
    if instrument_number === nothing
        throw(ArgumentError("Instrument \"$(instrument.instrument_name)\" not found!"))
    else
        instrument_number
    end
end

function get_instrument(instruments, instrument_name)
    instrument_number = findfirst(let instrument_name = instrument_name
        instrument -> instrument.name == instrument_name
    end, instruments)
    if instrument_number === nothing
        throw(ArgumentError("Instrument \"$instrument_name\" not found!"))
    else
        instrument_number
    end
    instruments[instrument_number]
end

"""
    DEFAULT_INSTRUMENTS

The default [`Instrument`]s available in [`read_justly`](@ref) and [`edit_justly`](@ref), namely,

```julia
[Instrument(pulse!, "pulse!"), Instrument(sustain!, "sustain!")]
```

See [`pulse!`](@ref) and [`sustain!`](@ref).
"""
const DEFAULT_INSTRUMENTS = [Instrument(pulse!, "pulse!"), Instrument(sustain!, "sustain!")]

export DEFAULT_INSTRUMENTS
