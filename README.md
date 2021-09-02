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
chords = Chord[]
edit_song(chords)
```

## How to use Justly

In Justly, one writes intervals as a rational fraction (integer / integer) times a power of 2.
A lowercase `o` stands for (`*2^`), similar how `E` stands for (`*10^`).
One can write the same ratio in multiple ways.
For example, one can write a fifth as `3/2`, or `3o-1`.

You will likely only need to know 4 intervals:

- Octave: `2/1`
- Major fifth: `3/2`
- Perfect third: `5/4`
- Harmonic seventh: `7/4`

You can create other intervals by multiplying and dividing these intervals.
For example, a minor third is up a perfect fifth and down a major third: `(3/2) / (5/4)` = `6/5`.
A major second is up two fifths and down an octave: `(3/2) * (3/2) / 2` = `9/8`.

In Justly, each row stands for a chord.
Each item in the row is a different note in the chord.
The first note in each chord is silent; one uses it to change the current key.
All of the other notes in the chord are in reference to the key.
For example:

Starting key: `440Hz`

| Key | Voice 1 | Voice 2 | Voice 3 |
| - | - | - | - |
| `1` for `1` | `1` for `1` | `3/2` for `1` | `5/4o1` for `1` |
| `2/3` for `1` | `3/2` for `1` | `5/4o1` for `1` | `o2` for `1` |
| `3/2` for `2` | `1` for `2` | `3/2` for `2` | `5/4o1` for `2` |

This song starts with a key of frequency `440Hz`, that is, a concert A.
The key does not change in the first chord.
The three voices in the first chord play the tonic (≈A4), fifth (≈E5), and the third up an octave (≈C#6).
All four voices play for `1` beat.

After 1 beat, the key changes: you divide the key by `3/2`, so the key goes down by a fifth.
Now the key is close to D4.
The four voices play the fifth (≈A4), third up an octave (≈F#5), and up two octaves (≈D6).

After 1 more beat, you multiply the key by `3/2`, so the key goes up by a fifth. The voices repeat the notes in the first chord, but play for `2` beats.

You can play any note by clicking the play button underneath the note.
You can play a song, starting with a certain chord, by clicking the play button underneath the chord.
You can add lyrics, or performance notes, to any chord.
You can set beats to 0 to overlap, or to a negative number to "travel back in time".
You can copy the song as YAML on the left.
You can also import YAML.
You can convert YAML, or a vector of chords, directly to an `AudioSchedule` using `make_schedule`.
One omits values in the YAML notation if the values are equal to their defaults.

- The default "words" is ""
- The default "interval" is 1
- The default "octave" is 0
- The default "beats" is 1