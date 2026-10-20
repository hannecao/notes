r"""Check that a cleaned 文字稿 only *removed* things from the raw transcript.

    python check_transcript.py transcripts\<id>.txt transcripts\<id>.文字稿.md

Cleaning may delete fillers and false-start repeats and add punctuation/paragraphs.
It must not reword, summarize, or add. Punctuation and whitespace are ignored; what's left
of the cleaned text should be a subsequence of the raw text. The report lists:
  - every insertion/replacement (should be empty, or only deliberate 专名 fixes)
  - the most common deleted fragments (should be 嗯/啊/那个/就是说/… and stutters)
  - every long deletion (could be a real repeated sentence — or lost content)
"""
import re
import sys
from collections import Counter
from difflib import SequenceMatcher

LONG_DELETION = 12      # chars; longer deletions are listed in full for review
MAX_DELETED_SHARE = 0.35   # heavy-filler speech can legitimately lose ~20–30%


def body(text):
    """Drop YAML frontmatter, headings and callouts from the cleaned markdown."""
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
    return "\n".join(l for l in text.splitlines() if not l.lstrip().startswith(("#", ">")))


def norm(text):
    return "".join(ch.lower() for ch in text if ch.isalnum())


def main(raw_path, clean_path):
    raw = norm(open(raw_path, encoding="utf-8-sig").read())
    clean = norm(body(open(clean_path, encoding="utf-8-sig").read()))
    # Match in raw-line-sized windows would be faster, but whole-text keeps moved
    # paragraphs visible as delete+insert, which is what we want to catch.
    ops = SequenceMatcher(None, raw, clean, autojunk=False).get_opcodes()

    changed, deleted, long_dels = [], Counter(), []
    for tag, i1, i2, j1, j2 in ops:
        if tag == "delete":
            frag = raw[i1:i2]
            deleted[frag] += 1
            if len(frag) >= LONG_DELETION:
                long_dels.append(frag)
        elif tag in ("insert", "replace"):
            ctx = raw[max(0, i1 - 10):i1]
            changed.append(f"  …{ctx}[{raw[i1:i2]} → {clean[j1:j2]}]")

    removed = sum(len(f) * n for f, n in deleted.items())
    share = removed / max(len(raw), 1)
    print(f"raw {len(raw)} chars, cleaned {len(clean)} chars, deleted {removed} ({share:.1%})")
    print(f"\nInsertions/replacements: {len(changed)}")
    print("\n".join(changed) or "  (none)")
    print("\nMost common deletions:")
    print("  " + "  ".join(f"{f}×{n}" for f, n in deleted.most_common(30)))
    print(f"\nLong deletions (≥{LONG_DELETION} chars): {len(long_dels)}")
    for f in long_dels:
        print(f"  - {f}")
    if share > MAX_DELETED_SHARE:
        print(f"\nWARNING: over {MAX_DELETED_SHARE:.0%} deleted — looks like summarizing, not cleaning.")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:3]))
