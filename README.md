# Justly

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bramtayl.github.io/Justly.jl/dev)
[![codecov](https://codecov.io/gh/bramtayl/Justly.jl/branch/master/graph/badge.svg?token=MK1IMGK0GE)](https://codecov.io/gh/bramtayl/Justly.jl)

You can use Justly to both compose and play music using any pitches you want.
Using staff notation, you can only write the notes of the 12-tone scale.
Some intervals in any 12-tone scale are close to harmonic, but other intervals are not.
Johnston [expanded staff notation](http://marsbat.space/pdfs/EJItext.pdf), but relying on staff notation limited him.

To start Justly, start Julia and run

```
using Justly
edit_song("new_song.justly")
```

## How to use Justly

In Justly, you write intervals as a rational fraction (integer / integer) times a power of 2.
A lowercase `o` stands for (`*2^`), similar how `E` stands for (`*10^`).
You can write the same ratio in multiple ways.
For example, you can write a fifth as `3/2`, or `3o-1`.

You will likely only need to know 4 intervals:

- Octave: `2/1`
- Perfect fifth: `3/2`
- Major third: `5/4`
- Harmonic seventh: `7/4`

You can create other intervals by multiplying and dividing these intervals.
For example, a minor third is up a perfect fifth and down a major third: `(3/2) / (5/4)` = `6/5`.
A major second is up two fifths and down an octave: `(3/2) * (3/2) / 2` = `9/8`.

In Justly, each row stands for a chord.
Each item in the row is a different note in the chord.
The first note in each chord is silent; you use it to change the current key.
All of the other notes in the chord are in reference to the key.
To interactively run the example Justly file below, run

```julia
using Justly
cd(pkgdir(Justly)) do
    edit_song("examples/simple.justly")
end
```

Frequency: 440 Hz
Tempo: 200 bpm
Volume: 0.2
# I
1: 1, 5/4 at 2.0, 3/2
# IV
2/3: 3/2, 1o1 at 2.0, 5/4o1
# I
3/2 for 2: 1 for 2, 5/4 for 2 at 2.0, 3/2 for 2

This song starts with a key of frequency 440Hz, that is, a concert A, at a tempo of 200 beats per minute and a volume of 0.2, that is, a fifth of the maximum volume. Note that playing more than 5 notes at once could result in peaking.
Chords last for 1 beat and notes play for 1 beat by default.
The key does not change in the first chord.
The three voices in the first chord play the tonic (≈A4), third (≈C#5), and fifth (≈E5).
All three voices play for `1` beat.
The second voice plays at double volume.

After 1 beat, the key changes: you divide the key by `3/2`, so the key goes down by a fifth.
Now the key is close to D4.
The three voices play the fifth (≈A4), up one octave (≈D5), and up one octave and a third (≈F#5). 
The second voice plays at double volume.

After 1 more beat, you multiply the key by `3/2`, so the key goes up by a fifth. The voices repeat the notes in the first chord, but play for `2` beats. Again, the second voice plays at double volume.

You can play any note by clicking the play button underneath the note.
You can play a song, starting with a certain chord, by clicking the play button underneath the chord.
You can add lyrics, or performance notes, to any chord.
You can set beats to 0 to overlap, or to a negative number to "travel back in time".
You can edit the tempo, initial frequency, and initial volume, using the sliders on the top.

!!! warning

    It's a good idea to hit the "Precompile" button before you play any sounds.
