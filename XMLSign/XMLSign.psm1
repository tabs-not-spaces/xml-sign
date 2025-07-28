# XMLSign PowerShell Module
# Main module file that loads private and public functions

using namespace System.Security.Cryptography

class AzureKeyVaultRsaKey : RSA {
    hidden [string]$_KeyVaultName
    hidden [object]$_Key
    hidden [string]$_AccessToken

    AzureKeyVaultRsaKey(
        [string]$KeyVaultName,
        [object]$Key,
        [string]$AccessToken) {
        $this._KeyVaultName = $KeyVaultName
        $this._Key = $Key
        $this._AccessToken = $AccessToken
    }

    [byte[]] SignHash(
        [byte[]]$data,
        [HashAlgorithmName]$hashAlgorithm,
        [RSASignaturePadding]$padding
    ) {
        if ($padding -ne [RSASignaturePadding]::Pkcs1) {
            throw "Only PKCS#1 padding is supported"
        }

        $sigAlgo = switch ($hashAlgorithm.Name) {
            "SHA256" { "RS256" }
            "SHA384" { "RS384" }
            "SHA512" { "RS512" }
            default { throw "Unsupported hash algorithm for Azure RSA Key: $($hashAlgorithm.Name)" }
        }

        $signParams = @{
            DataToSign = $data
            KeyVaultName = $this._KeyVaultName
            Key = $this._Key
            AccessToken = $this._AccessToken
            Algorithm = $sigAlgo
        }
        return Invoke-AzureKeyVaultSign @signParams
    }

    # The below is required by the base class but is not used for signing
    [RSAParameters] ExportParameters([bool]$includePrivateParameters) {
        throw [NotImplementedException]"ExportParameters is not implemented for AzureKeyVaultRsaKey"
    }

    [void] ImportParameters([RSAParameters]$parameters) {
        throw [NotImplementedException]"ImportParameters is not implemented for AzureKeyVaultRsaKey"
    }
}


# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        Write-Verbose "Importing $($import.FullName)"
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName