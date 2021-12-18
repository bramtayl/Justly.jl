mutable struct Note
    interval::Interval
    beats::Int
end

function Note(; interval = Interval(), beats = 1)
    # convert strings and rationals to intervals first
    Note(interval, beats)
end

const NOTE_REGEX = r"(?<interval>.*) for (?<beats>.*)"

function from_yamlable(::Type{Note}, note_string::AbstractString)
    a_match = match(NOTE_REGEX, note_string)
    Note(from_yamlable(Interval, a_match["interval"]), parse(Int, a_match["beats"]))
end

function to_yamlable(io, note::Note)
    to_yamlable(io, note.interval)
    print(io, " for ")
    print(io, note.beats)
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
