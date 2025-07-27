# XMLSign Module Usage

The XMLSign PowerShell module has been refactored from the original working example script into a modular structure with separate private and public functions.

## Module Structure

```
XMLSign/
├── XMLSign.psd1           # Module manifest
├── XMLSign.psm1           # Main module file
├── private/               # Private functions (internal use only)
│   ├── Get-KeyVaultCertificateAndKey.ps1
│   ├── Invoke-AzureKeyVaultSign.ps1
│   └── New-XMLSignature.ps1
└── public/                # Public functions (user-facing)
    ├── Invoke-XMLSign.ps1
    └── Test-XMLSignature.ps1
```

## Public Functions

### Invoke-XMLSign
Signs XML documents using Azure Key Vault HSM protected keys.

**Parameters:**
## Parameters

- `KeyVaultName` (Required): The name of the Azure Key Vault (e.g., "yourvault")
- `CertificateName` (Required): The name of the certificate/key stored in the Key Vault  
- `XmlFileToSign` (Required): Path to the XML file that needs to be signed
- `XmlFileToSave` (Required): Path where the signed XML file should be saved
- `TenantId` (Optional): Azure AD Tenant ID

### Test-XMLSignature
Validates XML digital signatures by checking signature structure and certificate presence.

**Parameters:**
- `XmlFilePath` (Required): Path to the XML file to validate

## Usage Examples

### Import the Module
```powershell
Import-Module "./XMLSign/XMLSign.psd1"
```

### Sign an XML Document
```powershell
Invoke-XMLSign -KeyVaultName "yourvault" `
               -CertificateName "mycert" `
               -XmlFileToSign "sample.xml" `
               -XmlFileToSave "signed-sample.xml"
```

### Validate a Signed XML Document
```powershell
Test-XMLSignature -XmlFilePath "signed-sample.xml"
```

### Using the Example Script
The `example-usage.ps1` script demonstrates how to use the module:

```powershell
# Sign an XML document
./example-usage.ps1 -KeyVaultName "yourvault" -CertificateName "mycert" -XmlFileToSign "sample.xml" -XmlFileToSave "signed.xml"

# Validate a signed XML document  
./example-usage.ps1 -ValidateOnlyFile "signed.xml"
```

## Private Functions (Internal Use)

The following functions are used internally by the module and are not exposed to users:

- **Get-KeyVaultCertificateAndKey**: Retrieves certificate and key from Azure Key Vault
- **Invoke-AzureKeyVaultSign**: Signs data using Azure Key Vault HSM
- **New-XMLSignature**: Creates the actual XML digital signature

## Prerequisites

- PowerShell 7.0 or later (enforced by module manifest)
- Azure CLI installed and authenticated (`az login`)
- Az.Accounts and Az.KeyVault PowerShell modules (enforced by module manifest)
- Access to Azure Key Vault with appropriate permissions

## Required Key Vault Permissions

- Key Permissions: Get, Sign, Verify
- Certificate Permissions: Get

## Migration from Working Example

The original `workingexample.ps1` script has been refactored into this modular structure. The main differences are:

1. **Modularity**: Functions are now separated into logical files
2. **Reusability**: Public functions can be imported and used in other scripts
3. **Maintainability**: Private functions are separate from public interface
4. **Error Handling**: Improved error handling and return values
5. **Documentation**: Each function now has proper help documentation

The functionality remains the same, but the code is now better organized and more maintainable.
