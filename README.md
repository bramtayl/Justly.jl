# Justly

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bramtayl.github.io/Justly.jl/dev)
[![Coverage](https://codecov.io/gh/bramtayl/Justly.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bramtayl/Justly.jl)

Have you ever felt constrained by only being able to compose with the 12 notes in the Western scale? You can use Justly to compose music using just intervals.
Almost all western instruments are constrained to the notes of the Western scale, with some exceptions (like the human voice, string instruments, and the trombone).
Even then, most string players and trombonists stick to memorized positions aligning with the western scale.
So you can never play perfectly in tune using the western scale.
Some equal tempered intervals are pretty close to their harmonic equivalents (fifths), but others, like the harmonic seventh, aren't even close.
If you're interested in hearing what just intervals sound like, check out [this video](https://www.youtube.com/watch?v=vC9Qh709gas).

The reason there aren't more musicians using just intonation is that there isn't a good way to write music in just notation (until now!).
There are some hacky ways to modify Western music notation to do it.
If you're bored, you can read about Johnston notation [here](http://marsbat.space/pdfs/EJItext.pdf).
However, these methods are fundamentally limited by relying on a limited method of music notation.
Justly is not an application but a totally new way of writing down music.

To run Justly, you will just need to run the Julia script in the repository.
To begin, run `justly_interactive` to bring up an interactive dialog for entering music using Justly notation.

## Instructions for using Justly:

Musical intervals are identified in Justly by a rational fraction (integer / integer) times a power of 2.
This means that there are multiple ways of writing the same ratio.
For example, you could write a fifth as `3/2*2^0`, or `3/1*2^-1`.

You will likely only need to know 4 fundamental intervals:

- Octave: `2/1`
- Major fifth: `3/2`
- Perfect third: `5/4`
- Harmonic seventh: `7/4`

You can create other intervals by multiplying and dividing these building blocks.
For example, a minor third is a perfect fifth divided by a major third: `(3/2) / (5/4)` = `6/5`.
A major second is up two fifths and down an octave: `(3/2) * (3/2) / 2` = `9/8`.

In Justly, each row refers to a chord.
You can add and remove new rows with the wide plus and minus buttons.
Each item in the row is a different note in the chord.
You can add and remove notes to a chord with the small plus and minus buttons.

The first note in each chord is special: it changes the current key.
All of the other notes in the chord are in reference to the key.
Consider the following example:

Starting key: `440Hz`

| Key | Voice 1 | Voice 2 | Voice 3 | Voice 4 |
| - | - | - | - | - |
| `1` for `1` | `1` for `1` | `3/2` for `1` | `2` for `1` | `5/4*2` for `1` |
| `2/3` for `1` | `3/2` for `1` | `5/4*2` for `1` | `3/2*2` for `1` | `2^2` for `1` |
| `3/2` for `2` | `1` for `2` | `3/2` for `2` | `2` for `2` | `5/4*2` for `2` |

This song starts in `440Hz`, that is, a concert A.
The first chord doesn't change the key (so multiplies by `1`).
The key is not intended to be played, but only to serve as an anchor for the voices.
The four voices in the first chord are on the tonic (≈A4), fifth (≈E5), the octave (≈A5), and the third up an octave (≈C#6).
All four voices play for `1` beat.

After 1 beat, the key changes: it goes down by a fifth, so divide by `3/2`, that is, multiply by `2/3`.
Now we are close to the key of D.
The four voices are on the fifth (≈A4), third up an octave (≈F#5), fifth up an octave (≈A5), and up two octaves (≈D6).

After 1 more beat, the key changes, and we return to our original chord by moving the key up a fifth (`3/2`).
Now, all the voices play for `2` beats.

You can preview the pitch of any note or key in the song by clicking the play button underneath it.
Once you are done, you can play the whole song or copy the song to your clipboard in YAML.
You can play YAML using the `justly` function.
The YAML notation omits values if they are equal to defaults.
- The default words are ""
- The default interval is 1
- The default octave is 0
- The default beats is 1