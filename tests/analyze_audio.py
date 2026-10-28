#!/usr/bin/env python3
"""Objective audio diagnostics for a recompilation capture.

Usage: python tests/analyze_audio.py <capture.wav> [--boot SECONDS]

Prints format, peak, RMS, DC offset, clipped-sample count, channel balance
and per-second silent runs. This is a measurement tool, not a listening
test: it finds dropouts, hard clipping and gross level errors, not a wrong
instrument.

No third-party modules: struct only, so it runs in a bare Python.
"""
import argparse
import math
import struct
import sys
import wave


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("wav")
    ap.add_argument("--boot", type=float, default=10.0,
                    help="ignore silent runs before this many seconds")
    ap.add_argument("--silence", type=float, default=50.0,
                    help="RMS threshold counted as silence")
    args = ap.parse_args()

    try:
        w = wave.open(args.wav, "rb")
    except OSError as e:
        print(f"cannot open {args.wav}: {e}")
        return 2
    rate, channels, width = w.getframerate(), w.getnchannels(), w.getsampwidth()
    n = w.getnframes()
    raw = w.readframes(n)
    w.close()
    if width != 2:
        print(f"expected 16-bit PCM, got {width * 8} bit")
        return 2

    total = len(raw) // 2
    samples = struct.unpack("<%dh" % total, raw)
    frames = total // channels
    dur = frames / rate if rate else 0.0

    left = samples[0::channels]
    right = samples[1::channels] if channels > 1 else left

    def stats(xs):
        if not xs:
            return 0.0, 0.0, 0.0, 0
        peak = max(max(xs), -min(xs))
        mean = sum(xs) / len(xs)
        rms = math.sqrt(sum(float(x) * x for x in xs) / len(xs))
        clipped = sum(1 for x in xs if x >= 32767 or x <= -32768)
        return peak, mean, rms, clipped

    lp, lm, lr, lc = stats(left)
    rp, rm, rr, rc = stats(right)

    print(f"file        {args.wav}")
    print(f"format      {rate} Hz, {channels} ch, 16 bit, {dur:.2f} s")
    print(f"peak        L {lp}  R {rp}")
    print(f"rms         L {lr:.1f}  R {rr:.1f}")
    if rr > 0:
        print(f"balance     L/R {lr / rr:.3f}")
    print(f"dc offset   L {lm:+.2f}  R {rm:+.2f}")
    print(f"clipped     L {lc}  R {rc}"
          + ("  <-- hard clipping" if max(lc, rc) > 0 else ""))

    # per-second RMS on the mono sum
    mono = [(left[i] + (right[i] if channels > 1 else left[i])) / 2.0
            for i in range(frames)]
    secs = []
    for start in range(0, frames - rate + 1, rate):
        block = mono[start:start + rate]
        secs.append(math.sqrt(sum(x * x for x in block) / len(block)))

    silent = [i for i, r in enumerate(secs)
              if i >= args.boot and r < args.silence]
    runs = []
    for i in silent:
        if runs and i == runs[-1][1] + 1:
            runs[-1] = (runs[-1][0], i)
        else:
            runs.append((i, i))
    print(f"silent      {len(runs)} run(s) after {args.boot:.0f} s, "
          f"longest {max((b - a + 1 for a, b in runs), default=0)} s")
    if runs:
        print("            " + ", ".join(
            f"{a}-{b}" if a != b else str(a) for a, b in runs))
    # level steps: a 10 dB drop or rise between adjacent seconds
    steps = []
    for i in range(1, len(secs)):
        if secs[i - 1] <= 1 or secs[i] <= 1:
            continue
        d = 20 * math.log10(secs[i] / secs[i - 1])
        if abs(d) >= 10:
            steps.append((i, d))
    print(f"level steps {len(steps)} (>=10 dB second-to-second)")
    for i, d in steps[:20]:
        print(f"            {i - 1}s -> {i}s  {d:+.1f} dB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
