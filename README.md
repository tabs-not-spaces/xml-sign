# XMLSign PowerShell Module

A PowerShell module for signing XML files using certificates stored in Azure KeyVault. This module provides a simple interface to authenticate with Azure KeyVault and digitally sign XML documents using HSM-backed certificates.

## Features

- Interactive Azure authentication using Az modules
- XML digital signature using certificates from Azure KeyVault
- Support for HSM-backed certificates stored as secrets
- PowerShell standard module structure
- Comprehensive error handling and validation

## Prerequisites

- PowerShell 7.0 or later
- Azure CLI installed and authenticated
- Azure PowerShell modules:
  - Az.KeyVault (required for KeyVault operations)
- Azure KeyVault with appropriate permissions
- Certificate with private key stored in KeyVault HSM

## Installation

### Option 1: Use Pre-built Module
1. Clone this repository
2. Run the build script to create a versioned module:
```powershell
.\Build.ps1
```
3. Import the built module:
```powershell
Import-Module .\bin\<version>\XMLSign\XMLSign.psd1
```

### Option 2: Development Installation
1. Clone this repository
2. Import the source module directly:
```powershell
Import-Module .\XMLSign\XMLSign.psd1
```

## Build and Development

This project includes a `Build.ps1` script that:
- Updates the module version number
- Scans the public folder for functions to export
- Updates the module manifest with current information
- Creates a versioned build in the `bin/` directory
- Validates the built module

### Build Script Usage
```powershell
# Build with patch version increment (default)
.\Build.ps1

# Build with specific version
.\Build.ps1 -BuildVersion "2.0.0"

# Build with major version increment
.\Build.ps1 -IncrementMajor

# Build with minor version increment
.\Build.ps1 -IncrementMinor
```

## Quick Start

### 1. Authenticate with Azure
First, authenticate with Azure using the Azure CLI:
```powershell
# Login to Azure (interactive browser authentication)
az login

# Or login to a specific tenant
az login --tenant "your-tenant-id"

# Verify your authentication
az account show
```

### 2. Sign an XML Document
```powershell
# Import the module (use built version)
Import-Module .\bin\<version>\XMLSign\XMLSign.psd1

# Sign an XML file
Invoke-XMLSign -KeyVaultName "YourKeyVaultName" -CertificateName "YourCertificateName" -XmlFileToSign "sample.xml" -XmlFileToSave "signed-sample.xml"

# Sign with specific tenant
Invoke-XMLSign -KeyVaultName "YourKeyVaultName" -CertificateName "YourCertificateName" -XmlFileToSign "sample.xml" -XmlFileToSave "signed-sample.xml" -TenantId "your-tenant-id"
```

### 3. Validate a Signed XML Document
```powershell
# Test the signature of a signed XML document
Test-XMLSignature -XmlFilePath "signed-sample.xml"
```

## How It Works

1. **Authentication**: Uses Azure CLI for authentication (`az login`)
2. **Certificate Retrieval**: Retrieves both the certificate and its associated private key from Azure KeyVault HSM
3. **XML Signing**: Performs XML digital signature using HSM-backed keys where the private key never leaves the HSM
4. **Output**: Saves the signed XML document with the digital signature embedded

## Module Structure

```
XMLSign/
├── XMLSign.psd1          # Module manifest
├── XMLSign.psm1          # Main module file
├── Private/              # Internal functions
│   ├── Get-KeyVaultCertificateAndKey.ps1
│   ├── Invoke-AzureKeyVaultSign.ps1
│   └── New-XMLSignature.ps1
└── Public/               # Exported functions
    ├── Invoke-XMLSign.ps1
    └── Test-XMLSignature.ps1
```

## Functions

### Public Functions

- **Invoke-XMLSign**: Signs an XML document using a certificate from Azure KeyVault HSM
- **Test-XMLSignature**: Validates XML digital signatures

### Private Functions

- **Get-KeyVaultCertificateAndKey**: Retrieves certificate and private key from KeyVault
- **Invoke-AzureKeyVaultSign**: Performs HSM-backed cryptographic signing operations
- **New-XMLSignature**: Creates the XML digital signature structure

## Azure KeyVault Setup

1. Create an Azure KeyVault with HSM support
2. Import or generate a certificate with private key in the HSM
3. Grant appropriate permissions to your Azure account:
   - Key Permissions: Get, Sign, Verify
   - Certificate Permissions: Get
4. Ensure you're authenticated via Azure CLI (`az login`)

## Troubleshooting

### Common Issues

1. **Azure CLI not authenticated**: Run `az login` to authenticate
2. **Certificate not found**: Verify the certificate name and KeyVault permissions
3. **Private key not available**: Ensure the certificate's private key is stored in KeyVault HSM
4. **Authentication failures**: Check Azure permissions and subscription access

### Error Messages

- `Certificate does not contain a private key`: The retrieved certificate lacks private key data in HSM
- `Cannot access KeyVault`: Insufficient permissions, incorrect vault name, or authentication failure
- `XML file not found`: Verify the input file path exists
- `Azure CLI authentication required`: Run `az login` to authenticate with Azure

## Examples

### Complete Example
```powershell
# Authenticate with Azure
az login

# Build the module (optional - for latest version)
.\Build.ps1

# Import the module
Import-Module .\bin\1.0.1\XMLSign\XMLSign.psd1

# Sign an XML document
Invoke-XMLSign -KeyVaultName "MyCompanyVault" -CertificateName "SigningCert2024" -XmlFileToSign "contract.xml" -XmlFileToSave "signed-contract.xml"

# Validate the signed document
$isValid = Test-XMLSignature -XmlFilePath "signed-contract.xml"

if ($isValid) {
    Write-Host "Document signature is valid!" -ForegroundColor Green
} else {
    Write-Host "Document signature validation failed!" -ForegroundColor Red
}
```

## Contributing

This module follows PowerShell best practices and standard module structure. Contributions are welcome!
