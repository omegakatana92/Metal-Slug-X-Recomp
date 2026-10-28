# SDL output path: what was wrong and what this build does

The YM2610 produces 55,555.5 stereo samples per second (8 MHz / 144). PC and
Steam Deck audio devices rarely accept that rate, and the queue between the
frame loop and the device is where audible faults usually come from. This
build's `neogeorecomp/src/window_sdl.c`:

* opens the device with `SDL_AUDIO_ALLOW_FREQUENCY_CHANGE`,
  `SDL_AUDIO_ALLOW_FORMAT_CHANGE` and `SDL_AUDIO_ALLOW_CHANNELS_CHANGE`, so a
  device that does not accept 55,555 Hz still opens instead of leaving the
  game silent;
* converts the YM2610 rate to the device rate with `SDL_AudioStream`, so no
  sample-rate mismatch is passed to the hardware;
* starts playback once 60 ms has been queued (a cushion against frame
  jitter), and never pads silence into the queue — the old path inserted
  silence whenever the queue dipped below 30 ms, which is exactly what
  happens under normal jitter and is audible as a click;
* if the queue exceeds 150 ms — a genuine stall such as a window drag or a
  long load — drops only the *oldest excess* down to 80 ms with
  `SDL_DequeueAudio`. The previous version called `SDL_ClearQueuedAudio()`,
  discarding everything and cutting the music.

`NG_AUDIO_TRACE=1` prints the negotiated device format once and, about once
per second, how many source frames have been fed, the current queue depth, the
peak queue depth and how many times excess audio had to be trimmed. That is
the diagnostic used to verify the path without a physical listening test.

## Still not covered by this document

* Playback on a physical audio device, and subjective quality.
* Devices that report a format change to something other than S16 (the
  conversion is done by SDL, but only S16/float device formats were
  exercised here).
* Bluetooth audio latency, which is outside the application's control.
