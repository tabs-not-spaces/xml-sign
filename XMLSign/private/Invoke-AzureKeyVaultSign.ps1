function Invoke-AzureKeyVaultSign {
    <#
    .SYNOPSIS
        Signs data using Azure Key Vault HSM.
    
    .DESCRIPTION
        Sends data to Azure Key Vault for signing using the HSM-protected private key.
    
    .PARAMETER DataToSign
        The byte array of data to be signed.
    
    .PARAMETER KeyVaultName
        The name of the Key Vault.
    
    .PARAMETER Key
        The Key Vault key object.
    
    .PARAMETER Algorithm
        The signing algorithm to use (default: RS256).
    
    .PARAMETER AccessToken
        The Azure access token for Key Vault authentication.
    
    .OUTPUTS
        Byte array containing the signature.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$DataToSign,
        
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName,
        
        [Parameter(Mandatory = $true)]
        [object]$Key,
        
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        
        [Parameter(Mandatory = $false)]
        [string]$Algorithm = "RS256"
    )
    
    try {
        Write-Verbose "Sending hash to Azure Key Vault for signing..."
        
        # Convert byte array to base64 for REST API
        $base64Hash = [Convert]::ToBase64String($DataToSign)
        
        # Prepare the REST API call
        $keyVersion = $Key.Version
        $signUrl = "https://$KeyVaultName.vault.azure.net/keys/$($Key.Name)/$keyVersion/sign?api-version=7.3"
        
        $headers = @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type"  = "application/json"
        }
        
        $body = @{
            alg   = $Algorithm
            value = $base64Hash
        } | ConvertTo-Json
        
        Write-Verbose "Calling Key Vault REST API: $signUrl"
        
        # Make the REST API call
        $response = Invoke-RestMethod -Uri $signUrl -Method POST -Headers $headers -Body $body
        
        if ($response -and $response.value) {
            Write-Verbose "Successfully received signature from Key Vault"
            
            # Convert base64 result back to bytes - handle URL-safe base64 format from Azure Key Vault
            $base64Value = $response.value
            # Replace URL-safe base64 characters with standard base64 characters
            $base64Value = $base64Value.Replace('-', '+').Replace('_', '/')
            # Add padding if necessary (base64 strings must be multiple of 4 characters)
            while ($base64Value.Length % 4 -ne 0) {
                $base64Value += '='
            }
            
            return [Convert]::FromBase64String($base64Value)
        }
        else {
            throw "No signature value returned from Azure Key Vault"
        }
    }
    catch {
        Write-Error "Failed to sign data with Azure Key Vault: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseText = $reader.ReadToEnd()
            Write-Host "Response details: $responseText" -ForegroundColor Red
        }
        throw
    }
}
