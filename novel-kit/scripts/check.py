"""检查一本书的文件是否超过字数上限，并给最近几章算流水账指标。

用法: python novel-kit/scripts/check.py <书目录> [最近章数，默认 5]
"""
import re
import sys
from pathlib import Path

# 相对书目录的路径（可用通配符） -> 字数上限
CAPS = {
    "样章.md": 2000,
    "00_设定/固定设定.md": 3000,
    "00_设定/人物/*.md": 500,
    "01_规划/细纲/*.md": 1500,
    "02_状态/近况.md": 1500,
}
MAX_OPEN_HOOKS = 15
CONNECTORS = ["然后", "接着", "于是", "随后", "不久", "之后"]
QUOTE = re.compile(r"“[^”]*”|「[^」]*」")


def strip_comments(text):
    return re.sub(r"<!--.*?-->", "", text, flags=re.S)


def char_count(text):
    return len(re.sub(r"\s", "", text))


def prose_stats(text):
    """返回 (字数, 每千字概括词数, 对话占比%)。"""
    text = strip_comments(text)
    n = char_count(text)
    if n == 0:
        return 0, 0.0, 0.0
    conn = sum(text.count(w) for w in CONNECTORS)
    dialogue = sum(char_count(m) for m in QUOTE.findall(text))
    return n, conn * 1000 / n, dialogue * 100 / n


def check_caps(book):
    over = []
    for pattern, cap in CAPS.items():
        for path in sorted(book.glob(pattern)):
            if path.name.startswith("_"):
                continue
            n = char_count(strip_comments(path.read_text(encoding="utf-8")))
            if n > cap:
                over.append((path.relative_to(book), n, cap))
    hooks = book / "02_状态/伏笔账本.md"
    if hooks.exists():
        rows = [l for l in hooks.read_text(encoding="utf-8").splitlines()
                if re.match(r"\|\s*F\d+", l)]
        if len(rows) > MAX_OPEN_HOOKS:
            over.append((hooks.relative_to(book), len(rows), MAX_OPEN_HOOKS))
    return over


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    book = Path(sys.argv[1])
    recent = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    print("== 字数上限 ==")
    over = check_caps(book)
    if not over:
        print("全部在上限内")
    for path, n, cap in over:
        print(f"超限  {path}: {n} / {cap}")

    print("\n== 流水账指标（和样章对比）==")
    print(f"{'文件':<12}{'字数':>8}{'概括词/千字':>12}{'对话占比':>10}")
    rows = []
    sample = book / "样章.md"
    if sample.exists():
        rows.append(("样章", sample))
    chapters = sorted((book / "03_正文").glob("ch*.md"))[-recent:]
    rows += [(p.stem, p) for p in chapters]
    for name, path in rows:
        n, conn, dia = prose_stats(path.read_text(encoding="utf-8"))
        print(f"{name:<12}{n:>8}{conn:>12.1f}{dia:>9.0f}%")


if __name__ == "__main__":
    main()
