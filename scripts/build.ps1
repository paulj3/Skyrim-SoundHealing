param(
    [switch]$Deploy,
    [string]$SkyrimRoot = $env:SKYRIM_ROOT
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($SkyrimRoot)) {
    $SkyrimRoot = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition"
}

$DataPath = Join-Path $SkyrimRoot "Data"

$Spriggit = Join-Path $ProjectRoot "tools\Spriggit-0.41.0\Spriggit.CLI.exe"
$PluginSource = Join-Path $ProjectRoot "plugin-src\SoundHealing"

$BuildDir = Join-Path $ProjectRoot "build"
$BuiltPlugin = Join-Path $BuildDir "SoundHealing.esp"
$BuiltScripts = Join-Path $BuildDir "Scripts"

# Package is Data-rooted, so it can be inspected before being deployed.
$PackageData = Join-Path $BuildDir "package\Data"
$PackageScripts = Join-Path $PackageData "Scripts"

$PapyrusCompiler = Join-Path $SkyrimRoot "Papyrus Compiler\PapyrusCompiler.exe"
$VanillaPapyrusSource = Join-Path $DataPath "Source\Scripts"
$ProjectPapyrusSource = Join-Path $ProjectRoot "src\papyrus"
$FlagsFile = Join-Path $VanillaPapyrusSource "TESV_Papyrus_Flags.flg"

$AssetsPath = Join-Path $ProjectRoot "assets"

function Assert-Exists([string]$Path, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description missing: $Path"
    }
}

Write-Host "=== SoundHealing Build ==="
Write-Host "Skyrim root: $SkyrimRoot"

# Validate dependencies before deleting any previous generated output.
Assert-Exists $DataPath "Skyrim Data folder"
Assert-Exists $Spriggit "Spriggit 0.41.0 executable"
Assert-Exists $PluginSource "Serialized plugin source"
Assert-Exists $PapyrusCompiler "Papyrus compiler"
Assert-Exists $VanillaPapyrusSource "Vanilla Papyrus script sources"
Assert-Exists $ProjectPapyrusSource "Project Papyrus script sources"
Assert-Exists $FlagsFile "Papyrus flags file"

$PapyrusFiles = @(Get-ChildItem -LiteralPath $ProjectPapyrusSource -Filter "*.psc" -File | Sort-Object Name)
if ($PapyrusFiles.Count -eq 0) {
    throw "No Papyrus .psc files found in $ProjectPapyrusSource"
}

# Clean only the repository-local generated build directory.
if (Test-Path -LiteralPath $BuildDir) {
    Remove-Item -LiteralPath $BuildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $BuiltScripts -Force | Out-Null
New-Item -ItemType Directory -Path $PackageScripts -Force | Out-Null

Write-Host ""
Write-Host "Deserializing SoundHealing.esp from YAML..."
& $Spriggit deserialize `
    --InputPath $PluginSource `
    --OutputPath $BuiltPlugin `
    --DataFolder $DataPath

if ($LASTEXITCODE -ne 0) {
    throw "Spriggit build failed with exit code $LASTEXITCODE"
}
Assert-Exists $BuiltPlugin "Generated ESP"

Write-Host ""
Write-Host "Compiling Papyrus..."
foreach ($Script in $PapyrusFiles) {
    Write-Host "Compiling $($Script.Name)..."

    Push-Location $ProjectPapyrusSource
    try {
        & $PapyrusCompiler `
            $Script.Name `
            "-i=$VanillaPapyrusSource;$ProjectPapyrusSource" `
            "-o=$BuiltScripts" `
            "-f=$FlagsFile"

        if ($LASTEXITCODE -ne 0) {
            throw "Papyrus compilation failed: $($Script.Name) (exit $LASTEXITCODE)"
        }
    }
    finally {
        Pop-Location
    }
}

$CompiledScripts = @(Get-ChildItem -LiteralPath $BuiltScripts -Filter "*.pex" -File)
if ($CompiledScripts.Count -lt $PapyrusFiles.Count) {
    throw "Expected at least $($PapyrusFiles.Count) compiled PEX files, found $($CompiledScripts.Count)"
}

Write-Host ""
Write-Host "Staging installable Data tree..."
Copy-Item -LiteralPath $BuiltPlugin -Destination (Join-Path $PackageData "SoundHealing.esp") -Force
Copy-Item -Path (Join-Path $BuiltScripts "*.pex") -Destination $PackageScripts -Force

if (Test-Path -LiteralPath $AssetsPath) {
    Copy-Item -Path (Join-Path $AssetsPath "*") -Destination $PackageData -Recurse -Force
}

Write-Host ""
Write-Host "=== BUILD SUCCESSFUL ==="
Write-Host "Plugin: $BuiltPlugin"
Write-Host "Staged Data tree: $PackageData"

if (-not $Deploy) {
    Write-Host "Not deployed. Run with -Deploy to overwrite matching files in Skyrim Data."
    return
}

Write-Host ""
Write-Host "Deploying staged files to $DataPath"
Write-Warning "Deployment overwrites matching Data files; back up installed mod files or use a mod manager before deploying."
Copy-Item -Path (Join-Path $PackageData "*") -Destination $DataPath -Recurse -Force

Write-Host "=== DEPLOY SUCCESSFUL ==="
