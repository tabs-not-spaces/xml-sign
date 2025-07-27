function Get-KeyVaultCertificate {
    <#
    .SYNOPSIS
    Retrieves a certificate from Azure KeyVault
    
    .DESCRIPTION
    Gets the certificate and private key data from Azure KeyVault for XML signing
    
    .PARAMETER VaultName
    The name of the Azure KeyVault
    
    .PARAMETER CertificateName
    The name of the certificate in the vault
    
    .EXAMPLE
    Get-KeyVaultCertificate -VaultName "MyVault" -CertificateName "MyCert"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VaultName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName
    )
    
    try {
        Write-Verbose "Retrieving certificate '$CertificateName' from vault '$VaultName'"
        
        # Get the certificate from KeyVault
        $cert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName
        if (-not $cert) {
            throw "Certificate '$CertificateName' not found in vault '$VaultName'"
        }
        
        # Get the secret (private key) associated with the certificate
        $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $CertificateName
        if (-not $secret) {
            throw "Secret for certificate '$CertificateName' not found in vault '$VaultName'"
        }
        
        # Convert the secret value to a certificate with private key
        $secretValue = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
        $secretBytes = [System.Convert]::FromBase64String($secretValue)
        $certWithPrivateKey = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($secretBytes)
        
        return $certWithPrivateKey
    }
    catch {
        Write-Error "Failed to retrieve certificate from KeyVault: $_"
        throw
    }
}