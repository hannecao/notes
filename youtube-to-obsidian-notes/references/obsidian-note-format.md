# Obsidian note format

Each video produces **two files** in the vault, side by side:

| 文件 | 内容 | 规则 |
|---|---|---|
| `<标题> · 文字稿.md` | 原汁原味的文字稿：讲者原话，去掉口癖和错误重复，加标点分段，不带时间戳 | 按 SKILL.md 第 5 步整理并用 `check_transcript.py` 校验后，**文件复制**自 `transcripts\<id>.文字稿.md`。 |
| `<标题>.md` | 详细的结构化笔记 | 本文件下面的全部规则。 |

The note links to its 文字稿 (`文字稿: "[[<标题> · 文字稿]]"`), so any claim in the note
can be checked against the speaker's words. **No timestamps** in either file.

Match the user's existing course-note style (observed in `E:\Obsidian\政治经济\社会关系开拓和维护\`).

## The goal: detailed, with the logic visible

The user wants notes **as detailed as possible, organized by the speaker's logic** — not a
summary. Reading the note should give back everything substantive in the talk, in an order
that shows *why* each point follows from the last.

- **Keep, don't compress.** Every argument, example, story, number, name, date, comparison,
  analogy, caveat, and Q&A answer goes in. Only cut what carries no content: filler
  (嗯/那个/就是说), repeated restatements of the same sentence, technical chatter
  ("能听到吗"), ads/sponsor reads, and greetings. When unsure whether something matters, keep it.
- **Logic over chronology.** Talks wander. Sections follow the speaker's *argument*, not
  the order sentences were spoken: if a point made near the end supports a claim from the
  start, it goes under that claim. Digressions with real content get their own
  section near the end, not deleted.
- **Make the reasoning explicit.** For each claim, show: 论点 → 理由/机制 → 例子/数据 →
  结论/推论. If the speaker skips a step, don't invent it — mark it `（讲者未展开）`.
- **Speaker's words, not mine.** Keep the speaker's own terms, framework names, and
  memorable phrasings. Quote verbatim (from the 文字稿) for definitions, key judgments, and
  anything punchy. Don't add outside knowledge or my own opinions to the body; if context
  is genuinely needed, put it in a clearly labeled `> [!note] 补充` callout.
- **No investment advice beyond reporting.** Record what the speaker said about stocks/
  markets as their view (`讲者认为…`), never restated as a recommendation.

## Structure

```markdown
---
tags: [听课笔记, <主题词>, <主题词>]
上级: "[[<专题> · 总览]]"
来源: <链接>
作者: <讲者 / 推特账号>
日期: <发布日期 YYYY-MM-DD>
文字稿: "[[<标题> · 文字稿]]"
---

# <序号/标题，如 ① 九大方法（社长主讲）>

> [!abstract] 一句话
> 这期的核心结论（讲者自己的话优先）。

## 逻辑框架

<全篇论证的骨架，一眼看懂"讲了什么、怎么推出来的"。>

- **核心问题**：这期要回答什么。
- **核心论点**：讲者的答案。
  - **分论点 1**：… → 见 §1
    - 依据：…
  - **分论点 2**：… → 见 §2
    - 依据：…
  - **分论点 3**：…（由 1、2 推出）→ 见 §3
- **结论 / 行动建议**：…

（框架复杂时可加一个 mermaid 流程图，展示论点之间的因果/递进关系。）

---

## 1. <分论点 1> —— <一句话副标题>

**论点**：讲者的主张。

**为什么**：
- **关键词/机制**：解释，保留讲者的推理链。
  - 次级理由；
  - 次级理由。

**例子 / 数据**：
- 具体案例、人名、数字、年份，全部保留。
- 另一个案例。

> 「讲者原话，定义或关键判断。」

**由此得出**：这一节推出了什么，如何接到下一节。

> [!tip] 核心
> 这一节最该记住的一句话。

---

## 2. <分论点 2> …

---

## 问答 / 补充内容
<Q&A、题外话里有实质内容的部分。>

## 关键概念与人物
| 名词 / 人物 | 讲者的解释 |
|---|---|

## 疑问与待查
- 讲者未展开、前后矛盾、或转录听不清的地方（回文字稿核对）。
```

## Detailed rules
- Use `## N. 主题` numbered sections, one per 分论点 in the 逻辑框架; framework bullets
  link to their sections (`→ 见 §N`) so the two stay in sync.
- Bold the **key terms / 关键词**; nest sub-points with indentation.
- `> [!tip] 核心` per section; `> [!warning]` for the speaker's caveats/risks;
  `> [!note] 补充` only for necessary outside context.
- ⭐ to flag the single most important tool/framework in the note.
- Keep everything **Simplified Chinese**, consistent with the source.
- Names/terms already corrected in the 文字稿 (e.g. 巴菲特, 比尔·阿克曼, 标普500) are used
  as-is; if a correction is a guess, write `（转录为"…"，疑为…）`.
- Length follows content: a 100-minute talk typically yields a long note (several thousand
  字). Don't trim to look tidy.
- Fill `来源` / `作者` / `日期` from the video's line in `H:\yt-notes\index.txt`
  (`id | 站点 | 日期 | 作者 | 链接 | 标题`); the 文字稿 uses the same fields.
  Drop a field if it's `NA`.

## Short clips (X/Twitter, < ~10 min)
Same principles, smaller frame. Frontmatter as above (`tags` use `推特` instead of
`听课笔记`; `上级` only if it belongs to a topic). Then: an H1 with the clip's point, one
line of context (who, where, what it replies to/quotes), a short `## 逻辑框架`
(论点 → 依据 → 结论), every substantive point as bullets, and one
`> [!tip] 核心`. Skip the numbered sections only if there's a single line of argument.

## Placement & linking
- Put the note and its 文字稿 in the matching vault folder, e.g. a new `<topic>\` under
  `政治经济\`, parallel to existing topic folders.
- If a topic has multiple episodes, create a `<专题> · 总览.md` MOC that links each episode
  note, and point each note's `上级:` at it (mirror the 社会关系 folder's pattern). The MOC
  can carry a cross-episode 逻辑框架 showing how episodes build on each other.
- If the video has a long intro, the note starts at the 正片.
