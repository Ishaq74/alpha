# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Invoke-Run {
    param([scriptblock]$Command)
    if ($State.DryRun) {
        Write-Info "DRY-RUN: $Command"
        return
    }
    & $Command
}

function Confirm-YesNo {
    param([string]$Prompt)
    if ($State.AssumeYes) { return $true }
    while ($true) {
        $reply = Read-Host "$Prompt (o/N)"
        switch ($reply.ToLower()) {
            { $_ -in "o", "oui", "y", "yes" } { return $true }
            { $_ -in "n", "non", "no", "" }   { return $false }
            default { Write-Info "Réponds par o ou N." }
        }
    }
}

function Test-Command {
    param([string]$Cmd)
    return [bool](Get-Command $Cmd -ErrorAction SilentlyContinue)
}
