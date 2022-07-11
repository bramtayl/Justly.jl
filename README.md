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
edit_song("new_song.yml")
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
Each row starts with a modulation, and then, has a list of notes.
You can use the modulation to change the current key and volume.
All notes in the chord are in reference to the key.
To interactively run the example Justly file below, run

```julia
using Justly
cd(pkgdir(Justly)) do
    edit_justly("examples/simple.yml")
end
```

Here is a schematic of what you will see:

```
Frequency: 220 Hz
Tempo: 200 bpm
Volume: 0.2
# I
1: 1, 5/4 at 2.0 with sustain!, 3/2
# IV
2/3: 3/2, 1o1 at 2.0 with sustain!, 5/4o1
# I
3/2 for 2: 1 for 2, 5/4 for 2 at 2.0 with sustain!, 3/2 for 2
```

You can edit the initial frequency, volume, and tempo, using the sliders on the top.

- `frequency` is the starting frequency, in Hz.
- `volume` is the starting volume of a single voice, between 0 and 1. To avoid peaking, lower the volume for songs with many voices.
- `tempo` is the tempo of the song, in beats per minute. These beats are indivisible, so for songs which subdivide beats, you will need to multiply the tempo accordingly.

This song starts with a key of frequency 220Hz, that is, a A3, at a tempo of 200 beats per minute and a volume of 0.2, that is, a fifth of maximum volume. Note that playing more than 5 notes at once could result in peaking.
The key does not change in the first chord.
The three voices in the first chord play the tonic (≈A3), third (≈C#4), and fifth (≈E45).
All three voices play for `1` beat.
The second voice plays at double volume, and uses the `sustain!` instrument.
All other voices use the `pulse!` instrument.
See the documentation for more information about instruments.

After 1 beat, the key changes: you divide the key by `3/2`, so the key goes down by a fifth.
Now the key is close to D4.
The three voices play the fifth (≈A3), up one octave (≈D4), and up one octave and a third (≈F#4). 
The second voice plays at double volume, and uses the `sustain!` instrument.
All other voices use the `pulse!` instrument.

After 1 more beat, you multiply the key by `3/2`, so the key goes up by a fifth. The voices repeat the notes in the first chord, but play for `2` beats. Again, the second voice plays at double volume.

You can play any note by clicking the play button underneath the note.
You can play a song, starting with a certain chord, by clicking the play button underneath the chord.
You can add lyrics, or performance notes, to any chord.
You can set beats to 0 to overlap, or to a negative number to "travel back in time".






