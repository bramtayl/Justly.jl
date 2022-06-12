using Justly
using Documenter: doctest
using Test: @test, @test_throws, @testset
using AudioSchedules: AudioSchedule, duration
using Base.Meta: ParseError
using Unitful: s

cd(joinpath(pkgdir(Justly))) do
    edit_song("examples/simple.justly"; test = true)
    song = read_justly("examples/simple.justly")
    @test length(song.chords[1].notes) == 3
    audio_schedule = AudioSchedule()
    push!(audio_schedule, song)
    @test duration(audio_schedule) == 1.27s

    @testset "parsing" begin
        @test_throws ParseError("Can't parse ? as beats on line 1") read_justly(
            "test/bad_beats.justly",
        )
        @test_throws ParseError("Can't parse ? as chord on line 1") read_justly(
            "test/bad_chord.justly",
        )
        @test_throws ParseError("Can't parse ? as denominator on line 1") read_justly(
            "test/bad_denominator.justly",
        )
        @test_throws ParseError("Can't parse o as interval on line 1") read_justly(
            "test/bad_interval.justly",
        )
        @test_throws ParseError("Can't parse ? as numerator on line 1") read_justly(
            "test/bad_numerator.justly",
        )
        @test_throws ParseError("Can't parse ? as octave on line 1") read_justly(
            "test/bad_octave.justly",
        )
        @test_throws ParseError("Can't parse ? as tempo on line 1") read_justly(
            "test/bad_tempo.justly",
        )
        @test_throws ParseError("Can't parse ? as frequency on line 1") read_justly(
            "test/bad_frequency.justly",
        )
        @test_throws ParseError("Can't parse ? as volume on line 1") read_justly(
            "test/bad_volume.justly",
        )
    end
end

if v"1.7" <= VERSION < v"1.8"
    doctest(Justly)
end
