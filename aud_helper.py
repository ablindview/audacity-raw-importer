#!/usr/bin/env python3
import sys, os, time

def send(tp, fp, cmd):
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
    send(tp, fp, 'New:')
    time.sleep(2)

    # Import each raw file as a new track
    for path in files:
        send(tp, fp,
            'ImportRaw: Filename="' + path + '" Encoding="Signed 16-bit PCM" '
            'ByteOrder="Default byte order" Channels=1 Rate=44100')
        time.sleep(1.5)

    # If multiple files: align end-to-end, then mix down to one track
    if len(files) > 1:
        send(tp, fp, 'SelectAll:')
        time.sleep(0.5)
        send(tp, fp, 'Align_EndToEnd:')
        time.sleep(0.5)
        send(tp, fp, 'MixAndRender:')
        time.sleep(3)

    # Normalize
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Normalize: PeakLevel=-1 ApplyGain=1 RemoveDcOffset=1 StereoIndependent=0')
    time.sleep(5)

    # Amplify (default: bring peak to 0 dB)
    send(tp, fp, 'SelectAll:')
    time.sleep(0.5)
    send(tp, fp, 'Amplify:')
    time.sleep(5)

    # Set metadata tags
    send(tp, fp, 'Tags: artist="NFB of California" album="NFBCAL Convention 2026" year=2026')
    time.sleep(1)

    # Save Audacity project (.aup3)
    send(tp, fp, 'SaveProject2: Filename="' + save_path + '" AddToHistory=0')
    time.sleep(3)

    print('DONE')

main()
