[CmdletBinding()]
param(
    [Parameter()]
    [string]$BuildVersion,

    [Parameter()]
    [switch]$IncrementMajor,

    [Parameter()]
    [switch]$IncrementMinor,

    [Parameter()]
    [switch]$IncrementPatch = $true
)

# Build script for XMLSign PowerShell module
# This script:
# - Updates the version number of the module
# - Scans the public folder for functions to export
# - Updates the psd1 file with updated info
# - Puts the build module into bin/$BuildVersion/$ModuleName

$ErrorActionPreference = 'Stop'

# Define paths
$ModuleName = 'XMLSign'
$SourcePath = Join-Path $PSScriptRoot $ModuleName
$ManifestPath = Join-Path $SourcePath "$ModuleName.psd1"
$PublicPath = Join-Path $SourcePath 'public'

Write-Host "Building module: $ModuleName" -ForegroundColor Green

# Validate source structure
if (-not (Test-Path $SourcePath)) {
    throw "Source module path not found: $SourcePath"
}

if (-not (Test-Path $ManifestPath)) {
    throw "Module manifest not found: $ManifestPath"
}

if (-not (Test-Path $PublicPath)) {
    throw "Public functions path not found: $PublicPath"
}

# Read current manifest
$Manifest = Import-PowerShellDataFile -Path $ManifestPath

# Determine new version
if ($BuildVersion) {
    $NewVersion = [Version]$BuildVersion
    Write-Host "Using specified version: $NewVersion" -ForegroundColor Yellow
} else {
    $CurrentVersion = [Version]$Manifest.ModuleVersion

    if ($IncrementMajor) {
        $NewVersion = [Version]::new($CurrentVersion.Major + 1, 0, 0)
        Write-Host "Incrementing major version: $($CurrentVersion) -> $NewVersion" -ForegroundColor Yellow
    } elseif ($IncrementMinor) {
        $NewVersion = [Version]::new($CurrentVersion.Major, $CurrentVersion.Minor + 1, 0)
        Write-Host "Incrementing minor version: $($CurrentVersion) -> $NewVersion" -ForegroundColor Yellow
    } else {
        # Default to patch increment
        $NewVersion = [Version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build + 1)
        Write-Host "Incrementing patch version: $($CurrentVersion) -> $NewVersion" -ForegroundColor Yellow
    }
}

# Scan public folder for functions
Write-Host "Scanning public functions..." -ForegroundColor Cyan
$PublicFunctions = @()
$PublicFiles = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -File

foreach ($File in $PublicFiles) {
    Write-Host "  Processing: $($File.Name)" -ForegroundColor Gray

    # Read the file content to extract function names
    $Content = Get-Content -Path $File.FullName -Raw

    # Use regex to find function declarations
    $FunctionMatches = [regex]::Matches($Content, '^\s*function\s+([a-zA-Z][\w-]*)', [System.Text.RegularExpressions.RegexOptions]::Multiline)

    foreach ($Match in $FunctionMatches) {
        $FunctionName = $Match.Groups[1].Value
        $PublicFunctions += $FunctionName
        Write-Host "    Found function: $FunctionName" -ForegroundColor Green
    }
}

if ($PublicFunctions.Count -eq 0) {
    Write-Warning "No public functions found in $PublicPath"
}

Write-Host "Found $($PublicFunctions.Count) public function(s) to export" -ForegroundColor Cyan

# Create build output directory
$BuildPath = Join-Path $PSScriptRoot "bin" $NewVersion.ToString() $ModuleName
Write-Host "Creating build directory: $BuildPath" -ForegroundColor Cyan

if (Test-Path $BuildPath) {
    Write-Host "Removing existing build directory..." -ForegroundColor Yellow
    Remove-Item -Path $BuildPath -Recurse -Force
}

$null = New-Item -Path $BuildPath -ItemType Directory -Force

# Copy module files to build directory
Write-Host "Copying module files..." -ForegroundColor Cyan
Copy-Item -Path "$SourcePath\*" -Destination $BuildPath -Recurse -Force

# Update the manifest in the build directory
$BuildManifestPath = Join-Path $BuildPath "$ModuleName.psd1"
Write-Host "Updating module manifest..." -ForegroundColor Cyan

# Read the manifest content as text to preserve formatting
$ManifestContent = Get-Content -Path $BuildManifestPath -Raw

# Update version
$ManifestContent = $ManifestContent -replace "(ModuleVersion\s*=\s*')[^']*(')", "`${1}$($NewVersion.ToString())`${2}"

# Update functions to export
$FunctionsToExportString = ($PublicFunctions | ForEach-Object { "'$_'" }) -join ', '
$ManifestContent = $ManifestContent -replace "(FunctionsToExport\s*=\s*@\()[^)]*(\))", "`${1}$FunctionsToExportString`${2}"

# Update release notes with build info
$BuildDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ReleaseNote = "Version $NewVersion built on $BuildDate"
$ManifestContent = $ManifestContent -replace "(ReleaseNotes\s*=\s*')[^']*(')", "`${1}$ReleaseNote`${2}"

# Write updated manifest
Set-Content -Path $BuildManifestPath -Value $ManifestContent -Encoding UTF8

Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Module version: $NewVersion" -ForegroundColor Green
Write-Host "Build location: $BuildPath" -ForegroundColor Green
Write-Host "Functions exported: $($PublicFunctions -join ', ')" -ForegroundColor Green

# Test the built module
Write-Host "Testing built module..." -ForegroundColor Cyan
try {
    $TestResult = Test-ModuleManifest -Path $BuildManifestPath -ErrorAction Stop
    Write-Host "Module manifest is valid" -ForegroundColor Green
    Write-Host "  Name: $($TestResult.Name)" -ForegroundColor Gray
    Write-Host "  Version: $($TestResult.Version)" -ForegroundColor Gray
    Write-Host "  Exported Functions: $($TestResult.ExportedFunctions.Keys -join ', ')" -ForegroundColor Gray
} catch {
    if ($_.Exception.Message -like "*RequiredModules*") {
        Write-Warning "Module manifest validation skipped - required modules not available in build environment"
        Write-Host "  This is expected in CI/build environments where Az modules may not be installed" -ForegroundColor Gray
    } else {
        Write-Error "Module manifest validation failed: $_"
        throw
    }
}

Write-Host ""
Write-Host "Build Summary:" -ForegroundColor Yellow
Write-Host "  Module: $ModuleName" -ForegroundColor White
Write-Host "  Version: $NewVersion" -ForegroundColor White
Write-Host "  Build Path: $BuildPath" -ForegroundColor White
Write-Host "  Public Functions: $($PublicFunctions.Count)" -ForegroundColor White
Write-Host ""