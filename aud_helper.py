#!/usr/bin/env python3
import sys, os, time

def send(tp, fp, cmd):
    """Send a command to Audacity and return its response lines."""
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

    # New empty project
    r = send(tp, fp, 'New:')
    time.sleep(2)

    # Import each raw file as a new mono track.
    # Encoding value must match Audacity's internal choice string exactly.
    # "int32" is the internal key Audacity uses for Signed 32-bit PCM.
    for path in files:
        r = send(tp, fp,
            'ImportRaw: Filename="' + path + '"'
            ' Encoding="int32"'
            ' ByteOrder="01"'
            ' Channels=1'
            ' Rate=44100')
        time.sleep(1.5)
        # Surface any error from Audacity back to the caller
        for line in r:
            if line.startswith('Error') or line.startswith('error'):
                print('AUDERR:' + line)
                return

    # Align all tracks end-to-end (sequential, not overlapping)
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Align_EndToEnd:')
    time.sleep(0.5)

    # Flatten to a single mono track
    send(tp, fp, 'MixAndRender:')
    time.sleep(3)

    # Normalize: -1 dB peak, remove DC offset
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Normalize: PeakLevel=-1 ApplyGain=1 RemoveDcOffset=1 StereoIndependent=0')
    time.sleep(5)

    # Amplify: bring peak to 0 dB
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Amplify:')
    time.sleep(5)

    # Convert mono to stereo mix:
    # Duplicate the track so we have two identical mono tracks,
    # pan one hard-left and one hard-right, then MixAndRender
    # to produce a single stereo track.
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

    # Set metadata tags
    send(tp, fp, 'Tags: artist="NFB of California" album="NFBCAL Convention 2026" year=2026')
    time.sleep(1)

    # Save Audacity project (.aup3)
    send(tp, fp, 'SaveProject2: Filename="' + save_path + '" AddToHistory=0')
    time.sleep(3)

    print('DONE')

main()
