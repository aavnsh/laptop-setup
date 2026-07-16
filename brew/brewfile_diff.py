#!/usr/bin/env python3
import re
import subprocess
import sys
from collections import defaultdict


def parse_brewfile(content: str) -> dict:
    """Parses Brewfile content into a structured dictionary of sets."""
    packages = {"tap": set(), "brew": set(), "cask": set(), "mas": set()}

    # Matches lines like: brew "git"; cask "docker"; tap "homebrew/bundle"
    # Captures the type (brew/cask/etc) and the package identifier/name
    pattern = re.compile(r'^\s*(brew|cask|tap|mas)\s+["\']([^"\']+)["\']')

    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        match = pattern.match(line)
        if match:
            pkg_type, pkg_name = match.groups()
            # Normalize names to lowercase for robust comparison
            packages[pkg_type].add(pkg_name.lower())

    return packages


def get_current_system_brewfile() -> str:
    """Generates a Brewfile dump from the live system memory."""
    print("⏳ Gathering current system Homebrew state (brew bundle dump)...")
    try:
        # Run brew bundle dump to stdout safely without writing a file
        result = subprocess.run(
            ["brew", "bundle", "dump", "--file=-"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ Error running 'brew bundle': {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("❌ 'brew' command not found. Is Homebrew installed?", file=sys.stderr)
        sys.exit(1)


def print_diff(ref_pkgs: dict, target_pkgs: dict, ref_name: str, target_name: str):
    """Computes and prints what is added or removed elegantly."""
    all_types = ["tap", "brew", "cask", "mas"]
    has_changes = False

    print("=" * 60)
    print(f"Comparing Reference ({ref_name}) ➔ Target ({target_name})")
    print("=" * 60)

    for pkg_type in all_types:
        ref_set = ref_pkgs[pkg_type]
        target_set = target_pkgs[pkg_type]

        # Elements in target but NOT in reference (Added)
        added = target_set - ref_set
        # Elements in reference but NOT in target (Removed)
        removed = ref_set - target_set

        if added or removed:
            has_changes = True
            print(f"\n📦 {pkg_type.upper()}S:")

            for item in sorted(added):
                print(f"  ➕ [ADDED]   {item}")
            for item in sorted(removed):
                print(f"  ➖ [REMOVED] {item}")

    if not has_changes:
        print("\n✨ Perfect match! No additions or removals found.")
    print()


def main():
    args = sys.argv[1:]

    if len(args) == 2:
        # Case 1: Two Brewfiles provided
        ref_file, target_file = args[0], args[1]
        print(f"📖 Reading Reference Brewfile: {ref_file}")
        with open(ref_file, "r") as f:
            ref_pkgs = parse_brewfile(f.read())

        print(f"📖 Reading Target Brewfile: {target_file}")
        with open(target_file, "r") as f:
            target_pkgs = parse_brewfile(f.read())

        print_diff(ref_pkgs, target_pkgs, ref_file, target_file)

    elif len(args) == 1:
        # Case 2: One Brewfile provided (System vs Brewfile)
        target_file = args[0]

        # System is thought of as the Reference Copy
        system_content = get_current_system_brewfile()
        ref_pkgs = parse_brewfile(system_content)

        print(f"📖 Reading Target Brewfile: {target_file}")
        with open(target_file, "r") as f:
            target_pkgs = parse_brewfile(f.read())

        print_diff(ref_pkgs, target_pkgs, "Current System", target_file)

    else:
        print("❌ Invalid Arguments.")
        print("\nUsage:")
        print(
            "  Compare two files:      python3 brewfile_diff.py <reference_brewfile> <target_brewfile>"
        )
        print("  Compare system vs file: python3 brewfile_diff.py <target_brewfile>")
        sys.exit(1)


if __name__ == "__main__":
    main()
