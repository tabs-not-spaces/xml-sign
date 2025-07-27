# XMLSign PowerShell Module

A PowerShell module for signing XML files using certificates stored in Azure KeyVault. This module provides a simple interface to authenticate with Azure KeyVault and digitally sign XML documents using HSM-backed certificates.

## Features

- Interactive Azure authentication using Az modules
- XML digital signature using certificates from Azure KeyVault
- Support for HSM-backed certificates stored as secrets
- PowerShell standard module structure
- Comprehensive error handling and validation

## Prerequisites

- PowerShell 5.1 or later
- Azure PowerShell modules:
  - Az.Accounts (v2.0.0+)
  - Az.KeyVault (v4.0.0+)
- Azure KeyVault with appropriate permissions
- Certificate with private key stored in KeyVault

## Installation

1. Clone this repository
2. Import the module:
```powershell
Import-Module .\XMLSign\XMLSign.psd1
```

## Quick Start

### 1. Connect to Azure KeyVault
```powershell
# Connect with interactive authentication
Connect-XMLSignKeyVault -VaultName "YourKeyVaultName"

# Or specify a subscription
Connect-XMLSignKeyVault -VaultName "YourKeyVaultName" -SubscriptionId "your-subscription-id"
```

### 2. Sign an XML Document
```powershell
# Sign an XML file using the connected vault
Sign-XMLDocument -XmlPath "C:\temp\document.xml" -CertificateName "YourCertificateName"

# Or specify vault name directly
Sign-XMLDocument -XmlPath "C:\temp\document.xml" -CertificateName "YourCertificateName" -VaultName "YourKeyVaultName"

# Specify custom output path
Sign-XMLDocument -XmlPath "C:\temp\document.xml" -CertificateName "YourCertificateName" -OutputPath "C:\temp\signed.xml"
```

## How It Works

1. **Authentication**: Uses Azure PowerShell modules for interactive authentication
2. **Certificate Retrieval**: Retrieves both the certificate and its associated private key secret from KeyVault
3. **XML Signing**: Performs XML digital signature using .NET's SignedXml class
4. **Output**: Saves the signed XML document with the digital signature embedded

## Module Structure

```
XMLSign/
├── XMLSign.psd1          # Module manifest
├── XMLSign.psm1          # Main module file
├── Private/              # Internal functions
│   ├── Get-KeyVaultCertificate.ps1
│   └── Invoke-XMLSigning.ps1
└── Public/               # Exported functions
    ├── Connect-XMLSignKeyVault.ps1
    └── Sign-XMLDocument.ps1
```

## Functions

### Public Functions

- **Connect-XMLSignKeyVault**: Establishes connection to Azure and validates KeyVault access
- **Sign-XMLDocument**: Signs an XML document using a certificate from KeyVault

### Private Functions

- **Get-KeyVaultCertificate**: Retrieves certificate and private key from KeyVault
- **Invoke-XMLSigning**: Performs the actual XML digital signature

## Azure KeyVault Setup

1. Create an Azure KeyVault
2. Import or generate a certificate with private key
3. Ensure the certificate's private key is stored as a secret (this happens automatically for HSM certificates)
4. Grant appropriate permissions to your Azure account:
   - Key Vault Secrets User (to read secrets)
   - Key Vault Certificate User (to read certificates)

## Troubleshooting

### Common Issues

1. **Certificate not found**: Verify the certificate name and KeyVault permissions
2. **Private key not available**: Ensure the certificate's private key is stored as a secret in the vault
3. **Authentication failures**: Check Azure permissions and subscription access

### Error Messages

- `Certificate does not contain a private key`: The retrieved certificate lacks private key data
- `Cannot access KeyVault`: Insufficient permissions or incorrect vault name
- `XML file not found`: Verify the input file path exists

## Examples

### Complete Example
```powershell
# Import the module
Import-Module .\XMLSign\XMLSign.psd1

# Connect to Azure KeyVault
Connect-XMLSignKeyVault -VaultName "MyCompanyVault"

# Sign an XML document
$outputPath = Sign-XMLDocument -XmlPath "C:\Documents\contract.xml" -CertificateName "SigningCert2024"

Write-Host "Document signed and saved to: $outputPath"
```

## Contributing

This module follows PowerShell best practices and standard module structure. Contributions are welcome!
