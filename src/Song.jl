
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
    volume = 0.1,
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

julia> song = read_justly(joinpath(pkgdir(Justly), "test", "test_song_file.justly"));

julia> print(song)
220.0 Hz; 800.0 bpm
first chord # 1 for 1: 1 for 1, 3/2 for 10
```

You can create an `AudioSchedule` from a song.

```jldoctest read_justly
julia> using AudioSchedules: AudioSchedule

julia> AudioSchedule(song)
0.8 s 44100.0 Hz AudioSchedule
```
"""
function read_justly(file; keyword_arguments...)
    song = Song(; keyword_arguments...)
    chords = song.chords
    open(file) do io
        first_one = true
        for line in eachline(io)
            if first_one
                a_match = match(INTRO_REGEX, line)
                song.initial_key = parse(Float64, a_match["initial_key"])Hz
                song.beat_duration = 60s / parse(Float64, a_match["tempo"])
                first_one = false
            else
                push!(chords, parse(Chord, line))
            end
        end
    end
    song
end

export read_justly

function update_beats_per_minute!(song::Song, beats_per_minute)
    song.beat_duration = (60 / beats_per_minute)s
    nothing
end

function update_initial_midi_code!(song::Song, midi_code)
    song.initial_key = 2.0^((midi_code - 69) / 12) * 440Hz
    nothing
end

function get_beats_per_minute(song::Song)
    60s / song.beat_duration
end

function get_initial_midi_code(song::Song)
    69 + 12 * log(song.initial_key / 440Hz) / log(2)
end
