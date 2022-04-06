
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

function Song(;
    wave = SawTooth(7),
    make_envelope = pedal,
    beat_duration = 0.3s,
    initial_key = 220.0Hz,
    ramp = 0.1s,
    sample_rate = 44100.0Hz,
    volume = 0.2,
    # need to allocate a new vector
    chords = Chord[],
)
    Song(wave, make_envelope, beat_duration, initial_key, ramp, sample_rate, volume, chords)
end

function print(io::IO, song::Song)
    print(io, song.initial_key)
    print(io, "; ")
    print(io, 60s / song.beat_duration)
    print(io, " bpm")
    println(io)
    for chord in song.chords
        print(io, chord)
    end
end

const INTRO_REGEX = r"(?<initial_key>.*) Hz; (?<tempo>.*) bpm"
const WORDS_REGEX = r"# (?<words>.*)"

function add_initial_key_and_tempo!(song, line_number, line)
    a_match = match(INTRO_REGEX, line)
    if a_match === nothing
        throw_parse_error(line, "initial key and tempo", line_number)
    else
        initial_key_text = a_match["initial_key"]
        initial_key = tryparse(Float64, initial_key_text)
        if initial_key === nothing
            throw_parse_error(initial_key_text, "initial key", line_number)
        else
            song.initial_key = (initial_key)Hz
        end
        tempo_text = a_match["tempo"]
        tempo = tryparse(Float64, tempo_text)
        if tempo === nothing
            throw_parse_error(tempo_text, "tempo", line_number)
        else
            song.beat_duration = 60s / tempo
        end
    end
    nothing
end

function read_justly!(io, song)
    chords = song.chords
    first_one = true
    words = ""
    for (line_number, line) in enumerate(eachline(io))
        if !isempty(line)
            if first_one
                add_initial_key_and_tempo!(song, line_number, line)
                first_one = false
            else
                words_match = match(WORDS_REGEX, line)
                if words_match === nothing
                    push!(
                        chords,
                        parse(Chord, line; line_number = line_number, words = words),
                    )
                    words = ""
                else
                    words = words_match["words"]
                end
            end
        end
    end
end

"""
    function read_justly(song_file;
        wave = SawTooth(7),
        make_envelope = pedal,
        ramp = 0.1s,
        sample_rate = 44100.0Hz,
        volume = 0.1
    )

Create a `Song` from a song file.

- `make_envelope` is a function to make an envelope, like [`pedal`](@ref).
- `ramp` is the onset/offset time, in time units (like `s`).
- `sample_rate` is the sample rate, in frequency units (like `Hz`).
- `volume`, ranging from 0-1, is the volume that a single voice is played at.
- `wave` is a function which takes an angle in radians and returns an amplitude between -1 and 1.

```jldoctest read_justly
julia> using Justly

julia> song = read_justly(joinpath(pkgdir(Justly), "test", "song.justly"));

julia> print(song)
220.0 Hz; 800.0 bpm
# first chord
1 for 5 at 20.0%: 1 for 1 at 20.0%, 1 for 3 at 20.0%, 5/4 for 5 at 20.0%, 3/2 for 8 at 20.0%
1 for 14 at 20.0%: 5/4o1 for 14 at 20.0%
1 for -1 at 20.0%: 1 for 1 at 20.0%
```

You can create an `AudioSchedule` from a song.

```jldoctest read_justly
julia> using AudioSchedules: AudioSchedule

julia> AudioSchedule(song)
1.55 s 44100.0 Hz AudioSchedule
```
"""
function read_justly(file; keyword_arguments...)
    song = Song(; keyword_arguments...)
    open(let song = song
        io -> read_justly!(io, song)
    end, file)
    song
end

export read_justly

function update_beats_per_minute!(song::Song, beats_per_minute)
    song.beat_duration = (60 / beats_per_minute)s
    nothing
end

function update_initial_midi_code!(song::Song, midi_code)
    song.initial_key = get_frequency(midi_code)
    nothing
end

function get_beats_per_minute(song::Song)
    60s / song.beat_duration
end

function get_initial_midi_code(song::Song)
    get_midi_code(song.initial_key)
end
