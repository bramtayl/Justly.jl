
"""
mutable struct Chord

A Julia representation of a chord. Pass a vector of `Chord`s to [`edit_song`](@ref).
"""
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

const MODULATION_NOTES_REGEX = r"(?<modulation>.*)\: (?<notes>.*)"

function from_yamlable(::Type{Chord}, dictionary)
    modulation = only(Iterators.filter(x -> x != "words", keys(dictionary)))
    Chord(
        if haskey(dictionary, "words")
            dictionary["words"]
        else
            ""
        end,
        from_yamlable(Note, modulation),
        map(
            (sub_string -> from_yamlable(Note, sub_string)),
            split(dictionary[modulation], ", ")
        )
    )
end

function to_yamlable(chord::Chord)
    result = Dict{String, Any}()
    words = chord.words
    notes = chord.notes
    if words != ""
        result["words"] = words
    end
    notes_text = IOBuffer()
    first_one = true
    for note in notes
        if first_one
            first_one = false
        else
            print(notes_text, ", ")
        end
        to_yamlable(notes_text, note)
    end
    result[to_yamlable(chord.modulation)] = String(take!(notes_text))
    result
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
