# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

function Write-Log {
    param(
        [string]$Tag,
        [string]$Message,
        [string]$Color = "White"
    )
    $line = "[$Tag] $Message"
    Write-Host $line -ForegroundColor $Color
    if ($State.LogFile) {
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        "$timestamp $line" | Add-Content -Path $State.LogFile -Encoding UTF8
    }
}

function Write-Ok    { Write-Log "OK"     $args[0] "Green" }
function Write-Err   { Write-Log "ERREUR" $args[0] "Red" }
function Write-Info  { Write-Log "INFO"   $args[0] "Cyan" }
function Write-Warn  { Write-Log "WARN"   $args[0] "Yellow" }
function Write-Check { Write-Log "CHECK"  $args[0] "Cyan" }
function Write-Step  { Write-Log "STEP"   $args[0] "Cyan" }

function Die {
    param([string]$Message)
    Write-Err $Message
    exit 1
}