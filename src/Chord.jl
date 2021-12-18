
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
        my_list_model(notes, (:numerator, :denominator, :octave, :beats)),
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

function from_yamlable(::Type{Chord}, dictionary)
    Chord(
        if haskey(dictionary, :words)
            dictionary[:words]
        else
            ""
        end,
        from_yamlable(Note, dictionary[:modulation]),
        if haskey(dictionary, :notes)
            map(
                (sub_dictionary -> from_yamlable(Note, sub_dictionary)),
                dictionary[:notes],
            )
        else
            Note[]
        end,
    )
end

function to_yamlable(chord::Chord)
    result = Dict{Symbol, Any}()
    words = chord.words
    notes = chord.notes
    if words != ""
        result[:words] = words
    end
    result[:modulation] = to_yamlable(chord.modulation)
    if !isempty(notes)
        result[:notes] = map(to_yamlable, notes)
    end
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
