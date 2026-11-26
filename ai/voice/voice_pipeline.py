"""Voice pipeline demo (task #36):  audio -> FarukSTT -> assistant -> spoken answer.

Run from the repo root, for example:
    python ai/voice/voice_pipeline.py ai/stt/audio/q01.m4a --base-url http://localhost:8000 --token XXX --farm-id FARM_ID
Test the chain WITHOUT audio / model:
    python ai/voice/voice_pipeline.py --transcript "وقتاش نسقي ليوم؟" --base-url ... --token ... --farm-id ...

The farmer's words are transcribed with FarukSTT (Arabic language hint, the better setting in ai/stt/README.md),
sent to POST /farms/{farm_id}/irrigation/advice, and answered with a pre-recorded clip from ai/voice/clips/.
No clip is ever generated: if a clip is missing, the text answer is shown instead.
"""
import argparse, json, os, sys, urllib.error, urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
CLIP_DIR = HERE / "clips"
MODEL_ID = "medyas/FarukSTT"
CLIP_EXTS = (".wav", ".mp3", ".m4a")
ACTIONS = ("irrigate_now", "wait", "monitor", "insufficient_data")

def load_audio(path):
    """Decode any audio file (m4a, wav, mp3...) to 16 kHz mono float32 using ffmpeg."""
    import shutil, subprocess
    import numpy as np
    if shutil.which("ffmpeg"):
        proc = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", "16000", "-"],
                              capture_output=True)
        if proc.returncode == 0 and proc.stdout:
            return np.frombuffer(proc.stdout, dtype=np.float32).copy()
        sys.exit(f"ffmpeg could not decode {path}: {proc.stderr.decode('utf-8', 'replace')[:200]}")
    try:
        import librosa
        return librosa.load(str(path), sr=16000)[0]
    except Exception as e:
        sys.exit(f"Cannot read {path}: {e}\nInstall ffmpeg (winget install Gyan.FFmpeg), reopen the terminal, and retry.")

def transcribe(audio_path):
    """FarukSTT with the Arabic hint. Uses the GPU if it fits, otherwise the CPU."""
    import torch
    from transformers import pipeline
    audio = load_audio(audio_path)
    kwargs = {"language": "arabic", "task": "transcribe"}
    for device in (["cuda"] if torch.cuda.is_available() else []) + ["cpu"]:
        try:
            dtype = torch.float16 if device == "cuda" else torch.float32
            asr = pipeline("automatic-speech-recognition", model=MODEL_ID, torch_dtype=dtype,
                           device=0 if device == "cuda" else -1)
            text = asr({"raw": audio, "sampling_rate": 16000}, generate_kwargs=kwargs)["text"].strip()
            print(f"[stt] model {MODEL_ID} on {device}")
            return text
        except RuntimeError as e:                       # e.g. CUDA out of memory on a 4 GB card
            if device == "cpu":
                raise
            print(f"[stt] {device} failed ({str(e)[:60]}...), retrying on cpu")
            torch.cuda.empty_cache()

def ask_assistant(base_url, token, farm_id, message):
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}/farms/{farm_id}/irrigation/advice",
        data=json.dumps({"message": message[:500]}).encode("utf-8"),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"Assistant returned HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:300]}")
    except urllib.error.URLError as e:
        sys.exit(f"Cannot reach {base_url}: {e.reason}")

def find_clip(name):
    for ext in CLIP_EXTS:
        p = CLIP_DIR / f"{name}{ext}"
        if p.exists():
            return p
    return None

def clips_for(advice):
    """Which clips to play, in order: the action, then the expert-review notice if escalated."""
    names = [advice["action"] if advice.get("action") in ACTIONS else "insufficient_data"]
    if advice.get("expert_review_required") and names[0] != "insufficient_data":
        names.append("expert_review")
    return names

def play(path):
    if path.suffix == ".wav" and os.name == "nt":
        import winsound
        winsound.PlaySound(str(path), winsound.SND_FILENAME)        # waits until finished
    elif os.name == "nt":
        os.startfile(str(path))                                     # opens default player, no waiting
    else:
        print(f"[audio] play manually: {path}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("audio", nargs="?", help="recording of the farmer's question (.wav/.m4a)")
    ap.add_argument("--transcript", help="skip speech-to-text and use this text")
    ap.add_argument("--base-url", required=True)
    ap.add_argument("--token", required=True, help="JWT access token (from /docs -> Authorize)")
    ap.add_argument("--farm-id", required=True)
    ap.add_argument("--yes", action="store_true", help="do not ask the farmer to confirm the transcript")
    ap.add_argument("--no-audio", action="store_true", help="do not play clips")
    a = ap.parse_args()
    if not a.audio and not a.transcript:
        ap.error("give an audio file or --transcript")

    text = a.transcript or transcribe(a.audio)
    print(f"\n[1] Transcript: {text!r}")
    if not text.strip():
        print("[!] Nothing understood."); p = find_clip("not_understood")
        if p and not a.no_audio: play(p)
        sys.exit(2)
    if not a.yes and input("    Is this what you said? [Y/n] ").strip().lower() in ("n", "no"):
        print("[!] Please record the question again."); sys.exit(3)

    advice = ask_assistant(a.base_url, a.token, a.farm_id, text)
    print(f"\n[2] Assistant: {advice['action']} - {advice['action_label']}")
    print(f"    {advice['explanation']}")
    for s in advice.get("recommended_steps", []):
        print(f"    - {s}")
    print(f"    confidence {advice['confidence']:.2f} ({advice['confidence_level']}) | "
          f"expert review: {advice['expert_review_required']} | sources: {advice['source_label']}")

    print("\n[3] Spoken answer:")
    for name in clips_for(advice):
        p = find_clip(name)
        if p is None:
            print(f"    (no clip '{name}' in {CLIP_DIR.name}/ -> text answer only)")
        else:
            print(f"    playing {p.name}")
            if not a.no_audio: play(p)

if __name__ == "__main__":
    main()
