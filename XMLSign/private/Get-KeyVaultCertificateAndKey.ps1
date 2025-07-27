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
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName
    )
    
    Write-Verbose "Retrieving certificate and key from Key Vault..."
    
    try {
        # Get certificate
        $certificate = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName -ErrorAction Stop
        Write-Verbose "Retrieved certificate: $CertificateName"
        
        # Get key
        $key = Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $CertificateName -ErrorAction Stop
        Write-Verbose "Retrieved key: $CertificateName"
        
        return @{
            Certificate = $certificate
            Key         = $key
        }
    }
    catch {
        Write-Error "Failed to retrieve certificate/key '$CertificateName' from Key Vault '$KeyVaultName': $($_.Exception.Message)"
        return $null
    }
}
