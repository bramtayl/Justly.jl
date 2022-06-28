mutable struct Modulation
    interval::Interval
    beats::Int
    volume::Float64
end

function Modulation(;
    interval = Interval(),
    beats = 1,
    volume = 1
)
    Modulation(interval, beats, volume)
end

precompile(Modulation, ())

const MODULATION_REGEX = r"(?<interval>[^ ]*)(?: for (?<beats>[^ ]*))?(?: at (?<volume>[^ ]*))?"

function parse(::Type{Modulation}, text::AbstractString; line_number)
    a_match = match(MODULATION_REGEX, text)
    if a_match === nothing
        throw_parse_error(text, "note", line_number)
    else
        beats_string = a_match["beats"]
        beats =
            if beats_string === nothing
                1
            else
                tryparse(Int, beats_string)
            end
        if beats === nothing
            throw_parse_error(beats_string, "beats", line_number)
        end

        volume_string = a_match["volume"]
        volume = 
            if volume_string === nothing
                1.0
            else
                tryparse(Float64, volume_string)
            end
        if volume === nothing
            throw_parse_error(volume_string, "volume", line_number)
        end

        Modulation(;
            interval = parse(Interval, a_match["interval"];
                line_number = line_number
            ),
            beats = beats, 
            volume = volume
        )
    end
end

precompile(parse, (Type{Modulation}, SubString))

function print(io::IO, note::Modulation)
    print(io, note.interval)
    beats = note.beats
    if !(beats == 1)
        print(io, " for ")
        print(io, note.beats)
    end
    volume = note.volume
    if !(volume ≈ 1)
        print(io, " at ")
        print(io, volume)
    end
end

precompile(print, (IOStream, Modulation))
