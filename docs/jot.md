# Using Jot

Jot is a personal MacParakeet fork. Dictation and meeting speech recognition
use the local Parakeet v3 model on this Mac.

- Tap physical **F5** to start dictation. Tap **F5** again to stop and paste.
  For a cold AirPods connection, the chosen practice is to pause about two
  seconds after starting before speaking. Jot adds no delay or hold gesture.
  The microphone closes after recording, preserving playback quality.
- Drag the center waveform/timer area of the dictation pill to move it away
  from text. The idle and recording pills share the saved position. The
  meeting pill is also draggable and saves its own position. Positions
  survive later recordings and app launches. In Settings → Capture →
  Dictation, **Reset pill positions** restores both defaults; Top/Bottom
  resets the dictation edge.
- Start a meeting with **Microphone + System Audio** to capture your voice
  and audio played on this Mac. Stop it, then use **Export → Markdown** for
  a local transcript with speaker labels. Open or paste that file in your
  separate LLM app when you want summaries or analysis.
- Updates are manual. Official upstream changes are reviewed before a new
  Jot build is installed. This personal build blocks the official automatic
  updater from replacing Jot.

The existing bundle/data identity, models, recordings, preferences, and
credentials are preserved. MacParakeet and dependency licenses remain in the
app; About links to the upstream project.

The Mac Mini/AirPods/Glove80 checks cover one complete physical F5 dictation
and a short microphone plus system-audio meeting with a local Markdown
export. They do not establish long meeting endurance or distinct-human
speaker recognition.
