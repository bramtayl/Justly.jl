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
