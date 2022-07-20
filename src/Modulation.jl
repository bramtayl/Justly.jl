mutable struct Modulation
    interval::Interval
    beats::Int
    volume::Float64
end

function Modulation(; interval = Interval(), beats = 1, volume = 1)
    Modulation(interval, beats, volume)
end

function as_dict(modulation::Modulation)
    Dict(
        "interval" => as_dict(modulation.interval),
        "beats" => modulation.beats,
        "volume" => modulation.volume,
    )
end

function from_dict(::Type{Modulation}, dict)
    Modulation(
        interval = from_dict(Interval, dict["interval"]),
        beats = dict["beats"],
        volume = dict["volume"],
    )
end
