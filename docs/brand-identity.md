# Jot identity

Jot is a personal MacParakeet fork for local dictation and meeting transcripts.
Its visible name is Jot. The bundle identifier, data folders, model cache,
preference keys, and upstream licenses retain their existing identity.

## Assets

- `Assets/AppIcon.icns` is the approved grayscale note/speech app icon.
- `Assets/AppIcon-1024x1024.png` is the matching approved bitmap.
- `Sources/MacParakeet/Resources/jot-mark.png` contains the same bitmap bytes
  for inline marks through `BreathWaveIcon.brandMark` and `BreathWaveLogo`.
- The menu bar uses an adaptive `doc.text` system symbol with the original red recording and orange processing state dots.

Reuse these assets; do not regenerate or recolor the approved bitmap.
`BreathWaveLogo` renders the original grayscale image rather than treating
its full tile as a tintable template.

## Appearance

The app retains MacParakeet's original macOS styling. `DesignSystem.Colors`
owns its original light/dark palette: the coral primary action accent,
neutral secondary controls, semantic status colors, and distinct transcript
speaker colors. Recording pills retain their original red/amber capture
indicators and green/gold completion artwork on a dark capsule. The approved
gray app icon remains unchanged.

The sidebar and Transcribe view contain capture/library controls without
promotional feeds or inspirational footer copy. About retains the
MacParakeet attribution and links to its source and license. Dependency
license resources remain bundled.
