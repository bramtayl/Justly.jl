mutable struct Note
    interval::Interval
    beats::Int
    volume::Float64
end

function Note(;
    interval = Interval(),
    beats = 1,
    volume = 1
)
    Note(interval, beats, volume)
end

precompile(Note, ())

const NOTE_REGEX = r"(?<interval>[^ ]*)(?: for (?<beats>[^ ]*))?(?: at (?<volume>[^ ]*))?"

function parse(::Type{Note}, text::AbstractString; line_number = line_number)
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
        volume_string = a_match["volume"]
        # default to 1.0
        volume = 
            if volume_string === nothing
                1.0
            else
                tryparse(Float64, volume_string)
            end
        if beats === nothing
            throw_parse_error(beats_string, "beats", line_number)
        elseif volume === nothing
            throw_parse_error(volume_string, "volume", line_number)
        else
            Note(;
                interval = parse(Interval, a_match["interval"];
                    line_number = line_number
                ),
                beats = beats, 
                volume = volume
            )
        end
    end
end

precompile(parse, (Type{Note}, SubString))

function print(io::IO, note::Note)
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
    addrole(list_model, "volume",
        item -> item.volume,
        (list, new_value, index) -> list[index].volume = new_value
    )
    setconstructor(list_model, Note)
    list_model
end

precompile(list_model, (Vector{Note},))