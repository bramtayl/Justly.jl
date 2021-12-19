using Justly
using Documenter: doctest
using Test: @test_throws

@test_throws Base.Meta.ParseError("Can't parse interval a") parse(Justly.Interval, "a")

doctest(Justly)
