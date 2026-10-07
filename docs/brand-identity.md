# Jot identity

Jot is a personal MacParakeet fork for local dictation and meeting transcripts.
Its visible name is Jot. The bundle identifier, data folders, model cache,
preference keys, and upstream licenses retain their existing identity.

## Assets

- `Assets/AppIcon.icns` is the approved grayscale note/speech app icon.
- `Assets/AppIcon-1024x1024.png` is the matching approved bitmap.
- `Sources/MacParakeet/Resources/jot-mark.png` contains the same bitmap bytes
  for inline marks through `BreathWaveIcon.brandMark` and `BreathWaveLogo`.
- The menu bar uses an adaptive `doc.text` system symbol with a gray state dot.

Reuse these assets; do not regenerate or recolor the approved bitmap.
`BreathWaveLogo` renders the original grayscale image rather than treating
its full tile as a tintable template.

## Appearance

`DesignSystem.Colors` owns the neutral gray palette in light and dark mode.
Labels, icons, shape, and motion convey recording, processing, success, and
error states. Both recording pills use gray/white artwork on a dark capsule.
Speaker names identify transcript speakers; the palette stays neutral.

The sidebar and Transcribe view contain capture/library controls without
promotional feeds or inspirational footer copy. About retains the
MacParakeet attribution and links to its source and license. Dependency
license resources remain bundled.
