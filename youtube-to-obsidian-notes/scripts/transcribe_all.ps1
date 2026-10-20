# Batch transcribe everything in <Root>\audio with local faster-whisper (large-v3, CPU int8).
# Idempotent: skips audio whose transcript already exists.
# If download_all.ps1 grabbed uploader-made Chinese subtitles for a video, those are used
# directly and Whisper is skipped for it (seconds instead of hours).
# Output is the raw transcript (<id>.txt); cleaning out fillers/repeats into the 文字稿 is
# a separate step (see SKILL.md), checked with check_transcript.py.
#
#   powershell -File transcribe_all.ps1 -Prompt "以下是政经鲁社长的简体中文内部分享，内容涉及美股投资、政治经济与社会关系。"
#   powershell -File transcribe_all.ps1 -Language en -Prompt ""
param(
    [string]$Root     = "H:\yt-notes",
    [string]$Model    = "",          # model folder; default <Root>\models\faster-whisper-large-v3
    [string]$Device   = "cpu",       # GPU(950M) can't run large-v3 -> CPU. Mac/newer GPU: change this
    [string]$Compute  = "int8",
    [int]$Threads     = 8,
    [string]$Language = "zh",        # "auto" = let Whisper detect (mixed-language X clips)
    [string]$Prompt   = "以下是普通话的内容，使用简体中文。",  # name the speaker/topic for better terms
    [switch]$NoSubs                  # ignore downloaded subtitles, always run Whisper
)
$ErrorActionPreference = 'Continue'
if (-not $Model) { $Model = "$Root\models\faster-whisper-large-v3" }
$audioDir = "$Root\audio"
$subsDir  = "$Root\subs"
$outDir   = "$Root\transcripts"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Keep the machine awake for multi-hour CPU runs; cleared automatically when this process exits.
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
[Win32.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null   # ES_CONTINUOUS | ES_SYSTEM_REQUIRED

# Subtitle language preference: Simplified first, then any other Chinese track.
function Find-Subtitle([string]$id) {
    if ($NoSubs -or -not (Test-Path $subsDir)) { return $null }
    $subs = Get-ChildItem $subsDir -File -Filter "$id.*.srt"
    foreach ($lang in "zh-Hans", "zh-CN", "zh", "zh-SG") {
        $hit = $subs | Where-Object { $_.Name -eq "$id.$lang.srt" -or $_.Name -like "$id.$lang-*.srt" } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $subs | Select-Object -First 1
}

# SRT cue texts, in order. Text is kept as-is except formatting tags like <i>;
# multi-line cues are joined with a space.
function Read-Srt([string]$srt) {
    $blocks = (Get-Content $srt -Raw -Encoding utf8) -split '\r?\n\s*\r?\n'
    foreach ($b in $blocks) {
        $lines = @($b -split '\r?\n')
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*\d+:\d\d:\d\d[,.]\d+\s+-->') {
                $text = (@($lines[($i + 1)..($lines.Count - 1)]) | Where-Object { $_.Trim() } |
                    ForEach-Object { ($_ -replace '<[^>]+>', '').Trim() }) -join ' '
                if ($i + 1 -lt $lines.Count -and $text) { $text }
                break
            }
        }
    }
}

$exts = '.webm', '.m4a', '.opus', '.mp3', '.aac', '.ogg', '.wav', '.flac', '.mp4', '.mkv', '.mov'
$audios = Get-ChildItem $audioDir -File | Where-Object { $_.Extension -in $exts } | Sort-Object Name
foreach ($a in $audios) {
    $id  = $a.BaseName
    $txt = Join-Path $outDir "$id.txt"
    $srt = Join-Path $outDir "$id.srt"
    $sub = Find-Subtitle $id

    if (Test-Path $txt) {
        Write-Host "[SKIP] $id (transcript exists)"
    } elseif ($sub) {
        Copy-Item $sub.FullName $srt
        Set-Content $txt (Read-Srt $srt) -Encoding utf8
        Write-Host "[SUBS] $id  <- $($sub.Name) (uploader subtitles, Whisper skipped)"
    } else {
        Write-Host "[TRANSCRIBE] $id  ($([math]::Round($a.Length/1MB,0)) MB) ..."
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $opts = @(
            "--model_directory", $Model, "--device", $Device, "--compute_type", $Compute, "--threads", $Threads,
            "--output_dir", $outDir, "--output_format", "all",
            "--vad_filter", "True", "--condition_on_previous_text", "False"
        )
        if ($Language -ne "auto") { $opts += "--language", $Language }
        if ($Prompt) { $opts += "--initial_prompt", $Prompt }
        whisper-ctranslate2 $a.FullName @opts
        $sw.Stop()
        Write-Host ("[DONE] {0} in {1} min" -f $id, [math]::Round($sw.Elapsed.TotalMinutes,1))
    }
}
Write-Host "==== ALL TRANSCRIPTIONS COMPLETE ===="
