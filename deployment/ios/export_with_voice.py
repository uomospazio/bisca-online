#!/usr/bin/env python3
"""Export the iOS Xcode project, then restore the native LiveKit integration."""
import argparse
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true")
    parser.add_argument("--godot", type=Path, default=Path.home() / "Downloads/Godot.app/Contents/MacOS/Godot")
    parser.add_argument("--godot-source", type=Path, default=Path("/private/tmp/bisca-voice-godot"))
    parser.add_argument("--output", type=Path, default=Path.home() / "Desktop/Bisca_iOS_test/index.ipa")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without exporting or modifying files")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    setup = Path(__file__).with_name("setup.py")
    if not args.godot.is_file():
        parser.error("Godot not found; specify --godot")
    if not args.godot_source.is_dir():
        parser.error("Godot headers not found; specify --godot-source (see README.md)")
    commit = subprocess.check_output(["git", "-C", str(args.godot_source), "rev-parse", "HEAD"], text=True).strip()
    if commit != "ed1daf0bf001b61586d9930840f2f1394092c079":
        parser.error("Godot source must match official 4.7.2")
    version = subprocess.check_output([str(args.godot), "--version"], text=True).strip()
    if not version.startswith("4.7.2.stable.official"):
        parser.error("Use the official Godot 4.7.2 executable")
    mode = "release" if args.release else "debug"
    output = args.output.expanduser().resolve()
    commands = [
        [str(args.godot), "--headless", "--path", str(repo), "--export-" + mode, "iOS", str(output)],
        [sys.executable, str(setup), str(output.with_suffix(".xcodeproj")), "--godot-source", str(args.godot_source.resolve()), "--engine-target", "template_" + mode],
    ]
    if args.dry_run:
        import shlex
        for command in commands:
            print(shlex.join(command))
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    for command in commands:
        subprocess.run(command, check=True)
    print("Xcode project with LiveKit ready: " + str(output.with_suffix(".xcodeproj")))
    print("Build / Run in Xcode. Existing IPA files have NOT been rebuilt.")


if __name__ == "__main__":
    main()
