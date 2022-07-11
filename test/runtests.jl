using Justly
using Documenter: doctest
using Test: @test, @test_throws, @testset
using AudioSchedules: AudioSchedule, duration
using Unitful: s

cd(joinpath(pkgdir(Justly))) do
    edit_justly("examples/simple.yml"; test = true)
    song = read_justly("examples/simple.yml")
    @test length(song.chords[1].notes) == 3
    audio_schedule = AudioSchedule()
    push!(audio_schedule, song, 0.0s)
    push!(audio_schedule, song, 1.0s)
    @test duration(audio_schedule) ≈ 1.97s
end

if v"1.7" <= VERSION < v"1.8"
    doctest(Justly)
end
