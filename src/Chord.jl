mutable struct Chord
    words::String
    modulation::Note
    notes::Vector{Note}
    # we need a separate property here for the list model
    notes_model::ListModel
end
export Chord

function Chord(words, modulation, notes)
    Chord(
        words,
        modulation,
        notes,
        property_model(notes, (:numerator, :denominator, :octave, :beats)),
    )
end

function Chord(;
    words = "",
    modulation = Note(),
    # need to allocate a new vector
    notes = Note[],
)
    Chord(words, modulation, notes)
end

const CHORD_REGEX = r"(?<modulation>.*): (?<notes>.*)"

function parse(::Type{Chord}, text::AbstractString; line_number, words = "")
    a_match = match(CHORD_REGEX, text)
    if a_match === nothing
        throw_parse_error(text, "chord", line_number)
    else
        notes_string = a_match["notes"]
        Chord(
            words = words,
            modulation = parse(Note, a_match["modulation"]; line_number = line_number),
            notes = if notes_string == ""
                Note[]
            else
                map(
                    let line_number = line_number
                        (sub_string -> parse(Note, sub_string; line_number = line_number))
                    end,
                    split(a_match["notes"], ", ")
                )
            end
        )
    end
end

function print(io::IO, chord::Chord)
    words = chord.words
    if words != ""
        print(io, "# ")
        print(io, words)
        println(io)
    end
    print(io, chord.modulation)
    print(io, ": ")
    first_one = true
    for note in chord.notes
        if first_one
            first_one = false
        else
            print(io, ", ")
        end
        print(io, note)
    end
    println(io)
end

# TODO: propertynames?

@inline function getproperty(chord::Chord, property_name::Symbol)
    if property_name === :numerator ||
       property_name === :denominator ||
       property_name === :denominator ||
       property_name === :octave ||
       property_name === :beats
        getproperty(chord.modulation, property_name)
    else
        getfield(chord, property_name)
    end
end

@inline function setproperty!(chord::Chord, property_name::Symbol, value)
    if property_name === :numerator ||
       property_name === :denominator ||
       property_name === :octave ||
       property_name === :beats
        setproperty!(chord.modulation, property_name, value)
    else
        setfield!(
            chord,
            property_name,
            convert(fieldtype(typeof(chord), property_name), value),
        )
    end
end
