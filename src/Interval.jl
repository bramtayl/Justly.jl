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

function as_dict(interval::Interval)
    Dict(
        "numerator" => interval.numerator,
        "denominator" => interval.denominator,
        "octave" => interval.octave,
    )
end

function from_dict(::Type{Interval}, dict)
    Interval(
        numerator = dict["numerator"],
        denominator = dict["denominator"],
        octave = dict["octave"],
    )
end
