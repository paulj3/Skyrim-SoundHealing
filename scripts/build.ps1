$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$SkyrimRoot = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition"
$DataPath = Join-Path $SkyrimRoot "Data"

$Spriggit = Join-Path $ProjectRoot "tools\Spriggit-0.41.0\Spriggit.CLI.exe"

$PluginSource = Join-Path $ProjectRoot "plugin-src\SoundHealing"

$BuildDir = Join-Path $ProjectRoot "build"
$BuiltPlugin = Join-Path $BuildDir "SoundHealing.esp"
$BuiltScripts = Join-Path $BuildDir "Scripts"

$PapyrusCompiler = Join-Path $SkyrimRoot "Papyrus Compiler\PapyrusCompiler.exe"
$VanillaPapyrusSource = Join-Path $DataPath "Source\Scripts"
$ProjectPapyrusSource = Join-Path $ProjectRoot "src\papyrus"
$FlagsFile = Join-Path $VanillaPapyrusSource "TESV_Papyrus_Flags.flg"

Write-Host "=== SoundHealing Build ==="

# ------------------------------------------------------------
# Clean build directory
# ------------------------------------------------------------

if (Test-Path $BuildDir) {
    Remove-Item $BuildDir -Recurse -Force
}

New-Item -ItemType Directory -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Path $BuiltScripts | Out-Null


# ------------------------------------------------------------
# Build ESP from Spriggit YAML
# ------------------------------------------------------------

Write-Host ""
Write-Host "Building SoundHealing.esp from YAML..."

& $Spriggit deserialize `
    --InputPath $PluginSource `
    --OutputPath $BuiltPlugin `
    --DataFolder $DataPath

if ($LASTEXITCODE -ne 0) {
    throw "Spriggit build failed."
}


# ------------------------------------------------------------
# Compile Papyrus
# ------------------------------------------------------------

Write-Host ""
Write-Host "Compiling Papyrus..."

$PapyrusFiles = Get-ChildItem $ProjectPapyrusSource -Filter *.psc

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
            throw "Papyrus compilation failed: $($Script.Name)"
        }

    }
    finally {
        Pop-Location
    }
}


# ------------------------------------------------------------
# Deploy plugin
# ------------------------------------------------------------

Write-Host ""
Write-Host "Deploying SoundHealing.esp..."

Copy-Item `
    $BuiltPlugin `
    (Join-Path $DataPath "SoundHealing.esp") `
    -Force


# ------------------------------------------------------------
# Deploy compiled Papyrus scripts
# ------------------------------------------------------------

Write-Host "Deploying Papyrus scripts..."

Copy-Item `
    (Join-Path $BuiltScripts "*") `
    (Join-Path $DataPath "Scripts") `
    -Force


# ------------------------------------------------------------
# Deploy assets
# ------------------------------------------------------------

$AssetsPath = Join-Path $ProjectRoot "assets"

if (Test-Path $AssetsPath) {

    Write-Host "Deploying assets..."

    Copy-Item `
        (Join-Path $AssetsPath "*") `
        $DataPath `
        -Recurse `
        -Force
}


# ------------------------------------------------------------
# Success
# ------------------------------------------------------------

Write-Host ""
Write-Host "=== BUILD AND DEPLOY SUCCESSFUL ==="
Write-Host ""
Write-Host "Generated plugin:"
Write-Host $BuiltPlugin
Write-Host ""
Write-Host "Deployed plugin:"
Write-Host (Join-Path $DataPath "SoundHealing.esp")