using Justly
using Justly: add_press!, DEFAULT_INSTRUMENTS, get_instrument, sustain!, pulse!
using Documenter: doctest
using Test: @test, @test_throws, @testset
using AudioSchedules: AudioSchedule, duration, Hz, s
using Unitful: s

audio_schedule = AudioSchedule()
song = cd(joinpath(pkgdir(Justly))) do
    @test_throws ArgumentError("Folder doesn't exist!") edit_justly("not_a_folder/simple.yml")
    edit_justly("examples/simple.yml"; test = true)
    song = read_justly("examples/simple.yml")
end
@test length(song.chords[1].notes) == 3
push!(audio_schedule, song, 0.0s)
push!(audio_schedule, song, 1.0s)
@test duration(audio_schedule) ≈ 2.27s
empty!(audio_schedule)
@test_throws ArgumentError("Instrument \"not an instrument\" not found!") get_instrument(
    DEFAULT_INSTRUMENTS,
    "not an instrument",
)
pulse!(audio_schedule, 0s, 0.01s, 1, 440Hz)
@test length(collect(audio_schedule)) == 2
empty!(audio_schedule)
sustain!(audio_schedule, 0s, 0.01s, 1, 440Hz)
@test length(collect(audio_schedule)) == 2
empty!(audio_schedule)
@test_throws ArgumentError("Press type \"not a press\" not recognized") add_press!(
    audio_schedule,
    song,
    "not a press",
    (),
)

if v"1.7" <= VERSION < v"1.8"
    doctest(Justly)
end
