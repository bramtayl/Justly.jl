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
    interval.numerator // interval.denominator * (2 // 1)^interval.octave
end

precompile(Rational, (Interval,))

function as_dict(interval::Interval)
    Dict(
        "numerator" => interval.numerator,
        "denominator" => interval.denominator,
        "octave" => interval.octave,
    )
end

precompile(as_dict, (Interval,))

function from_dict(::Type{Interval}, dict)
    Interval(
        numerator = dict["numerator"],
        denominator = dict["denominator"],
        octave = dict["octave"],
    )
end

precompile(from_dict, (Type{Interval}, Dict{String, Int}))
