mutable struct Note
    instrument::Instrument
    interval::Interval
    beats::Int
    volume::Float64
end

function Note(instrument; interval = Interval(), beats = 1, volume = 1.0)
    Note(instrument, interval, beats, volume)
end

function as_dict(note::Note)
    Dict(
        "instrument_name" => note.instrument.name,
        "interval" => as_dict(note.interval),
        "beats" => note.beats,
        "volume" => note.volume,
    )
end

function from_dict(::Type{Note}, dict, instruments)
    Note(
        get_instrument(instruments, dict["instrument_name"]);
        interval = from_dict(Interval, dict["interval"]),
        beats = dict["beats"],
        volume = dict["volume"],
    )
end

function make_list_model(notes::Vector{Note}, instruments)
    list_model = ListModel(notes, false)
    # convert ints back and forth to floats for qml
    # direct access to interval fields for qml
    addrole(
        list_model,
        "numerator",
        item -> float(item.interval.numerator),
        (list, new_value, index) -> list[index].interval.numerator = round(Int, new_value),
    )
    addrole(
        list_model,
        "denominator",
        item -> float(item.interval.denominator),
        (list, new_value, index) ->
            list[index].interval.denominator = round(Int, new_value),
    )
    addrole(
        list_model,
        "octave",
        item -> float(item.interval.octave),
        (list, new_value, index) -> list[index].interval.octave = round(Int, new_value),
    )
    addrole(
        list_model,
        "beats",
        item -> float(item.beats),
        (list, new_value, index) -> list[index].beats = round(Int, new_value),
    )
    # add and subtract 1 for zero-based indexing
    addrole(
        list_model,
        "instrument_number",
        let instruments = instruments
            item -> get_instrument_number(instruments, item.instrument) - 1
        end,
        let instruments = instruments
            (list, new_value, index) ->
                list[index].instrument = instruments[round(Int, new_value) + 1]
        end,
    )
    addrole(
        list_model,
        "volume",
        item -> item.volume,
        (list, new_value, index) -> list[index].volume = new_value,
    )
    setconstructor(list_model, let instrument = instruments[1]
        () -> Note(instrument)
    end)
    list_model
end
