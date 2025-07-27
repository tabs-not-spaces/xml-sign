function Get-KeyVaultCertificateAndKey {
    <#
    .SYNOPSIS
        Retrieves certificate and key from Azure Key Vault.
    
    .DESCRIPTION
        Gets the certificate and corresponding key from the specified Azure Key Vault.
    
    .PARAMETER KeyVaultName
        The name of the Key Vault.
    
    .PARAMETER CertificateName
        The name of the certificate/key stored in the Key Vault.
    
    .OUTPUTS
        Hashtable containing Certificate and Key objects, or $null if failed.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName
    )
    
    Write-Host "Retrieving certificate and key from Key Vault..." -ForegroundColor Yellow
    
    try {
        # Get certificate
        $certificate = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName -ErrorAction Stop
        Write-Host "✓ Retrieved certificate: $CertificateName" -ForegroundColor Green
        
        # Get key
        $key = Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $CertificateName -ErrorAction Stop
        Write-Host "✓ Retrieved key: $CertificateName" -ForegroundColor Green
        
        return @{
            Certificate = $certificate
            Key = $key
        }
    }
    catch {
        Write-Error "Failed to retrieve certificate/key '$CertificateName' from Key Vault '$KeyVaultName': $($_.Exception.Message)"
        return $null
    }
}
