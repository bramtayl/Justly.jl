mutable struct Interval
    numerator::Int
    denominator::Int
    octave::Int
end

function Interval(; numerator = 1, denominator = 1, octave = 0)
    Interval(numerator, denominator, octave)
end

precompile(Interval, ())

function Rational(interval::Interval)
    interval.numerator // interval.denominator * (2 // 1) ^ interval.octave
end

precompile(Rational, (Interval,))


const INTERVAL_REGEX = r"(?<numerator>[^/o]+)(?:/(?<denominator>[^o]+))?(?:o(?<octave>.+))?"

# TODO: reuse from AudioSchedules
function parse(::Type{Interval}, text::AbstractString; line_number)
    a_match = match(INTERVAL_REGEX, text)
    if a_match === nothing
        throw_parse_error(text, "interval", line_number)
    else
        numerator_string = a_match["numerator"]
        numerator = tryparse(Int, numerator_string)
        denominator_string = a_match["denominator"]
        octave_string = a_match["octave"]
        Interval(
            if numerator === nothing
                throw_parse_error(numerator_string, "numerator", line_number)
            else
                numerator
            end,
            # default to 1
            if denominator_string === nothing
                1
            else
                denominator = tryparse(Int, denominator_string)
                if denominator === nothing
                    throw_parse_error(denominator_string, "denominator", line_number)
                else
                    denominator
                end
            end,
            # default to 0
            if octave_string === nothing
                0
            else
                octave = tryparse(Int, octave_string)
                if octave === nothing
                    throw_parse_error(octave_string, "octave", line_number)
                else
                    octave
                end
            end,
        )
    end
end

precompile(parse, (Type{Interval}, SubString))

function print(io::IO, interval::Interval)
    denominator = interval.denominator
    octave = interval.octave
    print(io, interval.numerator)
    # don't print denoinator if it's 1
    if denominator != 1
        print(io, '/')
        print(io, denominator)
    end
    # don't print octave if it's 1
    if octave != 0
        print(io, 'o')
        print(io, octave)
    end
end

precompile(print, (IOStream, Interval))