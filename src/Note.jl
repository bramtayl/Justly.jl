
mutable struct Note
    interval::Interval
    beats::Int
    volume::Float64
end

function Note(; interval = Interval(), beats = 1, volume = 20.0)
    # convert strings and rationals to intervals first
    Note(interval, beats, volume)
end

const NOTE_REGEX = r"(?<interval>.*) for (?<beats>.*) at (?<volume>.*)%"

function parse(::Type{Note}, text::AbstractString; line_number = line_number)
    a_match = match(NOTE_REGEX, text)
    if a_match === nothing
        throw_parse_error(text, "note", line_number)
    else
        beats_string = a_match["beats"]
        beats = tryparse(Int, beats_string)
        volume_string = a_match["volume"]
        volume = tryparse(Float64, volume_string)
        if beats === nothing
            throw_parse_error(beats_string, "beats", line_number)
        elseif volume == nothing
            throw_parse_error(volume_string, "volume", line_number)
        else
            Note(parse(Interval, a_match["interval"]; line_number = line_number), beats, volume)
        end
    end
end

function print(io::IO, note::Note)
    print(io, note.interval)
    print(io, " for ")
    print(io, note.beats)
    print(io, " at ")
    print(io, note.volume)
    print(io, '%')
end

# TODO: propertynames?

@inline function getproperty(note::Note, property_name::Symbol)
    if property_name === :numerator ||
       property_name === :denominator ||
       property_name === :octave
        getproperty(note.interval, property_name)
    else
        getfield(note, property_name)
    end
end

@inline function setproperty!(note::Note, property_name::Symbol, value)
    if property_name === :numerator ||
       property_name === :denominator ||
       property_name === :octave
        setproperty!(note.interval, property_name, value)
    else
        setfield!(
            note,
            property_name,
            convert(fieldtype(typeof(note), property_name), value),
        )
    end
end
