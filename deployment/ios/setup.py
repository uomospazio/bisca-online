#!/usr/bin/env python3
"""Wire native voice into an existing Godot 4.7.2 Xcode export (idempotent)."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys

GODOT_COMMIT = "ed1daf0bf001b61586d9930840f2f1394092c079"
LIVEKIT_VERSION = "2.17.0"


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path, help="Exported .xcodeproj")
    parser.add_argument("--godot-source", type=Path, required=True)
    parser.add_argument("--engine-target", choices=["template_debug", "template_release"], required=True,
                        help="Must match the exported archive, independent of Xcode configuration")
    args = parser.parse_args()
    project = args.project.resolve()
    source = args.godot_source.resolve()
    if run("git", "-C", str(source), "rev-parse", "HEAD") != GODOT_COMMIT:
        parser.error("Godot headers must match 4.7.2 commit " + GODOT_COMMIT)
    archive = project.parent / (project.stem + ".xcframework") / "ios-arm64/libgodot.a"
    archive_members = run("ar", "-t", str(archive))
    if ".ios." + args.engine_target + "." not in archive_members:
        parser.error("--engine-target does not match the exported Godot archive")

    # Use Godot's own generators. No hand-written stand-ins for generated ABI.
    sys.path.insert(0, str(source))
    generated = project.parent / "BiscaVoiceGenerated"
    for relative, module in [("core/extension/gdextension_interface.gen.h", "core/extension/make_interface_header.py"),
                             ("core/object/gdvirtual.gen.h", "core/object/make_virtuals.py")]:
        target = generated / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        spec = importlib.util.spec_from_file_location("bisca_generator", source / module)
        generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(generator)
        generator.run([str(target)], [str(source / "core/extension/gdextension_interface.json")], {})
    # Official full templates disable no classes.
    (generated / "core/disabled_classes.gen.h").write_text("// Full official Godot template: no disabled classes.\n")

    pbx = project / "project.pbxproj"
    data = json.loads(run("plutil", "-convert", "json", "-o", "-", str(pbx)))
    objects = data["objects"]
    root = objects[data["rootObject"]]
    targets = [objects[t] for t in root["targets"] if objects[t].get("productType") == "com.apple.product-type.application"]
    if len(targets) != 1:
        parser.error("Expected exactly one application target")
    target = targets[0]
    repo_sources = Path(__file__).resolve().parent

    def uid(name):
        return hashlib.sha256(("BiscaVoice/" + name).encode()).hexdigest()[:24].upper()

    def append(obj, key, value):
        if value not in obj.setdefault(key, []):
            obj[key].append(value)

    for name, kind in [("BiscaVoice.swift", "sourcecode.swift"), ("BiscaVoice.mm", "sourcecode.cpp.objcpp")]:
        ref, build = uid(name), uid(name + "build")
        objects[ref] = {"isa": "PBXFileReference", "lastKnownFileType": kind,
                        "path": str(repo_sources / name), "sourceTree": "<absolute>"}
        objects[build] = {"isa": "PBXBuildFile", "fileRef": ref}
        append(objects[root["mainGroup"]], "children", ref)
        for phase in target["buildPhases"]:
            if objects[phase]["isa"] == "PBXSourcesBuildPhase":
                append(objects[phase], "files", build)

    package, product, framework = uid("LiveKitPackage"), uid("LiveKitProduct"), uid("LiveKitFramework")
    objects[package] = {"isa": "XCRemoteSwiftPackageReference", "repositoryURL": "https://github.com/livekit/client-sdk-swift.git",
                        "requirement": {"kind": "exactVersion", "version": LIVEKIT_VERSION}}
    objects[product] = {"isa": "XCSwiftPackageProductDependency", "package": package, "productName": "LiveKit"}
    objects[framework] = {"isa": "PBXBuildFile", "productRef": product}
    append(root, "packageReferences", package)
    append(target, "packageProductDependencies", product)
    for phase in target["buildPhases"]:
        if objects[phase]["isa"] == "PBXFrameworksBuildPhase":
            append(objects[phase], "files", framework)

    configs = objects[target["buildConfigurationList"]]["buildConfigurations"]
    for config in configs:
        settings = objects[config]["buildSettings"]
        settings["CLANG_CXX_LANGUAGE_STANDARD"] = "c++17"
        for key in ["HEADER_SEARCH_PATHS", "SYSTEM_HEADER_SEARCH_PATHS", "GCC_PREPROCESSOR_DEFINITIONS"]:
            old = settings.get(key, ["$(inherited)"])
            if isinstance(old, str):
                old = [old]
            settings[key] = old
        # Godot headers are external dependencies; retain warnings in our bridge.
        for path in [source, source / "platform/ios", generated]:
            quoted = '"' + str(path) + '"'
            settings["HEADER_SEARCH_PATHS"] = [
                p for p in settings["HEADER_SEARCH_PATHS"] if p not in [quoted, str(path)]]
            append(settings, "SYSTEM_HEADER_SEARCH_PATHS", quoted)
        # Automatic signing chooses development provisioning when building;
        # Xcode handles distribution signing at archive export time.
        if settings.get("CODE_SIGN_STYLE") == "Automatic":
            for key in list(settings):
                if key == "CODE_SIGN_IDENTITY" or key.startswith("CODE_SIGN_IDENTITY["):
                    settings[key] = "Apple Development"
        definitions = ["IOS_ENABLED", "UNIX_ENABLED", "THREADS_ENABLED", "CLIPPER2_ENABLED"]
        settings["GCC_PREPROCESSOR_DEFINITIONS"] = [
            d for d in settings["GCC_PREPROCESSOR_DEFINITIONS"]
            if d != "DEBUG_ENABLED" and not d.startswith("BISCA_SWIFT_HEADER=")]
        definitions.append("NDEBUG")
        if args.engine_target == "template_debug":
            definitions.append("DEBUG_ENABLED")
        definitions.append('BISCA_SWIFT_HEADER=\\"' + target["name"] + '-Swift.h\\"')
        for define in definitions:
            append(settings, "GCC_PREPROCESSOR_DEFINITIONS", define)
        settings["SWIFT_VERSION"] = "5.0"
        info = project.parent / settings["INFOPLIST_FILE"]
        plist = plistlib.loads(info.read_bytes())
        plist["NSMicrophoneUsageDescription"] = "Bisca usa il microfono per parlare con gli amici nella lobby."
        info.write_bytes(plistlib.dumps(plist))

    dummy = project.parent / target["name"] / "dummy.cpp"
    contents = dummy.read_text()
    if "void bisca_voice_initialize();" not in contents:
        for hook, call in [("initialize", "bisca_voice_initialize"), ("deinitialize", "bisca_voice_deinitialize")]:
            pattern = r"(void godot_apple_embedded_plugins_" + hook + r"\(\)\s*\{)"
            contents, count = re.subn(pattern, r"\1\n    " + call + "();", contents)
            if count != 1:
                parser.error("Missing unique Godot plugin hook: " + hook)
        contents = "void bisca_voice_initialize();\nvoid bisca_voice_deinitialize();\n" + contents
        shutil.copy2(dummy, dummy.with_suffix(".cpp.before-bisca-voice"))
        dummy.write_text(contents)
    if not pbx.with_suffix(".pbxproj.before-bisca-voice").exists():
        shutil.copy2(pbx, pbx.with_suffix(".pbxproj.before-bisca-voice"))
    pbx.write_bytes(plistlib.dumps(data, fmt=plistlib.FMT_XML, sort_keys=False))
    print("Configured", project, "with LiveKit", LIVEKIT_VERSION, "and", args.engine_target)


if __name__ == "__main__":
    main()
