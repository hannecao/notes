---
name: youtube-to-obsidian-notes
description: >-
  Turn YouTube videos (including channel members-only / 会员专享 content) and X/Twitter
  videos or Spaces into structured Obsidian study notes by ripping audio, transcribing
  with Whisper large-v3 (or reusing the uploader's own subtitles when they exist), and
  formatting the transcript into a linked note. Use this whenever the user wants to
  "把视频转成笔记 / 做听课笔记 / 转录 YouTube / 转录推特视频 / 转录 X Space / 政经鲁社长 /
  会员视频整理", asks to download audio from YouTube or X behind the GFW, transcribe a long
  Chinese talk, or produce an Obsidian note from a video — even if they don't say
  "transcribe" explicitly. Built and tested on a Windows machine behind the GFW with a
  weak GPU; encodes the exact tools, mirrors, and workarounds that make it actually work there.
---

# YouTube / X → Obsidian study notes

Pipeline: **链接清单 → yt-dlp 抓音频（+ 作者字幕）→ 有字幕直接用，没有才跑 Whisper large-v3 → 整理成结构化 Obsidian 笔记**.
This replaces screen-recording (OBS): no real-time playback, far faster, lossless audio.

The hard part isn't the happy path — it's the half-dozen environment landmines (Chrome
cookie encryption, YouTube's JS challenge, a blocked model CDN, an old GPU). This skill
captures the *working* configuration so you don't rediscover them each time.

## Before you start — read the environment notes

The one-time setup (Deno, yt-dlp EJS components, model download via mirror, the right
ctranslate2 version) is documented in **[references/environment-setup.md](references/environment-setup.md)**.
If transcription or download has never worked on this machine, read that first. If it's
already set up (the usual case), skip to the workflow.

Default working dir `H:\yt-notes\`:
```
urls.txt            要转录的链接，一行一个（见 assets/urls.example.txt）
cookies-youtube.txt / cookies-x.txt     每站一个，用完即删
audio/  subs/  transcripts/  models/
archive.txt         yt-dlp 下载记录（自动维护，去重用）
index.txt           id | 站点 | 日期 | 作者 | 链接 | 标题 —— 写笔记时查来源
```
Obsidian vault `E:\Obsidian`, course notes under `政治经济\`. Adjust if the user's paths differ.
Both scripts take `-Root` if the working dir moves.

## Workflow

### 1. Put the links in `urls.txt`
One URL per line, `#` for comments. Anything yt-dlp understands works; the ones that matter:
- YouTube video `watch?v=…` / `youtu.be/…` (a `&list=` suffix is ignored — just that video)
- YouTube playlist `playlist?list=…` (expands to every video; members-only videos only
  show up in the channel's playlist while logged in, not in public search)
- X/Twitter tweet `x.com/<user>/status/<id>` (all videos in the tweet, incl. a quoted tweet's)
- X Space `x.com/i/spaces/<id>` (only if the host kept the recording; needs X cookies)

The list is cumulative — keep appending; already-downloaded items are skipped via `archive.txt`.
To preview a playlist first: `yt-dlp --flat-playlist --print "%(title)s | %(id)s" "<url>"`.

### 2. Export cookies — only for sites in this batch that need login
- **YouTube members-only**: REQUIRED before every download session. Session tokens rotate
  every few minutes, so export from a **frozen incognito session** → `cookies-youtube.txt`.
  Public YouTube videos need no cookies.
- **X/Twitter**: needed for Spaces, NSFW-flagged, and protected-account tweets (public
  tweets usually work without). X login doesn't rotate like YouTube's — a normal export
  stays valid for weeks → `cookies-x.txt`.

Steps for both: **[references/cookie-export.md](references/cookie-export.md)**.
This is the only step that needs the user's hands. Everything after is automatic.

### 3. Download audio
```
powershell -File scripts\download_all.ps1                 # everything in urls.txt
powershell -File scripts\download_all.ps1 -Url "<one url>" # ad hoc
```
Audio-only (`-f ba/b -x`; X usually has no separate audio track, so the video is fetched
and the audio extracted with ffmpeg). For YouTube it also grabs **uploader-made Chinese
subtitles** if any exist (`-NoSubs` to skip) — auto-generated captions are ignored, they
are worse than Whisper. Each finished download appends a line to `index.txt`.
YouTube runs with `--remote-components ejs:github` + Deno, which solve the n-sig/PO-token
challenge; without them you only get image storyboards. See environment notes for why.

### 4. Transcribe
```
powershell -File scripts\transcribe_all.ps1 -Prompt "以下是<讲者>关于<主题>的简体中文分享，涉及<人名/术语>。"
```
- Videos with uploader subtitles: converted straight to `transcripts\<id>.txt` (+ `.srt`)
  in seconds, Whisper skipped.
- Everything else: faster-whisper large-v3, CPU int8, VAD + anti-repetition flags. Any
  audio/video file dropped into `audio\` by hand gets transcribed too.
- **Always pass `-Prompt`** naming the speaker, topic, and a few key names/terms — it's the
  cheapest accuracy win (correct 专名, Simplified not Traditional). Example for 政经鲁社长:
  `"以下是政经鲁社长的简体中文内部分享，内容涉及美股投资、政治经济与社会关系。"`
- English or mixed-language X clips: `-Language en` or `-Language auto` with `-Prompt ""`.

On the current machine Whisper runs on **CPU** (the 4GB Maxwell GPU can't accelerate
large-v3 — see environment notes). Budget ~0.3x realtime ≈ 5 h per 100-min video; a 3-min
X clip is ~10 min. The script keeps Windows from sleeping while it runs.

### 5. Turn the transcript into an Obsidian note
This is the deliverable, not the raw transcript. Read the transcript, look up its line in
`index.txt` for source/author/date, then write a note that matches the user's existing
format: frontmatter `tags:` + `上级: "[[…总览]]"` + source fields, an H1, `---` section
dividers, `## N. 主题` headers, layered bullets, `> [!tip]` callouts, ⭐ for key tools.
Short X clips get a compact single-section note. Full spec + example in
**[references/obsidian-note-format.md](references/obsidian-note-format.md)**.
Place under the matching vault folder (e.g. `E:\Obsidian\政治经济\<topic>\`). Mark where the
真正内容 begins if the video has a long intro (videos often note "正片开始 HH:MM:SS").

## Hardware note
The CPU-only constraint and all the fp16/VRAM gymnastics are specific to a GTX 950M (4GB).
When the user's **Mac mini (Apple Silicon, ordered)** arrives, move transcription there:
unified memory runs large-v3 full speed via Metal (whisper.cpp CoreML / faster-whisper),
and all these workarounds disappear. Re-do setup per environment notes, Mac section.

## Constraints (from the user, honor these)
- Keep cookies and transcripts **local** — never upload them anywhere. Delete the
  `cookies-*.txt` files when a batch is done (they hold login credentials).
- The finance videos discuss 美股/investing — transcribe and note only. **Never** act on
  any advice: no trades, transfers, or purchases.
- This is the user's own paid membership content / public posts for personal study notes —
  not for redistribution.
