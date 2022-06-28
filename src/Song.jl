
mutable struct Song
    chords::Vector{Chord}
    # use observables so changes in qml will propagate back
    volume_observable::Observable{Float64}
    frequency_observable::Observable{Float64}
    tempo_observable::Observable{Float64}
    precompiling_observable::Observable{Bool}
    instruments::Dict{String, INSTRUMENT_TYPE}
    instrument_names::Vector{String}
end

function Song(chords;
    volume = 0.2,
    frequency = 200.0,
    tempo = 200.0,
    precompiling = false,
    instruments = DEFAULT_INSTRUMENTS,
    instrument_names = collect(keys(instruments))
)
    Song(
        chords,
        Observable(volume),
        Observable(frequency),
        Observable(tempo),
        Observable(precompiling),
        instruments,
        instrument_names
    )
end

precompile(Song, (Vector{Chord},))

function print(io::IO, song::Song)
    print(io, "Frequency: ")
    print(io, song.frequency_observable[])
    print(io, " Hz")
    println(io)
    print(io, "Volume: ")
    print(io, song.volume_observable[])
    println(io)
    print(io, "Tempo: ")
    print(io, song.tempo_observable[])
    print(io, " bpm")
    println(io)
    for chord in song.chords
        print(io, chord; instrument_names = song.instrument_names)
    end
end

precompile(print, (IOStream, Song))

const WHITESPACE_REGEX = r"^\s*$"
const FREQUENCY_REGEX = r"^Frequency: (.*) Hz$"
const TEMPO_REGEX = r"^Tempo: (.*) bpm$"
const VOLUME_REGEX = r"^Volume: (.*)$"
const WORDS_REGEX = r"^# (.*)$"

function parse(::Type{Song}, io::IO;
    volume = 0.2,
    frequency = 200.0,
    tempo = 200.0,
    instruments = DEFAULT_INSTRUMENTS,
    instrument_names = collect(keys(instruments)),
    keywords...
)
    words = ""
    chords = Chord[]
    for (line_number, line) in enumerate(eachline(io))
        # skip empty lines
        if match(WHITESPACE_REGEX, line) === nothing
            tempo_match = match(TEMPO_REGEX, line)
            if tempo_match !== nothing
                tempo_text = tempo_match[1]
                tempo = tryparse(Float64, tempo_text)
                if tempo === nothing
                    throw_parse_error(tempo_text, "tempo", line_number)
                end
            else
                frequency_match = match(FREQUENCY_REGEX, line)
                if frequency_match !== nothing
                    frequency_text = frequency_match[1]
                    frequency = tryparse(Float64, frequency_text)
                    if frequency === nothing
                        throw_parse_error(frequency_text, "frequency", line_number)
                    end
                else
                    volume_match = match(VOLUME_REGEX, line)
                    if volume_match !== nothing
                        volume_text = volume_match[1]
                        volume = tryparse(Float64, volume_text)
                        if volume === nothing
                            throw_parse_error(line, "volume", line_number)
                        end
                    else
                        words_match = match(WORDS_REGEX, line)
                        if words_match !== nothing
                            words = words_match[1]
                        else
                            push!(chords, parse(Chord, line;
                                words = words,
                                line_number = line_number,
                                instrument_names = instrument_names
                            ))
                            # so we don't reuse words for the next chord
                            words = ""
                        end
                    end
                end
            end
        end
    end
    Song(chords;
        volume = volume,
        tempo = tempo,
        frequency = frequency,
        instruments = instruments,
        instrument_names = instrument_names,
        keywords...
    )
end

precompile(parse, (Type{Song}, IOStream))

"""
    function read_justly(song_file;
        volume = 0.2,
        frequency = 200.0,
        tempo = 200.0,
        wave = SawTooth(7),
        make_envelope = pluck
        
    )

Create a `Song` from a song file.

- `volume` is the starting volume of a single voice, between 0 and 1. Use this if the user doesn't specify a starting volume in the song file. To avoid peaking, lower the volume for songs with many voices.
- `frequency` is the starting frequency, in Hz. Use this if the user doesn't specify a starting frequency in the song file.
- `tempo` is the tempo of the song, in beats per minute. This is the tempo of 1 indivisible beat, so for songs which subdivide notes, you will need to multiply the tempo accordingly.
- `wave` is a function which takes an angle in radians and returns an amplitude between -1 and 1. Use this to change the timbre of the sound. The default is `SawTooth(7)`, a saw-tooth wave with the first 7 fundamental frequencies.
- `make_envelope` is a function which takes a duration in seconds and returns an envelope. The default is [`pluck`](@ref).

```jldoctest read_justly
julia> using Justly

julia> song = read_justly(joinpath(pkgdir(Justly), "examples", "simple.justly"));

julia> print(song)
Frequency: 220.0 Hz
Volume: 0.2
Tempo: 200.0 bpm
# I
1: 1, 5/4 at 2.0, 3/2
# IV
2/3: 3/2, 1o1 at 2.0, 5/4o1
# I
3/2 for 2: 1 for 2, 5/4 for 2 at 2.0, 3/2 for 2
```

You can add a song to an `AudioSchedule`

```jldoctest read_justly
julia> using AudioSchedules: AudioSchedule

julia> audio_schedule = AudioSchedule()
0.0 s 44100.0 Hz AudioSchedule

julia> push!(audio_schedule, song)

julia> audio_schedule
1.27 s 44100.0 Hz AudioSchedule
```

You can convert a song directly to a `SampleBuf`, with a default sample rate
of 44100Hz.

```jldoctest read_justly
julia> using SampledSignals: SampleBuf

julia> SampleBuf(song)
56007-frame, 1-channel SampleBuf{Float64, 1}
1.27s sampled at 44100.0Hz
▅▆▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▆▆▆▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▆▆▆▆▇▇▇▇▇▇▇▇▇▇▇▇▇▇▆▆▆▆▆▆▆▆▆▅▆▆▆▆▆▆▅▅▅▅▅▅▅▄▄▃
```
"""
function read_justly(file; keywords...)
    open(
        let keywords = keywords
            io -> parse(Song, io; keywords...) 
        end,
        file
    )
end

precompile(read_justly, (String,))

function push!(audio_schedule::AudioSchedule, song::Song, time = 0.0s; from_chord = 1)
    float_time = float(time)
    volume = song.volume_observable[]
    frequency = (song.frequency_observable[])Hz
    beat_duration = (60 / song.tempo_observable[])s
    instruments = song.instruments
    instrument_names = song.instrument_names
    for (index, chord) in enumerate(song.chords)
        frequency = frequency * Rational(chord.modulation.interval)
        volume = volume * chord.modulation.volume
        if index >= from_chord
            for note in chord.notes
                instruments[instrument_names[note.instrument_number]](
                    audio_schedule,
                    float_time,
                    note.beats * beat_duration,
                    volume * note.volume,
                    frequency * Rational(note.interval)
                )
            end
            float_time = float_time + chord.modulation.beats * beat_duration
        end
    end
    nothing
end

precompile(push!, (AudioSchedule, Song, FLOAT_SECONDS))

function SampleBuf(song::Song; sample_rate = 44100Hz)
    audio_schedule = AudioSchedule(; sample_rate = sample_rate)
    push!(audio_schedule, song)
    SampleBuf(audio_schedule)
end

export read_justly
