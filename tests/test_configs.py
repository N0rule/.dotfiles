#!/usr/bin/env python3
"""Offline parsing and PiP IPC regression checks; never touches the desktop."""
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile
import tomllib
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    loader = importlib.machinery.SourceFileLoader(
        name, str(ROOT / ".config/niri/scripts" / name))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class ConfigTests(unittest.TestCase):
    def test_structured_configs(self):
        for path in (ROOT / ".config").rglob("*.toml"):
            with self.subTest(path=path):
                tomllib.loads(path.read_text())
        for path in (ROOT / ".config/noctalia").glob("*.json"):
            json.loads(path.read_text())
        for path in (ROOT / ".config").rglob("tmtheme.xml"):
            plistlib.loads(path.read_bytes())

    def test_snap_only_matches_brave_pip(self):
        snap = load("pip-snap")
        data = {"outputs": {}, "workspaces": [], "windows": [
            {"id": 1, "app_id": "other", "title": "Picture-in-Picture"},
            {"id": 2, "app_id": "brave-origin", "title": "Picture-in-Picture", "is_floating": True},
        ]}
        with patch.object(snap, "query", side_effect=lambda key: data[key]), \
                patch.object(snap, "niri") as ipc, patch("sys.argv", ["pip-snap"]):
            self.assertEqual(snap.main(), 0)
        self.assertEqual(ipc.call_count, 2)
        self.assertTrue(all(call.args[3] == "2" for call in ipc.call_args_list))

    def test_follow_events_without_focus_steal(self):
        follow = load("pip-follow")
        events = [
            {"WindowsChanged": {"windows": [
                {"id": 9, "app_id": "brave-origin", "title": "Picture-in-Picture", "workspace_id": 1, "is_floating": True}]}},
            {"WorkspacesChanged": {"workspaces": [
                {"id": 1, "idx": 1, "is_focused": True}, {"id": 2, "idx": 2}]}},
            {"WorkspaceActivated": {"id": 2, "focused": False}},
            {"WorkspaceActivated": {"id": 2, "focused": True}},
            {"WorkspaceActivated": {"id": 2, "focused": True}},
        ]
        class Stream:
            stdout = io.StringIO("\n".join(map(json.dumps, events)))
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def poll(self): return 0
            def wait(self): return 0
        with tempfile.TemporaryDirectory() as cache, \
                patch.dict("os.environ", {"XDG_CACHE_HOME": cache}), \
                patch.object(follow.subprocess, "Popen", return_value=Stream()), \
                patch.object(follow.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as ipc:
            self.assertEqual(follow.main(), 0)
        ipc.assert_called_once()
        self.assertEqual(ipc.call_args.args[0][-3:], ["--focus", "false", "2"])


if __name__ == "__main__":
    unittest.main()
