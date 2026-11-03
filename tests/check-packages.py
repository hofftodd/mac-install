#!/usr/bin/env python3
"""Check every package the install scripts reference against its registry.

Upstream renames and deprecations are the main way these scripts break
without any change in this repo (e.g. pi's npm package moving to a new
name), and most install scripts are too slow to run in CI. This reads the
scripts and asks the registries instead, in a few seconds:

  - Homebrew formulae (`brew install ...`, including tap formulae like
    vitali87/croft/croft) and casks (`cask_install ...`, the Nerd Fonts
    list): must exist and not be deprecated or disabled.
  - Pinned npm packages (`npm_global_install <package> <version>`): the
    package and the pinned version must exist, and the pinned version must
    not be deprecated.

Run from anywhere: python3 tests/check-packages.py
"""
import glob
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
os.chdir(ROOT)

problems = []
checked = {"formula": 0, "cask": 0, "tap formula": 0, "npm": 0}


def fetch(url):
    """GET a URL; returns (status, body). Retries once on network errors."""
    for attempt in (1, 2):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "mac-install-ci"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.status, r.read()
        except urllib.error.HTTPError as e:
            return e.code, b""
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt == 2:
                return None, str(e).encode()
            time.sleep(2)


def scripts():
    for path in sorted(glob.glob("*.sh") + glob.glob("lib/*.sh")):
        with open(path) as f:
            # Join backslash-continued lines so multi-line installs parse.
            yield path, f.read().replace("\\\n", " ")


def literal(token):
    """A plain package name (no options, variables or globs)."""
    token = token.strip("'\"")
    if not token or token.startswith("-") or "$" in token or "*" in token:
        return None
    return token


def defaults(text):
    """VAR="${VAR:-value}" and VAR="value" assignments in a script."""
    found = {}
    for m in re.finditer(r'^\s*([A-Z_][A-Z0-9_]*)="\$\{\1:-([^}"]*)\}"', text, re.M):
        found[m.group(1)] = m.group(2)
    for m in re.finditer(r'^\s*([A-Z_][A-Z0-9_]*)="([^"$]*)"', text, re.M):
        found.setdefault(m.group(1), m.group(2))
    return found


def resolve(token, values):
    token = token.strip("'\"")
    m = re.fullmatch(r"\$\{?([A-Z_][A-Z0-9_]*)\}?", token)
    return values.get(m.group(1)) if m else token


formulae, casks, npm = {}, {}, {}
for path, text in scripts():
    values = defaults(text)
    # Only real commands at the start of a line, not mentions in comments or
    # echo'd tips.
    for m in re.finditer(r"^[ \t]*brew install ([^\n;&|<>#]*)", text, re.M):
        args = m.group(1).split()
        if "--cask" in args:
            continue  # casks go through cask_install
        for tok in args:
            name = literal(tok)
            if name:
                formulae.setdefault(name, path)
    for m in re.finditer(r"^[ \t]*cask_install ([^\s;]+)", text, re.M):
        name = literal(m.group(1))
        if name:
            casks.setdefault(name, path)
    m = re.search(r"FONTS=\(([^)]*)\)", text)
    if m:
        for name in m.group(1).split():
            casks.setdefault(name, path)
    # The default PostgreSQL formula is chosen at run time from a variable.
    for name in re.findall(r"\bpostgresql@\d+\b", text):
        formulae.setdefault(name, path)
    for m in re.finditer(r"^[ \t]*npm_global_install ([^\s;]+) ([^\s;]+)", text, re.M):
        if path == "lib/npm.sh":
            continue  # the helper's own definition
        pkg, version = resolve(m.group(1), values), resolve(m.group(2), values)
        if pkg and version:
            npm[(pkg, version)] = path
        else:
            problems.append(f"{path}: couldn't work out the package/version in: {m.group(0)}")


def brew_api(kind, name, path):
    status, body = fetch(f"https://formulae.brew.sh/api/{kind}/{name}.json")
    if status != 200:
        problems.append(f"{path}: Homebrew {kind} '{name}' not found (HTTP {status})")
        return
    data = json.loads(body)
    if data.get("disabled"):
        problems.append(f"{path}: Homebrew {kind} '{name}' is disabled: {data.get('disable_reason')}")
    elif data.get("deprecated"):
        problems.append(f"{path}: Homebrew {kind} '{name}' is deprecated: {data.get('deprecation_reason')}")
    checked[kind] += 1


for name, path in sorted(formulae.items()):
    parts = name.split("/")
    if len(parts) == 3:  # user/repo/formula → github.com/user/homebrew-repo
        user, repo, formula = parts
        url = f"https://raw.githubusercontent.com/{user}/homebrew-{repo}/HEAD/Formula/{formula}.rb"
        status, _ = fetch(url)
        if status != 200:
            problems.append(f"{path}: tap formula '{name}' not found ({url}, HTTP {status})")
        checked["tap formula"] += 1
    else:
        brew_api("formula", name, path)

for name, path in sorted(casks.items()):
    brew_api("cask", name, path)

for (pkg, version), path in sorted(npm.items()):
    status, body = fetch(f"https://registry.npmjs.org/{pkg.replace('/', '%2F')}")
    if status != 200:
        problems.append(f"{path}: npm package '{pkg}' not found (HTTP {status})")
        continue
    data = json.loads(body)
    info = data.get("versions", {}).get(version)
    if info is None:
        problems.append(f"{path}: npm package '{pkg}' has no version {version}")
    elif info.get("deprecated"):
        problems.append(f"{path}: npm {pkg}@{version} is deprecated: {info['deprecated']}")
    latest = data.get("dist-tags", {}).get("latest")
    latest_info = data.get("versions", {}).get(latest, {})
    if latest_info.get("deprecated") and latest != version:
        problems.append(f"{path}: npm package '{pkg}' is deprecated (latest {latest}): {latest_info['deprecated']}")
    checked["npm"] += 1

print(f"Checked {checked['formula']} formulae, {checked['tap formula']} tap formula(e), "
      f"{checked['cask']} casks, {checked['npm']} pinned npm packages")

# Guard against a parsing change silently checking nothing.
for kind, minimum in (("formula", 20), ("cask", 20), ("npm", 2)):
    if checked[kind] < minimum:
        problems.append(f"only {checked[kind]} {kind} names found (expected at least {minimum}); has the script parsing broken?")

if problems:
    print(f"\n{len(problems)} problem(s):")
    for p in problems:
        print(f"  ✗ {p}")
    sys.exit(1)
print("✓ every referenced package exists and is current")
