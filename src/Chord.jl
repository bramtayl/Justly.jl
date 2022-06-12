mutable struct Chord
    interval::Interval
    beats::Int
    volume::Float64
    words::String
    notes::Vector{Note}
    # separate list model for qml
    notes_model::ListModel
    selected::Bool
end

export Chord

function Chord(;
    interval = Interval(),
    beats = 1,
    volume = 1.0,
    words = "",
    notes = Note[],
    notes_model = list_model(notes),
    selected = false
)
    Chord(interval, beats, volume, words, notes, notes_model, selected)
end

precompile(Chord, ())

const CHORD_REGEX = r"(?<modulation>.*): ?(?<notes>.*)"

function parse(::Type{Chord}, text::AbstractString; line_number, words = "")
    a_match = match(CHORD_REGEX, text)
    if a_match === nothing
        throw_parse_error(text, "chord", line_number)
    else
        notes_string = a_match["notes"]
        modulation = parse(Note, a_match["modulation"]; line_number = line_number)
        Chord(
            words = words,
            interval = modulation.interval,
            beats = modulation.beats,
            volume = modulation.volume,
            notes = if notes_string == ""
                Note[]
            else
                map(
                    let line_number = line_number
                        (sub_string -> parse(Note, sub_string; line_number = line_number))
                    end,
                    split(a_match["notes"], ", "),
                )
            end,
        )
    end
end

precompile(parse, (Type{Chord}, SubString))

# TODO: precompile

function print(io::IO, chord::Chord)
    words = chord.words
    if words != ""
        print(io, "# ")
        print(io, words)
        println(io)
    end
    print(io, chord.interval)
    beats = chord.beats
    if beats != 1
        print(io, " for ")
        print(io, beats)
    end
    volume = chord.volume
    if !(volume ≈ 1)
        print(io, " at ")
        print(io, volume)
    end
    print(io, ": ")
    # print commas after the first one
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

precompile(print, (IOStream, Chord))

function list_model(chords::Vector{Chord})
    list_model = ListModel(chords, false)
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
    addrole(list_model, "words",
        item -> item.words,
        (list, new_value, index) -> list[index].words = new_value
    )
    addrole(list_model, "notes_model", item -> item.notes_model)
    addrole(list_model, "selected",
        item -> item.selected,
        (list, new_value, index) -> list[index].selected = new_value
    )
    setconstructor(list_model, Chord)
    list_model
end

precompile(list_model, (Vector{Chord},))