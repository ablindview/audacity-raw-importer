#!/usr/bin/env python3
"""
Audacity Raw Data Importer — Python helper.

Strategy: pre-convert each raw file to a temporary WAV using sox,
then import with Import2: which is fully silent (no dialog).
This avoids the interactive ImportRaw dialog that Audacity always shows.

Raw format assumed: Signed 32-bit PCM, default endianness, mono, 44100 Hz.
"""
import sys, os, time, tempfile, subprocess, shutil

SOX = '/opt/homebrew/bin/sox'

def send(tp, fp, cmd):
    """Send one command to Audacity via the scripting pipe and return response."""
    with open(tp, 'w') as f:
        f.write(cmd + '\n')
    resp = []
    with open(fp, 'r') as f:
        for line in f:
            line = line.rstrip('\n\r')
            resp.append(line)
            if line == 'BatchCommand finished':
                break
    return resp

def main():
    file_list_path = sys.argv[1]
    project_name   = sys.argv[2]
    save_path      = sys.argv[3]

    uid = str(os.getuid())
    tp  = '/tmp/audacity_script_pipe.to.'   + uid
    fp  = '/tmp/audacity_script_pipe.from.' + uid

    if not os.path.exists(tp):
        print('NOPIPE')
        return

    with open(file_list_path) as f:
        files = [line.strip() for line in f if line.strip()]

    if not files:
        print('NOFILES')
        return

    # ── Convert raw files → WAV in a temp directory ──────────────────────────
    # sox reads the raw PCM bytes and writes a proper WAV with a header.
    # -t raw        : input is headerless raw PCM
    # -e signed-integer : signed PCM encoding
    # -b 32         : 32 bits per sample
    # -r 44100      : sample rate
    # -c 1          : 1 channel (mono)
    tmp_dir = tempfile.mkdtemp(prefix='aud_importer_')
    wav_files = []
    for i, path in enumerate(files):
        out_wav = os.path.join(tmp_dir, f'track_{i:04d}.wav')
        result = subprocess.run(
            [SOX,
             '-t', 'raw',
             '-e', 'signed-integer',
             '-b', '32',
             '-r', '44100',
             '-c', '1',
             path,
             out_wav],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print('SOXERR:' + result.stderr.strip())
            shutil.rmtree(tmp_dir, ignore_errors=True)
            return
        wav_files.append(out_wav)

    # ── Open a new Audacity project ───────────────────────────────────────────
    send(tp, fp, 'New:')
    time.sleep(2)

    # ── Import each WAV silently — no dialog appears ──────────────────────────
    for wav in wav_files:
        r = send(tp, fp, 'Import2: Filename="' + wav + '"')
        time.sleep(1.5)

    # ── Align all tracks end-to-end then flatten to one mono track ────────────
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Align_EndToEnd:')
    time.sleep(0.5)
    send(tp, fp, 'MixAndRender:')
    time.sleep(3)

    # ── Normalize: -1 dB peak, remove DC offset ───────────────────────────────
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Normalize: PeakLevel=-1 ApplyGain=1 RemoveDcOffset=1 StereoIndependent=0')
    time.sleep(5)

    # ── Amplify: bring peak to 0 dB ───────────────────────────────────────────
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Amplify:')
    time.sleep(5)

    # ── Stereo mix: duplicate track, pan L/R, MixAndRender → stereo ──────────
    send(tp, fp, 'SelectAll:')
    time.sleep(0.3)
    send(tp, fp, 'Duplicate:')
    time.sleep(1)
    send(tp, fp, 'SelectTracks: Track=0 TrackCount=1')
    time.sleep(0.3)
    send(tp, fp, 'SetTrack: Pan=-1')
    time.sleep(0.3)
    send(tp, fp, 'SelectTracks: Track=1 TrackCount=1')
    time.sleep(0.3)
    send(tp, fp, 'SetTrack: Pan=1')
    time.sleep(0.3)
    send(tp, fp, 'SelectAll:')
    time.sleep(0.3)
    send(tp, fp, 'MixAndRender:')
    time.sleep(3)

    # ── Set metadata tags ─────────────────────────────────────────────────────
    send(tp, fp, 'Tags: artist="NFB of California" album="NFBCAL Convention 2026" year=2026')
    time.sleep(1)

    # ── Save the Audacity project (.aup3) ─────────────────────────────────────
    send(tp, fp, 'SaveProject2: Filename="' + save_path + '" AddToHistory=0')
    time.sleep(3)

    # ── Clean up temp WAVs ────────────────────────────────────────────────────
    shutil.rmtree(tmp_dir, ignore_errors=True)

    print('DONE')

main()
