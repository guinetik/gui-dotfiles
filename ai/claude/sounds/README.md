# Notification sounds

Played by `powershell/claude-notify.ps1` when Claude Code wants your
attention: the small potion when it is blocked on a question or a permission
prompt, the big one when a turn finishes.

| File | Trigger | Event |
|------|---------|-------|
| `PrinceOfPersiaSNESPotion.mp3` | `ask` | `Notification` hook (minus the 60s idle case) |
| `PrinceOfPersiaSNESBigPotion.mp3` | `done` | `Stop` hook |

## Provenance

Both are derived copies. The masters live outside this repo in
`~/Music/` and are never modified — these are the tuned versions, and the
repo is what the script actually reads so the sounds travel with the
dotfiles rather than depending on what happens to be in a music folder.

## Why they were re-encoded

The masters peak at −3.0 dB and −2.2 dBFS, which is close enough to full
scale to startle rather than notify. System notification sounds generally sit
around −6 to −12 dBFS. Both were attenuated by 10 dB, putting the peaks at
−13.5 and −12.4 dBFS, and dropped from 320 kbps to 128 kbps — inaudible on a
four-second 32 kHz sound effect from a 16-bit console, and it halves what the
repo has to carry.

## Regenerating

To re-derive at a different level, change the `volume` value and run from the
repo root:

```bash
for f in PrinceOfPersiaSNESPotion PrinceOfPersiaSNESBigPotion; do
  ffmpeg -y -i "$HOME/Music/$f.mp3" -af "volume=-10dB" \
    -c:a libmp3lame -b:a 128k "ai/claude/sounds/$f.mp3"
done
```

To check the result, `mean_volume` and `max_volume` come from:

```bash
ffmpeg -i ai/claude/sounds/PrinceOfPersiaSNESPotion.mp3 -af volumedetect -f null -
```

Less negative is louder. `max_volume` is the one that determines whether a
sound startles you.
