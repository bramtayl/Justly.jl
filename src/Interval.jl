# we could just store intervals as a rational number
# but there's more than one way to represent a given rational
# so we don't want to lose user information
mutable struct Interval
    numerator::Int
    denominator::Int
    octave::Int
end

function Interval(; numerator = 1, denominator = 1, octave = 0)
    Interval(numerator, denominator, octave)
end

function Rational(interval::Interval)
    interval.numerator // interval.denominator * (2 // 1)^interval.octave
end

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

function print(io::IO, interval::Interval)
    denominator = interval.denominator
    octave = interval.octave
    print(io, interval.numerator)
    if denominator != 1
        print(io, '/')
        print(io, denominator)
    end
    if octave != 0
        print(io, 'o')
        print(io, octave)
    end
end
