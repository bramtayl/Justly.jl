mutable struct Note
    interval::Interval
    beats::Int
    volume::Float64
    # using numbers not names is more convenient with QML
    instrument_number::Int
end

function Note(;
    interval = Interval(),
    beats = 1,
    volume = 1,
    instrument_number = 1
)
    Note(interval, beats, volume, instrument_number)
end

const NOTE_REGEX = r"(?<interval>[^ ]*)(?: for (?<beats>[^ ]*))?(?: at (?<volume>[^ ]*))? with (?<instrumentname>[^ ]*)"

function parse(::Type{Note}, text::AbstractString; line_number, instrument_names)
    a_match = match(NOTE_REGEX, text)
    if a_match === nothing
        throw_parse_error(text, "note", line_number)
    else
        beats_string = a_match["beats"]
        beats =
            if beats_string === nothing
                1
            else
                tryparse(Int, beats_string)
            end
        if beats === nothing
            throw_parse_error(beats_string, "beats", line_number)
        end

        volume_string = a_match["volume"]
        volume = 
            if volume_string === nothing
                1.0
            else
                tryparse(Float64, volume_string)
            end
        if volume === nothing
            throw_parse_error(volume_string, "volume", line_number)
        end

        Note(;
            interval = parse(Interval, a_match["interval"];
                line_number = line_number
            ),
            beats = beats, 
            volume = volume,
            instrument_number = findfirst(
                let instrument_name = a_match["instrumentname"]
                    name -> name == instrument_name
                end,
                instrument_names
            )
        )
    end
end

precompile(parse, (Type{Note}, SubString))

function print(io::IO, note::Note; instrument_names)
    print(io, note.interval)
    beats = note.beats
    if !(beats == 1)
        print(io, " for ")
        print(io, note.beats)
    end
    volume = note.volume
    if !(volume ≈ 1)
        print(io, " at ")
        print(io, volume)
    end
    print(io, " with ")
    print(io, instrument_names[note.instrument_number])
end

precompile(print, (IOStream, Note))

function list_model(notes::Vector{Note})
    list_model = ListModel(notes, false)
    # convert ints back and forth to floats for qml
    # direct access to interval fields for qml
    addrole(list_model, "numerator",
        item -> float(item.interval.numerator),
        (list, new_value, index) -> 
            list[index].interval.numerator = round(Int, new_value)
    )
    addrole(list_model, "denominator",
        item -> float(item.interval.denominator),
        (list, new_value, index) -> 
            list[index].interval.denominator = round(Int, new_value)
    )
    addrole(list_model, "octave",
        item -> float(item.interval.octave),
        (list, new_value, index) -> 
            list[index].interval.octave = round(Int, new_value)
    )
    addrole(list_model, "beats",
        item -> float(item.beats),
        (list, new_value, index) -> 
            list[index].beats = round(Int, new_value)
    )
    # add and subtract 1 for zero-based indexing
    addrole(list_model, "instrument_number",
        item -> float(item.instrument_number) - 1,
        (list, new_value, index) -> 
            list[index].instrument_number = round(Int, new_value) + 1
    )
    addrole(list_model, "volume",
        item -> item.volume,
        (list, new_value, index) -> list[index].volume = new_value
    )
    setconstructor(list_model, Note)
    list_model
end

precompile(list_model, (Vector{Note},))