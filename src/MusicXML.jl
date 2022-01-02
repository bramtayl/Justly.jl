const NOTE_NAMES =
    ("C", "C♯/D♭", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B")

const SHARPS = (
    ("C", "0"),
    ("C", "1"),
    ("D", "0"),
    ("D", "1"),
    ("E", "0"),
    ("F", "0"),
    ("F", "1"),
    ("G", "0"),
    ("G", "1"),
    ("A", "0"),
    ("A", "1"),
    ("B", "0"),
)

const FLATS = (
    ("C", "0"),
    ("D", "-1"),
    ("D", "0"),
    ("E", "-1"),
    ("E", "0"),
    ("F", "0"),
    ("G", "-1"),
    ("G", "0"),
    ("A", "-1"),
    ("A", "0"),
    ("B", "-1"),
    ("B", "0"),
)

const A440_MIDI_CODE = 69
const C0_MIDI_CODE = 12

function get_nearest_midi_code(frequency)
    A440_MIDI_CODE + round(Int, 12 * log(frequency / 440Hz) / log(2))
end

function get_note_parts(midi_code)
    fldmod(round(Int, midi_code) - C0_MIDI_CODE, 12)
end

function round_nearest_midi(frequency)
    get_frequency(get_nearest_midi_code(frequency))
end

function get_frequency(midi_code)
    2.0^((midi_code - A440_MIDI_CODE) / 12) * 440Hz
end

const NOTE_TYPES = (
    "maxima",
    "long",
    "breve",
    "whole",
    "half",
    "quarter",
    "eighth",
    "16th",
    "32nd",
    "64th",
    "128th",
    "256th",
    "512th",
    "1024th",
)

function skip!(measure, direction, beats)
    add_text(new_child(new_child(measure, direction), "duration"), string(beats))
end

function skip!(measure, beats)
    if beats > 0
        skip!(measure, "forward", beats)
    elseif beats < 0
        skip!(measure, "backup", -beats)
    end
end

function new_measure!(part, index)
    measure = new_child(part, "measure")
    set_attribute(measure, "number", string(index))
    measure
end

function maybe_new_measure!(part, measures, index)
    if index == length(measures) + 1
        measure = new_measure!(part, index)
        push!(measures, measure)
        measure
    else
        measures[index]
    end
end

function make_notations!(xml_note)
    new_child(xml_note, "notations")
end

function tie!(xml_note, start_or_stop)
    set_attribute(new_child(xml_note, "tie"), "type", start_or_stop)
    maybe_notations = find_element(xml_note, "notations")
    set_attribute(
        new_child(if maybe_notations === nothing
            new_child(xml_note, "notations")
        else
            maybe_notations
        end, "tied"),
        "type",
        start_or_stop,
    )
end

struct ParsedPitch
    staff::String
    step::String
    alter::String
    octave::String
end

function ParsedPitch(scale, frequency)
    midi_code = get_nearest_midi_code(frequency)
    octave, degree = get_note_parts(midi_code)
    step, alter = scale[degree + 1]
    # middle C
    staff = if midi_code >= 60
        "1"
    else
        "2"
    end
    ParsedPitch(staff, step, alter, string(octave))
end

function add_sub_note!(
    measure,
    beat_type_offset,
    parsed_pitch,
    beat_type_index;
    dotted = false,
)
    xml_note = new_child(measure, "note")
    xml_pitch = new_child(xml_note, "pitch")
    add_text(new_child(xml_pitch, "step"), parsed_pitch.step)
    add_text(new_child(xml_pitch, "alter"), parsed_pitch.alter)
    add_text(new_child(xml_pitch, "octave"), parsed_pitch.octave)
    add_text(
        new_child(xml_note, "duration"),
        string(Int(if dotted
            1.5
        else
            1.0
        end * 2.0^(beat_type_offset - 1))),
    )
    add_text(
        new_child(xml_note, "type"),
        NOTE_TYPES[beat_type_index - (beat_type_offset - 1)],
    )
    if dotted
        new_child(xml_note, "dot")
    end
    add_text(new_child(xml_note, "staff"), parsed_pitch.staff)
    xml_note
end

function add_measure_note!(
    measure,
    beat_type_index,
    parsed_pitch,
    beats;
    end_previous_tie = false,
    start_new_tie = false,
)
    # TODO: avoid allocations
    duration_offsets = map(
        first,
        Iterators.filter(((_, digit),) -> Bool(digit), enumerate(digits(beats; base = 2))),
    )
    if length(duration_offsets) == 2 && duration_offsets[1] + 1 == duration_offsets[2]
        xml_note = add_sub_note!(
            measure,
            duration_offsets[2],
            parsed_pitch,
            beat_type_index;
            dotted = true,
        )
        if end_previous_tie
            tie!(xml_note, "stop")
        end
        if start_new_tie
            tie!(xml_note, "start")
        end
    else
        number_of_sub_notes = length(duration_offsets)
        for (sub_index, beat_type_offset) in enumerate(duration_offsets)
            xml_note =
                add_sub_note!(measure, beat_type_offset, parsed_pitch, beat_type_index)
            if end_previous_tie || sub_index != 1
                tie!(xml_note, "stop")
            end
            if start_new_tie || sub_index != number_of_sub_notes
                tie!(xml_note, "start")
            end
        end
    end
    skip!(measure, -beats)
end

function split_measures(beats_per_measure, chord_from_beat, beats)
    beginning = beats_per_measure - chord_from_beat
    middle_measures, ending = fldmod(beats - beginning, beats_per_measure)
    beginning, middle_measures, ending
end

function add_whole_note!(
    part,
    measures,
    measure_index,
    key,
    scale,
    note,
    beats_per_measure,
    chord_from_beat,
    beat_type_index,
)
    parsed_pitch = ParsedPitch(scale, key * Rational(note.interval))
    note_beats = note.beats
    destination = chord_from_beat + note_beats
    if destination > beats_per_measure
        # TODO: avoid allocations
        beginning, middle_measures, ending =
            split_measures(beats_per_measure, chord_from_beat, note_beats)
        measure_index_beats =
            map((index -> (index, beats_per_measure)), (measure_index + 1):(measure_index + middle_measures))
        if beginning > 0
            pushfirst!(measure_index_beats, (measure_index, beginning))
        end
        if ending > 0
            push!(measure_index_beats, (measure_index + middle_measures + 1, ending))
        end
        number_of_note_measures = length(measure_index_beats)
        for (sub_index, (measure_index, beats)) in enumerate(measure_index_beats)
            add_measure_note!(
                maybe_new_measure!(part, measures, measure_index),
                beat_type_index,
                parsed_pitch,
                beats;
                end_previous_tie = sub_index != 1,
                start_new_tie = sub_index != number_of_note_measures,
            )
        end
    else
        add_measure_note!(
            measures[measure_index],
            beat_type_index,
            parsed_pitch,
            note_beats,
        )
    end
end

function add_chord!(
    part,
    measures,
    key,
    scale,
    chord,
    measure_index,
    beats_per_measure,
    beat_type_index,
    chord_from_beat,
)
    key = round_nearest_midi(Rational(chord.modulation.interval) * key)
    for note in chord.notes
        add_whole_note!(
            part,
            measures,
            measure_index,
            key,
            scale,
            note,
            beats_per_measure,
            chord_from_beat,
            beat_type_index,
        )
    end
    chord_beats = chord.beats
    if chord_beats > 0
        destination = chord_from_beat + chord_beats
        if destination > beats_per_measure
            beginning, middle_measures, ending =
                split_measures(beats_per_measure, chord_from_beat, chord_beats)
            if beginning > 0
                skip!(measures[measure_index], beginning)
            end
            for middle_index in 1:middle_measures
                measure_index = measure_index + middle_index
                skip!(maybe_new_measure!(part, measures, measure_index), beats_per_measure)
            end
            if ending > 0
                measure_index = measure_index + middle_measures + 1
                skip!(maybe_new_measure!(part, measures, measure_index), ending)
                chord_from_beat = ending
                measure_index = measure_index
            else
                chord_from_beat = beats_per_measure
                measure_index = measure_index + middle_measures
            end
        else
            skip!(measures[measure_index], chord_beats)
            chord_from_beat = chord_from_beat + chord_beats
        end
    elseif chord_beats < 0
        if chord_beats < -chord_from_beat
            throw(
                ErrorException(
                    "Skipping chord backwards into a previous measure is not unsupported",
                ),
            )
        end
        skip!(chord_measure, chord_beats)
        chord_from_beat = chord_from_beat + chord_beats
    end
    key, measure_index, chord_from_beat
end

"""
    make_music_xml(
        song;
        key_fifths = 0,
        beats_per_quarter_note = 1,
        time_signature_numerator = 4,
        time_signature_denominator = 4,
    )

Make a music xml file from a song. You can save it to a new file with
LightXML.save_file.

```jldoctest
julia> using Justly

julia> using LightXML: save_file

julia> cd(joinpath(pkgdir(Justly), "test"))

julia> song = read_justly("song.justly");

julia> xml_song = make_music_xml(song);

julia> save_file(xml_song, "test_song.xml");

julia> read("test_song.xml", String) == read("song.xml", String)
true

julia> rm("test_song.xml")
```
"""
function make_music_xml(
    song;
    key_fifths = 0,
    beats_per_quarter_note = 1,
    time_signature_numerator = 4,
    time_signature_denominator = 4,
)
    beats_per_measure =
        Int(4 * time_signature_numerator / time_signature_denominator * beats_per_quarter_note)
    scale = if key_fifths >= 0
        SHARPS
    else
        FLATS
    end

    beat_type_index = 6 + Int(log2(beats_per_quarter_note))

    part_id = "P1"
    score = XMLDocument()
    score_partwise = create_root(score, "score-partwise")
    set_attribute(score_partwise, "version", "4.0")
    part_list = new_child(score_partwise, "part-list")
    first_part = new_child(part_list, "score-part")
    set_attribute(first_part, "id", part_id)
    add_text(new_child(first_part, "part-name"), "Part 1")
    part = new_child(score_partwise, "part")
    set_attribute(part, "id", part_id)
    measure_index = 1
    first_measure = new_measure!(part, measure_index)
    measures = [first_measure]
    attributes = new_child(first_measure, "attributes")
    add_text(new_child(attributes, "divisions"), string(beats_per_quarter_note))
    add_text(new_child(new_child(attributes, "key"), "fifths"), string(key_fifths))
    time_signature = new_child(attributes, "time")
    add_text(new_child(time_signature, "beats"), string(time_signature_numerator))
    add_text(new_child(time_signature, "beat-type"), string(time_signature_denominator))
    add_text(new_child(attributes, "staves"), "2")
    treble_clef = new_child(attributes, "clef")
    set_attribute(treble_clef, "number", "1")
    add_text(new_child(treble_clef, "sign"), "G")
    add_text(new_child(treble_clef, "line"), "2")
    bass_clef = new_child(attributes, "clef")
    set_attribute(bass_clef, "number", "2")
    add_text(new_child(bass_clef, "sign"), "F")
    add_text(new_child(bass_clef, "line"), "4")

    chord_from_beat = 0
    key = round_nearest_midi(song.initial_key)
    for chord in song.chords
        key, measure_index, chord_from_beat = add_chord!(
            part,
            measures,
            key,
            scale,
            chord,
            measure_index,
            beats_per_measure,
            beat_type_index,
            chord_from_beat,
        )
    end

    score
end
export make_music_xml
