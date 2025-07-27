# XMLSign Module Test Script
# This script tests the XMLSign module functionality

Write-Host "Testing XMLSign PowerShell Module" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Test 1: Module Import
Write-Host "`n1. Testing module import..." -ForegroundColor Yellow
try {
    Import-Module .\XMLSign\XMLSign.psd1 -Force
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
    
    $commands = Get-Command -Module XMLSign
    Write-Host "✓ Found $($commands.Count) exported commands:" -ForegroundColor Green
    foreach ($cmd in $commands) {
        Write-Host "  - $($cmd.Name)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "✗ Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Help Documentation
Write-Host "`n2. Testing help documentation..." -ForegroundColor Yellow
try {
    $help = Get-Help Sign-XMLDocument -ErrorAction Stop
    if ($help.Synopsis) {
        Write-Host "✓ Help documentation available" -ForegroundColor Green
    }
    else {
        Write-Host "✗ No help synopsis found" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Failed to get help: $_" -ForegroundColor Red
}

# Test 3: Sample XML Validation
Write-Host "`n3. Testing sample XML file..." -ForegroundColor Yellow
if (Test-Path "sample.xml") {
    try {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load("sample.xml")
        Write-Host "✓ Sample XML file is valid" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Sample XML file is invalid: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "✗ Sample XML file not found" -ForegroundColor Red
}

# Test 4: Function Parameter Validation
Write-Host "`n4. Testing function parameters..." -ForegroundColor Yellow
try {
    $params = (Get-Command Sign-XMLDocument).Parameters
    $requiredParams = @('XmlPath', 'CertificateName')
    $hasRequired = $true
    
    foreach ($required in $requiredParams) {
        if (-not $params.ContainsKey($required)) {
            Write-Host "✗ Missing required parameter: $required" -ForegroundColor Red
            $hasRequired = $false
        }
    }
    
    if ($hasRequired) {
        Write-Host "✓ All required parameters found" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Failed to validate parameters: $_" -ForegroundColor Red
}

Write-Host "`nTesting completed!" -ForegroundColor Cyan
Write-Host "`nTo use this module with Azure KeyVault:" -ForegroundColor Yellow
Write-Host "1. Install Az.Accounts and Az.KeyVault modules" -ForegroundColor Gray
Write-Host "2. Run: Connect-XMLSignKeyVault -VaultName 'YourVaultName'" -ForegroundColor Gray
Write-Host "3. Run: Sign-XMLDocument -XmlPath 'path\to\file.xml' -CertificateName 'YourCert'" -ForegroundColor Gray