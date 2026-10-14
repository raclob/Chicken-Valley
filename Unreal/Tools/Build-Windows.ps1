param(
    [Parameter(Mandatory = $true)][string]$EngineRoot,
    [switch]$Package
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $projectRoot 'ChickenValley.uproject'
$buildScript = Join-Path $EngineRoot 'Engine/Build/BatchFiles/Build.bat'
if (!(Test-Path $buildScript)) { throw 'EngineRoot must point to the installed UE_5.8 directory.' }
if ($Package -and !(Test-Path (Join-Path $projectRoot 'Content/Maps/FarmValley.umap'))) {
    throw 'Open the editor and run Tools/Bootstrap.py before packaging. See Unreal/README.md.'
}
& $buildScript ChickenValleyEditor Win64 Development "-Project=$projectPath" -WaitMutex
if ($LASTEXITCODE -ne 0) { throw "Unreal editor build failed ($LASTEXITCODE). Check the build output." }
if ($Package) {
    $automation = Join-Path $EngineRoot 'Engine/Build/BatchFiles/RunUAT.bat'
    $output = Join-Path $projectRoot 'Builds/Windows'
    & $automation BuildCookRun "-project=$projectPath" -noP4 -platform=Win64 -clientconfig=Development -build -cook -allmaps -stage -pak -archive "-archivedirectory=$output" -utf8output
    if ($LASTEXITCODE -ne 0) { throw "Unreal Windows packaging failed ($LASTEXITCODE)." }
    Write-Host "Packaged game is in $output"
} else {
    $editor = Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe'
    Start-Process -FilePath $editor -ArgumentList "`"$projectPath`""
}
