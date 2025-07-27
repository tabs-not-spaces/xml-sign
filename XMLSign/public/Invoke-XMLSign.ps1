function Invoke-XMLSign {
    <#
    .SYNOPSIS
        Signs XML documents using Azure Key Vault HSM protected keys.

    .DESCRIPTION
        This function signs XML documents using keys stored in Azure Key Vault HSM, where the private key
        never leaves the HSM. Authentication is handled via Azure CLI (az login).

    .PARAMETER KeyVaultName
        The name of the Azure Key Vault (e.g., "yourvault")

    .PARAMETER CertificateName
        The name of the certificate/key stored in the Key Vault

    .PARAMETER XmlFileToSign
        Path to the XML file that needs to be signed

    .PARAMETER XmlFileToSave
        Path where the signed XML file should be saved

    .PARAMETER TenantId
        Azure AD Tenant ID (optional, uses default if not specified)

    .EXAMPLE
        # Sign an XML document
        Invoke-XMLSign -KeyVaultName "yourvault" -CertificateName "mycert" -XmlFileToSign "sample.xml" -XmlFileToSave "signed-sample.xml"

    .EXAMPLE
        # Sign an XML document with specific tenant
        Invoke-XMLSign -KeyVaultName "yourvault" -CertificateName "mycert" -XmlFileToSign "sample.xml" -XmlFileToSave "signed-sample.xml" -TenantId "your-tenant-id"

    .NOTES
        Prerequisites:
        - PowerShell 7.0 or later
        - Azure CLI installed and authenticated (az login)
        - Az.KeyVault PowerShell module
        - Access to Azure Key Vault with appropriate permissions
        
        Required Key Vault Permissions:
        - Key Permissions: Get, Sign, Verify
        - Certificate Permissions: Get

        Author: Generated from C# cli-exakvdocsign application
        Version: 1.0
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName,
        
        [Parameter(Mandatory = $true)]
        [string]$XmlFileToSign,
        
        [Parameter(Mandatory = $true)]
        [string]$XmlFileToSave,
        
        [Parameter(Mandatory = $false)]
        [string]$TenantId
    )
    
    try {
        # Set tenant context if TenantId is provided
        if ($TenantId) {
            try {
                az account set --subscription (az account list --query "[?tenantId=='$TenantId'].id" -o tsv)
                Write-Host "✓ Set tenant context: $TenantId" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not set tenant context. Continuing with current context."
            }
        }
        
        # Get certificate and key from Key Vault
        $keyVaultAssets = Get-KeyVaultCertificateAndKey -KeyVaultName $KeyVaultName -CertificateName $CertificateName
        if (-not $keyVaultAssets) {
            throw "Failed to retrieve certificate and key from Key Vault '$KeyVaultName' for certificate '$CertificateName'"
        }
        
        # Load XML document
        Write-Host "Loading XML document..." -ForegroundColor Yellow
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.PreserveWhitespace = $true
        
        if (-not (Test-Path $XmlFileToSign)) {
            throw "XML file not found: $XmlFileToSign"
        }
        
        $xmlDoc.Load($XmlFileToSign)
        Write-Host "✓ XML document loaded: $XmlFileToSign" -ForegroundColor Green
        
        # Sign the document
        $result = New-XMLSignature -XmlDocument $xmlDoc -OutputPath $XmlFileToSave -Certificate $keyVaultAssets.Certificate -Key $keyVaultAssets.Key -KeyVaultName $KeyVaultName
        
        if (-not $result) {
            throw "XML document signing failed"
        }
        
        Write-Host ""
        Write-Host "✓ XML document signing completed successfully!" -ForegroundColor Green
        Write-Host "Signed document saved to: $XmlFileToSave" -ForegroundColor Cyan
    }
    catch {
        throw "Failed to sign XML document: $($_.Exception.Message)"
    }
}
