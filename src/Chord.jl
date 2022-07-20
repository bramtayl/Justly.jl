mutable struct Chord
    modulation::Modulation
    words::String
    notes::Vector{Note}
    # separate list model for qml
    notes_model::ListModel
    note_cursor::Int
end

export Chord

function Chord(
    instruments;
    modulation = Modulation(),
    words = "",
    notes = Note[],
    note_cursor = 0
)
    Chord(modulation, words, notes, make_list_model(notes, instruments), note_cursor)
end

function as_dict(chord::Chord)
    Dict(
        "modulation" => as_dict(chord.modulation),
        "words" => chord.words,
        "notes" => map(as_dict, chord.notes),
    )
end

function from_dict(::Type{Chord}, dict, instruments)
    Chord(
        instruments;
        modulation = from_dict(Modulation, dict["modulation"]),
        words = dict["words"],
        notes = map(dict["notes"]) do dict
            from_dict(Note, dict, instruments)
        end,
    )
end

function make_list_model(chords::Vector{Chord}, instruments)
    list_model = ListModel(chords, false)
    # convert ints back and forth to floats for qml
    # direct access to interval fields for qml
    addrole(
        list_model,
        "numerator",
        item -> float(item.modulation.interval.numerator),
        (list, new_value, index) ->
            list[index].modulation.interval.numerator = round(Int, new_value),
    )
    addrole(
        list_model,
        "denominator",
        item -> float(item.modulation.interval.denominator),
        (list, new_value, index) ->
            list[index].modulation.interval.denominator = round(Int, new_value),
    )
    addrole(
        list_model,
        "octave",
        item -> float(item.modulation.interval.octave),
        (list, new_value, index) ->
            list[index].modulation.interval.octave = round(Int, new_value),
    )
    addrole(
        list_model,
        "beats",
        item -> float(item.modulation.beats),
        (list, new_value, index) -> list[index].modulation.beats = round(Int, new_value),
    )
    addrole(
        list_model,
        "note_cursor",
        item -> float(item.note_cursor),
        (list, new_value, index) -> list[index].note_cursor = round(Int, new_value),
    )
    addrole(
        list_model,
        "volume",
        item -> item.modulation.volume,
        (list, new_value, index) -> list[index].modulation.volume = new_value,
    )
    addrole(
        list_model,
        "words",
        item -> item.words,
        (list, new_value, index) -> list[index].words = new_value,
    )
    addrole(list_model, "notes_model", item -> item.notes_model)
    setconstructor(list_model, let instruments = instruments
        () -> Chord(instruments)
    end)
    list_model
end
