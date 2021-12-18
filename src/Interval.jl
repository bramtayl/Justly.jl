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

# TODO: reuse from AudioSchedules
function from_yamlable(::Type{Interval}, text::AbstractString)
    a_match = match(QUOTIENT, text)
    if a_match === nothing
        throw(Meta.ParseError("Can't parse interval $text"))
    end
    numerator_string = a_match["numerator"]
    denominator_string = a_match["denominator"]
    octave_string = a_match["octave"]
    Interval(
        parse(Int, numerator_string),
        if denominator_string === nothing
            1
        else
            parse(Int, denominator_string)
        end,
        if octave_string === nothing
            0
        else
            parse(Int, octave_string)
        end,
    )
end

function to_yamlable(interval::Interval)
    result = IOBuffer()
    denominator = interval.denominator
    octave = interval.octave
    print(result, interval.numerator)
    if denominator != 1
        print(result, '/')
        print(result, denominator)
    end
    if octave != 0
        print(result, 'o')
        print(result, octave)
    end
    String(take!(result))
end