[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
$State = @{
    Name         = $Name
    Dir          = ""
    GitLocal     = $false
    GitHub       = $false
    GitHubUrl    = ""
    VsCode       = $false
    DryRun       = $DryRun.IsPresent
    AssumeYes    = $Yes.IsPresent
    ForceGit     = $Git.IsPresent
    ForceGitHub  = $GitHub.IsPresent
    ForcePublic  = $Public.IsPresent
    ForceVsCode  = $VsCode.IsPresent
    ExtensionsDir = $ExtensionsDir
    LogFile      = $LogFile
}