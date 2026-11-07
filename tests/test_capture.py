import contextlib
import io
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]


class CaptureTests(unittest.TestCase):
    def setUp(self):
        self.module = runpy.run_path(str(ROOT / "url2org"))
        self.main = self.module["main"]
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dest = Path(self.tmp.name)

    def invoke(self, *args, **mocks):
        stdout = io.StringIO()
        with patch.object(sys, "argv", ["url2org", "https://example.test", "--dir", str(self.dest), *args]), patch.dict(self.main.__globals__, mocks), contextlib.redirect_stdout(stdout):
            self.main()
        return stdout.getvalue().splitlines()

    def test_preserve_org_structure(self):
        samples = [
            "* Eerste\nTekst\n\n** Tweede\nMeer tekst\n",
            "#+begin_src python\nx = 1\ny = 2\nprint('\\\\')\n#+end_src\n",
            "#+BeGiN_Example\neerste\ntweede\n#+EnD_Example\n",
            "- eerste\n  vervolg\n+ tweede\n1) derde\n",
            "| a | b |\n| c | d |\n",
            ":PROPERTIES:\n:SOURCE: https://example.test\n:END:\n",
        ]
        for sample in samples:
            with self.subTest(sample=sample):
                fixed = self.module["softbreak_fix_org"](sample)
                self.assertEqual(sample, fixed)
                self.assertEqual(sample.rstrip("\n"), self.module["fill_wrap_org"](fixed))

    def test_join_only_prose_and_keep_hard_break(self):
        self.assertEqual("Een lange alinea.\n", self.module["softbreak_fix_org"]("Een lange\nalinea.\n"))
        self.assertEqual("Eerste\n\nTweede\n", self.module["softbreak_fix_org"]("Eerste\\\\\nTweede\n"))

    def test_failed_download_writes_nothing(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as caught:
            self.invoke(requests_get=lambda url: "")
        self.assertEqual(4, caught.exception.code)
        self.assertEqual([], list(self.dest.iterdir()))

    def test_empty_extraction_writes_nothing(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as caught:
            self.invoke(requests_get=lambda url: "<html></html>", trafilatura_extract=lambda *a: ("", "", ""), pandoc_to_org_from_html=lambda html: "")
        self.assertEqual(5, caught.exception.code)
        self.assertEqual([], list(self.dest.iterdir()))

    def test_empty_html_fallback_is_empty(self):
        with patch.dict(self.module["pandoc_to_org_from_html"].__globals__, have=lambda cmd: False):
            self.assertEqual("", self.module["pandoc_to_org_from_html"]("<html><body> </body></html>"))

    @unittest.skipUnless(shutil.which("pandoc"), "pandoc required for real format conversion")
    def test_multiple_exports_fetch_and_extract_once(self):
        from unittest.mock import Mock
        fetch = Mock(return_value="<html><title>Artikel</title><body><p>Inhoud.</p></body></html>")
        extract = Mock(return_value=("Inhoud.", "<p>Inhoud.</p>", ""))
        paths = self.invoke("--format", "org", "--format", "markdown", "--format", "docx", "--format", "org", requests_get=fetch, trafilatura_extract=extract)
        fetch.assert_called_once()
        extract.assert_called_once()
        self.assertEqual([".org", ".md", ".docx"], [Path(p).suffix for p in paths])
        self.assertIn("Inhoud.", Path(paths[0]).read_text())
        self.assertIn("Inhoud.", Path(paths[1]).read_text())
        self.assertTrue(Path(paths[2]).read_bytes().startswith(b"PK"))
        again = self.invoke(requests_get=fetch, trafilatura_extract=extract)
        self.assertNotEqual(paths[0], again[0])
        self.assertTrue(Path(paths[0]).exists())

    def test_append_still_works_and_rejects_other_formats(self):
        target = self.dest / "existing.org"
        target.write_text("Bestaand\n")
        mocks = dict(requests_get=lambda url: "<p>Nieuw</p>", trafilatura_extract=lambda *a: ("Nieuw", "<p>Nieuw</p>", ""), pandoc_to_org_from_html=lambda html: "Nieuw\n")
        self.assertEqual([str(target)], self.invoke("--append", str(target), **mocks))
        self.assertIn("Bestaand\n", target.read_text())
        self.assertIn("Nieuw", target.read_text())
        before = target.read_text()
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as caught:
            self.invoke("--append", str(target), "--format", "markdown", **mocks)
        self.assertEqual(2, caught.exception.code)
        self.assertEqual(before, target.read_text())


class FrontendTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.dest = self.base / "Documenten"
        self.dest.mkdir()
        self.cache = self.base / "cache" / "url2org"
        self.cache.mkdir(parents=True)
        self.recent = self.base / "recent"
        self.recent.mkdir()
        (self.cache / "dirs.txt").write_text(f"{self.recent}\n{self.dest}\n")
        self.env = dict(os.environ, HOME=str(self.base), XDG_CACHE_HOME=str(self.base / "cache"), REVIEW_BASE=str(self.base), REVIEW_DEST=str(self.dest), REVIEW_CHOICES="Klaar", REVIEW_FAIL="0", REVIEW_SEARCH="0")
        self.env["PATH"] = str(self.base) + os.pathsep + self.env["PATH"]
        self.script("xdg-user-dir", 'printf "%s\\n" "$REVIEW_DEST"\n')
        self.env["WOFI_BIN"] = str(self.script("menu", '''cat >> "$REVIEW_BASE/menu-input"
count=0
[ ! -f "$REVIEW_BASE/menu-count" ] || read -r count < "$REVIEW_BASE/menu-count"
echo "$((count + 1))" > "$REVIEW_BASE/menu-count"
if [ "$count" -eq 0 ]; then
  if [ "$REVIEW_SEARCH" = 1 ]; then echo '🔎 Zoek andere map'; else echo "$REVIEW_DEST"; fi
elif [ "$REVIEW_SEARCH" = 1 ] && [ "$count" -eq 1 ]; then
  echo "$REVIEW_DEST"
else
  index="$count"
  [ "$REVIEW_SEARCH" != 1 ] || index="$((index - 1))"
  choice="$(printf '%s\\n' "$REVIEW_CHOICES" | sed -n "${index}p")"
  [ "$choice" != CANCEL ] || exit 1
  printf '%s\\n' "$choice"
fi
'''))
        self.env["URL2ORG_BIN"] = str(self.script("backend", '''printf '%s\\n' "$@" >> "$REVIEW_BASE/backend-args"
echo call >> "$REVIEW_BASE/backend-calls"
if [ "$REVIEW_FAIL" = 1 ]; then echo 'Download mislukt: HTTP 403' >&2; exit 4; fi
echo "$REVIEW_DEST/artikel.org"
'''))
        self.env["FD_BIN"] = str(self.script("find-dirs", 'echo search >> "$REVIEW_BASE/search-calls"\necho "$REVIEW_DEST"\n'))
        self.script("notify-send", 'printf "%s\\n" "$@" >> "$REVIEW_BASE/notifications"\n')

    def script(self, name, body):
        path = self.base / name
        path.write_text("#!/usr/bin/env bash\nset -eu\n" + body)
        path.chmod(0o755)
        return path

    def run_frontend(self, **env):
        return subprocess.run(["bash", str(ROOT / "wofi-cap-url2org"), "https://example.test"], env=dict(self.env, **env), text=True, capture_output=True)

    def test_cancel_options_never_captures(self):
        result = self.run_frontend(REVIEW_CHOICES="CANCEL")
        self.assertEqual(130, result.returncode, result.stderr)
        self.assertFalse((self.base / "backend-calls").exists())

    def test_empty_selection_also_cancels(self):
        result = self.run_frontend(REVIEW_CHOICES="")
        self.assertEqual(130, result.returncode, result.stderr)
        self.assertFalse((self.base / "backend-calls").exists())

    def test_recent_maps_without_scan_and_atomic_history(self):
        result = self.run_frontend()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertFalse((self.base / "search-calls").exists())
        self.assertIn(str(self.dest), (self.base / "menu-input").read_text())
        self.assertEqual([str(self.dest), str(self.recent)], (self.cache / "dirs.txt").read_text().splitlines())
        self.assertEqual(["dirs.txt"], [p.name for p in self.cache.iterdir()])

    def test_explicit_search_scans_once(self):
        result = self.run_frontend(REVIEW_SEARCH="1")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(["search"], (self.base / "search-calls").read_text().splitlines())

    def test_history_is_deduplicated_and_limited(self):
        history = [str(self.base / f"map-{i}") for i in range(230)]
        (self.cache / "dirs.txt").write_text("\n".join(history + history) + "\n")
        result = self.run_frontend()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual([str(self.dest), *history[:199]], (self.cache / "dirs.txt").read_text().splitlines())

    def test_multiple_formats_use_one_backend_call(self):
        result = self.run_frontend(REVIEW_CHOICES="[ ] markdown\nKlaar")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(["call"], (self.base / "backend-calls").read_text().splitlines())
        self.assertEqual(["https://example.test", "--dir", str(self.dest), "--format", "org", "--format", "markdown"], (self.base / "backend-args").read_text().splitlines())

    def test_failure_notifies_and_preserves_history(self):
        before = (self.cache / "dirs.txt").read_text()
        result = self.run_frontend(REVIEW_FAIL="1")
        self.assertEqual(1, result.returncode)
        self.assertIn("HTTP 403", result.stderr)
        self.assertIn("HTTP 403", (self.base / "notifications").read_text())
        self.assertNotIn("Opgeslagen", (self.base / "notifications").read_text())
        self.assertEqual(before, (self.cache / "dirs.txt").read_text())


if __name__ == "__main__":
    unittest.main()
