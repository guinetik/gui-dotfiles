#Requires -Version 7
<#
.SYNOPSIS
    Claude Code hook: sound + toast + taskbar flash when Claude wants you back.

.DESCRIPTION
    Two triggers, two Prince of Persia potions:

      ask   Claude is blocked on a question or permission  -> small potion
      done  Claude finished the turn                       -> big potion

    Three signals fire per trigger, each independently optional:

      sound   ffplay, hidden and detached. No ffmpeg -> silent skip.
      toast   BurntToast. Lands in the Action Center regardless of which
              window has focus, which is why it earns its place next to the
              flash. Visual only: a plain toast cannot focus the terminal
              without a registered COM activator.
      flash   FlashWindowEx on the terminal window. The taskbar button flashes
              until the window comes to the foreground, and clicking it takes
              you there. Note the corollary: if the terminal is ALREADY
              foreground, Windows flashes nothing. That is the toast's job.

    The idle filter. Claude Code's Notification hook fires for two different
    situations: Claude actually needs you (a permission prompt), and the input
    box having sat untouched for 60 seconds. Only the first is a question.
    Without filtering, the question potion plays 61 seconds after every single
    turn ends, which is how this was found. So on 'ask' we read the hook
    payload and stay quiet when the message is the idle one.

    That is the only reason this script reads stdin, and the only reason it is
    carved into begin/process/end -- pipeline input does not reliably reach a
    plain script body. Fail open throughout: if the payload is missing or
    unparseable, the potion plays. A missed notification is a worse failure
    than a spurious one.

    Nothing here is allowed to fail a turn. Every signal is wrapped, and the
    script always exits 0.

.PARAMETER Trigger
    'ask' or 'done'. Named Trigger rather than Event because $Event is a
    PowerShell automatic variable.

.PARAMETER Test
    Also print what was found (ffplay, BurntToast, the window it flashed), so
    you can run this by hand and see which of the three signals are live.

.EXAMPLE
    Wire into ~/.claude/settings.json -- this repo deliberately does not
    symlink settings.json, see windows/links.psv:

      "hooks": {
        "Notification": [
          { "hooks": [ { "type": "command",
            "command": "pwsh -NoProfile -File D:/Developer/gui-dotfiles/powershell/claude-notify.ps1 -Trigger ask" } ] }
        ],
        "Stop": [
          { "hooks": [ { "type": "command",
            "command": "pwsh -NoProfile -File D:/Developer/gui-dotfiles/powershell/claude-notify.ps1 -Trigger done" } ] }
        ]
      }

    Set CLAUDE_NOTIFY_LOG to a file path to record every invocation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('ask', 'done')]
    [string]$Trigger,

    [switch]$Test,

    # The hook's event JSON, delivered on stdin one line per pipeline object.
    [Parameter(ValueFromPipeline)]
    [string]$HookJson
)

begin { }

# Runs once with an empty value: under `pwsh -File` PowerShell does not feed
# stdin into the script pipeline, it just binds one empty object. The block
# exists so that object has somewhere to land instead of becoming a stderr
# binding error, and so the real read below happens in a proper end block.
process { }

end {
    # Repo-relative, so the sounds travel with the dotfiles instead of
    # depending on whatever happens to be sitting in ~/Music. See
    # ai/claude/sounds/README.md for where they came from.
    $SOUNDS = Join-Path $PSScriptRoot '..' 'ai' 'claude' 'sounds'

    $profiles = @{
        ask  = @{
            Sound = Join-Path $SOUNDS 'PrinceOfPersiaSNESPotion.mp3'
            Title = 'Claude is waiting'
            Body  = 'A question or a permission prompt needs you.'
        }
        done = @{
            Sound = Join-Path $SOUNDS 'PrinceOfPersiaSNESBigPotion.mp3'
            Title = 'Claude is done'
            Body  = 'The turn finished. Nothing is blocked.'
        }
    }
    $p = $profiles[$Trigger]

    function Write-Diag($msg) { if ($Test) { Write-Host $msg } }

    # ─── parse the hook payload ──────────────────────────────────────────────
    # The parameter above never receives this; Console.In does. The
    # IsInputRedirected guard matters: without it, a hand-run of this script
    # from an interactive console would block forever waiting on a terminal
    # that is never going to send EOF.
    $message = ''
    if ([Console]::IsInputRedirected) {
        try {
            $raw = [Console]::In.ReadToEnd()
            if ($raw.Trim()) {
                $message = [string](($raw | ConvertFrom-Json).message ?? '')
            }
        } catch {
            Write-Diag "payload: unparseable, treating as absent - $_"
        }
    }
    Write-Diag "payload: message=[$message]"

    # ─── idle filter ─────────────────────────────────────────────────────────
    # Claude Code's idle notification reads "Claude is waiting for your input".
    # A permission prompt reads "Claude needs your permission to use <tool>".
    # Match the idle one narrowly and let everything else through: an unknown
    # message means we notify, because silence is the worse failure.
    $isIdle = $Trigger -eq 'ask' -and $message -match 'waiting for your input'

    # ─── diagnostic log ──────────────────────────────────────────────────────
    if ($env:CLAUDE_NOTIFY_LOG) {
        try {
            $parent = (Get-Process -Id $PID -ErrorAction SilentlyContinue).Parent
            $line = '{0} trigger={1}{2} pid={3} ppid={4}({5}) msg="{6}"' -f @(
                (Get-Date -Format 'HH:mm:ss.fff'),
                $Trigger,
                $(if ($isIdle) { ' SKIPPED(idle)' } else { '' }),
                $PID,
                ($parent.Id ?? '?'),
                ($parent.ProcessName ?? '?'),
                ($message -replace '\s+', ' ')
            )
            Add-Content -LiteralPath $env:CLAUDE_NOTIFY_LOG -Value $line -Encoding utf8
        } catch { }
    }

    if ($isIdle) {
        Write-Diag 'idle notification, staying quiet'
        exit 0
    }

    # ─── 1. sound ────────────────────────────────────────────────────────────
    # ffplay because SoundPlayer is WAV-only and these are mp3s. Hidden window,
    # no wait: the hook must return immediately.
    try {
        $ffplay = (Get-Command ffplay -ErrorAction SilentlyContinue).Source
        if (-not $ffplay) {
            Write-Diag 'sound: ffplay not on PATH, skipping'
        } elseif (-not (Test-Path -LiteralPath $p.Sound)) {
            Write-Diag "sound: missing $($p.Sound), skipping"
        } else {
            Start-Process -FilePath $ffplay -WindowStyle Hidden `
                -ArgumentList '-nodisp', '-autoexit', '-loglevel', 'quiet', '-i', $p.Sound
            Write-Diag "sound: $ffplay -> $((Resolve-Path -LiteralPath $p.Sound).Path)"
        }
    } catch {
        Write-Diag "sound: failed - $_"
    }

    # ─── 2. toast ────────────────────────────────────────────────────────────
    # -Silent because Windows' own notification ding would step on the potion.
    try {
        if (Get-Module -ListAvailable -Name BurntToast) {
            Import-Module BurntToast -ErrorAction Stop
            New-BurntToastNotification -Text $p.Title, $p.Body -Silent
            Write-Diag 'toast: sent via BurntToast'
        } else {
            Write-Diag 'toast: BurntToast not installed, skipping'
        }
    } catch {
        Write-Diag "toast: failed - $_"
    }

    # ─── 3. taskbar flash ────────────────────────────────────────────────────
    if (-not ('Gui.Dotfiles.WindowFlash' -as [type])) {
        Add-Type -Namespace 'Gui.Dotfiles' -Name 'WindowFlash' -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct FLASHWINFO {
    public uint cbSize;
    public IntPtr hwnd;
    public uint dwFlags;
    public uint uCount;
    public uint dwTimeout;
}

[DllImport("user32.dll")]
private static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

// FLASHW_ALL (3) | FLASHW_TIMERNOFG (12): flash caption and taskbar button,
// and keep flashing until the window comes to the foreground.
public static bool Flash(IntPtr hwnd) {
    FLASHWINFO fi = new FLASHWINFO();
    fi.cbSize = (uint)Marshal.SizeOf(typeof(FLASHWINFO));
    fi.hwnd = hwnd;
    fi.dwFlags = 15;
    fi.uCount = uint.MaxValue;
    fi.dwTimeout = 0;
    return FlashWindowEx(ref fi);
}
'@
    }

    # Walk up the process tree until something owns a window. The chain is
    # pwsh (this) -> claude -> shell -> terminal host, but the exact depth
    # depends on how Claude Code was launched, so walk rather than assume.
    function Find-TerminalWindow {
        $proc = Get-Process -Id $PID -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt 8 -and $proc; $i++) {
            if ($proc.MainWindowHandle -ne [IntPtr]::Zero) { return $proc }
            $proc = $proc.Parent
        }
        # Fallback for launch paths where the parent chain is broken.
        Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
            Select-Object -First 1
    }

    try {
        $win = Find-TerminalWindow
        if ($win) {
            [Gui.Dotfiles.WindowFlash]::Flash($win.MainWindowHandle) | Out-Null
            Write-Diag "flash: $($win.ProcessName) (pid $($win.Id), hwnd $($win.MainWindowHandle))"
        } else {
            Write-Diag 'flash: no window found in the parent chain, skipping'
        }
    } catch {
        Write-Diag "flash: failed - $_"
    }

    exit 0
}
