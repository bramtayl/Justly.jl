using Justly
using Justly: Song, Chord, Note, Interval
using Documenter: doctest
using Test: @test, @test_throws, @testset
using AudioSchedules: AudioSchedule, duration
using Base.Meta: ParseError
using Unitful: s

cd(joinpath(pkgdir(Justly), "test")) do
    edit_song("song.justly"; test = true)
    song = read_justly("song.justly")
    @test length(song.chords[1].notes) == 2
    @test duration(AudioSchedule(song)) == 0.8s

    @testset "parsing" begin
        @test_throws ParseError("Can't parse ? as beats on line 3") read_justly("bad_beats.justly")
        @test_throws ParseError("Can't parse ? as chord on line 3") read_justly("bad_chord.justly")
        @test_throws ParseError("Can't parse ? as denominator on line 3") read_justly("bad_denominator.justly")
        @test_throws ParseError("Can't parse o as interval on line 3") read_justly("bad_interval.justly")
        @test_throws ParseError("Can't parse ? as note on line 3") read_justly("bad_note.justly")
        @test_throws ParseError("Can't parse ? as numerator on line 3") read_justly("bad_numerator.justly")
        @test_throws ParseError("Can't parse ? as octave on line 3") read_justly("bad_octave.justly")
        @test_throws ParseError("Can't parse ? as tempo on line 1") read_justly("bad_tempo.justly")
        @test_throws ParseError("Can't parse ? as initial key on line 1") read_justly("bad_initial_key.justly")
        @test_throws ParseError("Can't parse ? as initial key and tempo on line 1") read_justly("bad_initial_key_and_tempo.justly")
    end
end

if v"1.6" <= VERSION < v"1.7"
    doctest(Justly)
end
