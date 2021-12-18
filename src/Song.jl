
mutable struct Song{Wave, MakeEnvelope}
    wave::Wave
    make_envelope::MakeEnvelope
    beat_duration::TIME
    initial_key::FREQUENCY
    ramp::TIME
    sample_rate::FREQUENCY
    volume::Float64
    chords::Vector{Chord}
end

const DEFAULT_WAVE = SawTooth(7)
const DEFAULT_MAKE_ENVELOPE = pedal
const DEFAULT_BEAT_DURATION = 0.3s
const DEFAULT_RAMP = 0.1s
const DEFAULT_SAMPLE_RATE = 44100.0Hz
const DEFAULT_VOLUME = 0.1

function Song(;
    wave = DEFAULT_WAVE,
    make_envelope = DEFAULT_MAKE_ENVELOPE,
    beat_duration = 0.3s,
    initial_key = 220.0Hz,
    ramp = DEFAULT_RAMP,
    sample_rate = DEFAULT_SAMPLE_RATE,
    volume = DEFAULT_VOLUME,
    # need to allocate a new vector
    chords = Chord[],
)
    Song(wave, make_envelope, beat_duration, initial_key, ramp, sample_rate, volume, chords)
end

function to_yamlable(song::Song)
    result = Dict{Symbol, Any}()
    result[:beat_duration] = song.beat_duration
    result[:initial_key] = song.initial_key
    result[:chords] = map(to_yamlable, song.chords)
    result
end

function parse_unit(a_string, unit)
    parse(Float64, match(Regex("(.*) $unit"), a_string)[1])unit
end

function from_yamlable(
    ::Type{Song},
    dictionary;
    keyword_arguments...
)
    Song(;
        beat_duration = parse_unit(dictionary[:beat_duration], s),
        initial_key = parse_unit(dictionary[:initial_key], Hz),
        chords = map(sub_dictionary -> from_yamlable(Chord, sub_dictionary), dictionary[:chords]),
        keyword_arguments...
    )
end

function update_beats_per_minute!(song, beats_per_minute)
    song.beat_duration = (60 / beats_per_minute)s
    nothing
end

function update_initial_midi_code!(song, midi_code)
    song.initial_key = 2.0^((midi_code - 69) / 12) * 440Hz
    nothing
end

function get_beats_per_minute(song)
    60s / song.beat_duration
end

function get_initial_midi_code(song)
    69 + 12 * log(song.initial_key / 440Hz) / log(2)
end
