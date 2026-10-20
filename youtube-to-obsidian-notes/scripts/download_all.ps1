# Batch download audio for every URL in urls.txt (YouTube videos/playlists, X/Twitter
# tweets, X Spaces). Idempotent via yt-dlp's download archive: re-running skips anything
# already downloaded, so you can keep appending URLs to the same list.
#
#   powershell -File download_all.ps1                      # uses <Root>\urls.txt
#   powershell -File download_all.ps1 -Url https://x.com/user/status/123...
param(
    [string]$Root = "H:\yt-notes",
    [string]$List = "",            # default: <Root>\urls.txt
    [string[]]$Url = @(),          # ad-hoc URLs instead of / in addition to the list
    [string]$SubLangs = "zh.*",    # YouTube manual subtitles to grab (lets transcribe skip Whisper)
    [switch]$NoSubs
)
$ErrorActionPreference = 'Continue'
$env:PATH = (Join-Path $env:USERPROFILE ".deno\bin") + ";" + $env:PATH
if (-not $List) { $List = "$Root\urls.txt" }
$audioDir = "$Root\audio"
$subsDir  = "$Root\subs"
$archive  = "$Root\archive.txt"     # yt-dlp download archive ("youtube <id>", "twitter <id>")
$index    = "$Root\index.txt"       # id | site | date | author | url | title, for writing notes
New-Item -ItemType Directory -Force -Path $audioDir, $subsDir | Out-Null

# One-time migration: audio downloaded by the old hardcoded script has no archive entry.
# Seed it from YouTube-shaped filenames (11-char ids) so those aren't downloaded again.
$known = if (Test-Path $archive) { Get-Content $archive } else { @() }
Get-ChildItem $audioDir -File | Where-Object { $_.BaseName -match '^[\w-]{11}$' -and $_.Extension -ne '.part' } |
    ForEach-Object { if ("youtube $($_.BaseName)" -notin $known) { Add-Content $archive "youtube $($_.BaseName)" } }

if (-not (Test-Path $index)) {
    Add-Content $index "id | site | date | author | url | title" -Encoding utf8
}

$urls = @($Url)
if (Test-Path $List) {
    $urls += Get-Content $List -Encoding utf8 | ForEach-Object { ($_ -replace '(^|\s)#.*$', '').Trim() } | Where-Object { $_ }
}
if (-not $urls) { Write-Host "No URLs. Put one per line in $List or pass -Url."; exit 1 }

# Separate cookie files per site: YouTube's must come from a frozen incognito session,
# X's can be exported from a normal window. YouTube falls back to the old single cookies.txt.
function Get-Cookies([string]$site) {
    $files = @("$Root\cookies-$site.txt")
    if ($site -eq "youtube") { $files += "$Root\cookies.txt" }
    foreach ($f in $files) { if (Test-Path $f) { return $f } }
    return $null
}

foreach ($u in $urls) {
    $isX = $u -match '^https?://(www\.|mobile\.)?(x|twitter)\.com/'
    $site = if ($isX) { "x" } else { "youtube" }
    $opts = @(
        "--no-playlist",                       # watch?v=..&list=.. -> just that video; pure playlist URLs still expand
        "--download-archive", $archive,
        "-f", "ba/b", "-x",                    # audio only; X often has no audio-only stream, so extract from video
        "--no-progress",
        "-o", "$audioDir/%(id)s.%(ext)s",
        "--print-to-file", "after_move:%(id)s | %(extractor_key)s | %(upload_date>%Y-%m-%d)s | %(uploader)s | %(webpage_url)s | %(title)s", $index
    )
    $c = Get-Cookies $site
    if ($c) { $opts += "--cookies", $c }
    if ($isX) {
        if (-not $c) { Write-Host "[WARN] no cookies-x.txt: NSFW/protected tweets and Spaces will fail" }
    } else {
        $opts += "--remote-components", "ejs:github"   # YouTube n-sig/PO-token challenge (needs Deno)
        if (-not $NoSubs) {
            # Manual (uploader-made) subtitles only; auto-captions are worse than Whisper.
            $opts += "--write-subs", "--sub-langs", $SubLangs, "--convert-subs", "srt",
                     "-o", "subtitle:$subsDir/%(id)s.%(ext)s"
        }
    }
    Write-Host "[DL]   $u"
    yt-dlp @opts $u 2>&1 |
        Where-Object { $_ -match 'ERROR|WARNING: .*(members|login|cookies)|Destination|already been recorded' } |
        Select-Object -Last 5
}
Write-Host "==== ALL DOWNLOADS COMPLETE ===="
Get-ChildItem $audioDir -File | Where-Object { $_.Extension -ne '.part' } | Sort-Object LastWriteTime |
    Select-Object -Last 20 | ForEach-Object { "{0}  {1} MB" -f $_.Name, [math]::Round($_.Length/1MB,1) }
