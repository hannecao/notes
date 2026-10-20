# Exporting cookies (YouTube members-only and X/Twitter)

Use the **Get cookies.txt LOCALLY** extension (open-source, local-only) for both sites.

Also note: Chrome 127+ uses **App-Bound Encryption**, so `yt-dlp --cookies-from-browser
chrome` fails with `Failed to decrypt with DPAPI`. You must export to a cookies.txt file
with an extension instead.

Each site gets its own file in `H:\yt-notes\`: `cookies-youtube.txt`, `cookies-x.txt`
(`download_all.ps1` picks the right one per URL; an old plain `cookies.txt` still works
for YouTube). The files hold login credentials — keep them local, and delete them when
the batch is done.

---

## YouTube (required before each members-only download session)

### Why
YouTube's session tokens (`__Secure-3PSIDTS` etc.) **rotate every few minutes**. If you
export cookies while your normal Chrome keeps using the account, the export is invalidated
almost immediately and member videos start failing with *"This video is available to this
channel's members on level: 核心会员"* — even though you ARE a member. The first download may
succeed (token still fresh), then everything fails. The cure is to freeze a session.

Public videos need no cookies at all — skip this if the batch has no member videos.

### Steps (frozen incognito session)
1. Chrome → **Ctrl+Shift+N** for an Incognito window. (Enable the extension in incognito
   first: `chrome://extensions` → that extension → "Allow in Incognito".)
2. In incognito, open `https://www.youtube.com`, **log in** to the member account, and open
   one member video to confirm it plays.
3. Click the extension → **Export** → saves `www.youtube.com_cookies.txt` (usually to
   `Downloads`).
4. Copy it to `H:\yt-notes\cookies-youtube.txt`.
5. **Close the incognito window immediately** and don't touch it again — this freezes the
   session so the tokens stop rotating.

### Verifying it works
```
$env:PATH = "$env:USERPROFILE\.deno\bin;$env:PATH"
yt-dlp --cookies H:\yt-notes\cookies-youtube.txt --no-playlist --remote-components ejs:github `
  -F "https://www.youtube.com/watch?v=<member-video-id>"
```
If you see audio formats listed → good. If "available to members on level …" → the cookie
went stale; re-export with the frozen-incognito method above.

---

## X / Twitter (only when needed)

### When you need it
Public tweets usually download without login. Cookies are needed for **Spaces**,
tweets flagged sensitive/NSFW, protected accounts, and when X starts answering
"login required" / rate-limiting anonymous requests.

### Steps
X's login cookies (`auth_token`, `ct0`) don't rotate every few minutes like YouTube's, so
no incognito trick is needed:
1. In normal Chrome, open `https://x.com` while logged in.
2. Extension → **Export** → `x.com_cookies.txt`.
3. Copy it to `H:\yt-notes\cookies-x.txt`.

It stays valid until you log out of X in that browser (logging out kills `auth_token`) —
typically weeks. If X downloads suddenly fail with login errors, re-export.
Consider a secondary X account for this: the exported file is a full login.

### Verifying it works
```
yt-dlp --cookies H:\yt-notes\cookies-x.txt -F "https://x.com/<user>/status/<id>"
```
Formats listed → good. "NSFW tweet requires authentication" / "login required" → re-export.
