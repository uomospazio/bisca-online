"""Stage only BISCA's dependency closure, never the embedded Lexispell demo.

Usage: python3 deployment/package.py /absolute/new/directory
The destination must not exist; existing user files are never overwritten.
"""
import pathlib
import re
import shutil
import sys

root = pathlib.Path(__file__).resolve().parents[1]
target = pathlib.Path(sys.argv[1]).resolve()
target.mkdir(parents=True, exist_ok=False)
pending = ["project.godot", "icon.png", "scenes/balatro/balatro.tscn"]
pending += [str(p.relative_to(root)) for p in (root / "scenes/balatro/scripts").glob("*.gd")]
# Deck filenames are constructed at runtime rather than written as resource paths.
pending += [str(p.relative_to(root)) for p in (root / "scenes/balatro/trick_asset/mazzo_2/briscola").glob("*.png")]
seen = set()
while pending:
    name = pending.pop()
    if name in seen:
        continue
    source = (root / name).resolve()
    if not source.is_relative_to(root) or "scenes/Lexispell/" in name:
        raise ValueError(f"Unexpected dependency: {name}")
    if not source.is_file():
        raise FileNotFoundError(name)
    seen.add(name)
    output = target / name
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, output)
    for suffix in (".uid", ".import"):
        sidecar = pathlib.Path(str(source) + suffix)
        if sidecar.is_file():
            shutil.copy2(sidecar, str(output) + suffix)
    if source.suffix in (".gd", ".tscn", ".tres", ".godot", ".gdshader"):
        content = source.read_text()
        for dependency in re.findall(r'res://([^"\n]+)', content):
            if (root / dependency).is_file():
                pending.append(dependency)
for name in ("Dockerfile", ".dockerignore", "render.yaml", "LICENSE"):
    shutil.copy2(root / name, target / name)
shutil.copytree(root / "deployment", target / "deployment")
shutil.copy2(root / "deployment/web-export.cfg", target / "export_presets.cfg")
shutil.copy2(root / "deployment/README.md", target / "README.md")
shutil.copy2(root / "deployment/publish.gitignore", target / ".gitignore")
print(f"Staged {len(seen)} resources in {target}")
