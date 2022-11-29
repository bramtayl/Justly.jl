# Justly

## Motivation

You can use Justly to both compose and play music using any pitches you want.
Using staff notation, you can only write the items of the 12-tone scale.
Some intervals in any 12-tone scale are close to harmonic, but other intervals are not.
Johnston [expanded staff notation](http://marsbat.space/pdfs/EJItext.pdf), but relying on staff notation limited him.

## Building

You can use `vcpkg` and `cmake` to build binaries. I've only tested this on Windows.

## Command line usage

You can provide 1 command line argument, the path to a song file to open.
If you don't provide any arguments, Justly will prompt you to create or open a song file.

## Intervals

In Justly, you write intervals as a rational fraction (integer / integer) times a power of 2.
You can write the same ratio in multiple ways.
For example, you can write a fifth as `3/2`, or `3*2^-1`.

You will likely only need to know 4 intervals:

- Octave: `2/1`
- Perfect fifth: `3/2`
- Major third: `5/4`
- Harmonic seventh: `7/4`

You can create other intervals by multiplying and dividing these intervals.
For example, a minor third is up a perfect fifth and down a major third: `(3/2) / (5/4)` = `6/5`.
A major second is up two fifths and down an octave: `(3/2) * (3/2) / 2` = `9/8`.

## Top sliders

You can edit the starting frequency, starting volume, and starting tempo using the sliders on the top.

- `Starting frequency` is the starting frequency, in Hz.
- `Starting volume` is the starting volume, between 0 and 100%. To avoid peaking, lower the volume for songs with many voices.
- `Starting tempo` is the starting tempo, in beats per minute. These beats are indivisible, so for songs which subdivide beats, you will need to multiply the tempo accordingly.

# Chords vs. Notes

In Justly, there are "chords" and "notes".
A chord is a set of "notes" that will begin playing simulataneously.
You can think of a chord as a "key change" or modulation.
The interval, volume ratio, and tempo ratio changes in chords are cumulative.
The interval, volume ratio, and tempo ratio in a note are in reference to the chord, but only affect the note itself.
You can change the instrument of notes, but not chords.
Currently, only one instrument, "default", is supported, but that could change.

## Example

Here is a schematic of a song.

```
Starting frequency: 220 Hz
# I
1: 1, 5/4, 3/2
# IV
2/3: 3/2, 1o1, 5/4o1
# I
3/2 for 2: 1 for 2, 5/4 for 2, 3/2 for 2
```

This song starts with a key of frequency 220Hz, that is, a A3.
The key does not change in the first chord.
The three voices in the first chord play the tonic (≈A3), third (≈C#4), and fifth (≈E45).
All three voices play for `1` beat.

After 1 beat, the key changes: you divide the key by `3/2`, so the key goes down by a fifth.
Now the key is close to D4.
The three voices play the fifth (≈A3), up one octave (≈D4), and up one octave and a third (≈F#4). 

After 1 more beat, you multiply the key by `3/2`, so the key goes up by a fifth. The voices repeat the items in the first chord, but play for `2` beats.
