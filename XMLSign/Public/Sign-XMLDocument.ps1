function Sign-XMLDocument {
    <#
    .SYNOPSIS
    Signs an XML document using a certificate stored in Azure KeyVault
    
    .DESCRIPTION
    Signs the specified XML document using a certificate retrieved from Azure KeyVault.
    The certificate's private key must be stored as a secret in the vault.
    
    .PARAMETER XmlPath
    Path to the XML file to sign
    
    .PARAMETER CertificateName
    Name of the certificate in Azure KeyVault
    
    .PARAMETER VaultName
    Name of the Azure KeyVault (optional if already connected via Connect-XMLSignKeyVault)
    
    .PARAMETER OutputPath
    Path where the signed XML file will be saved (optional, defaults to input path with .signed.xml extension)
    
    .PARAMETER ReferenceUri
    Reference URI for the XML signature (optional, defaults to signing entire document)
    
    .EXAMPLE
    Sign-XMLDocument -XmlPath "C:\temp\document.xml" -CertificateName "MyCert" -VaultName "MyVault"
    
    .EXAMPLE
    Connect-XMLSignKeyVault -VaultName "MyVault"
    Sign-XMLDocument -XmlPath "C:\temp\document.xml" -CertificateName "MyCert"
    
    .EXAMPLE
    Sign-XMLDocument -XmlPath "C:\temp\document.xml" -CertificateName "MyCert" -VaultName "MyVault" -OutputPath "C:\temp\signed.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName,
        
        [Parameter(Mandatory = $false)]
        [string]$VaultName,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$ReferenceUri = ""
    )
    
    try {
        # Validate input file exists
        if (-not (Test-Path $XmlPath)) {
            throw "XML file not found: $XmlPath"
        }
        
        # Determine vault name
        if (-not $VaultName) {
            if ($script:XMLSignContext.Connected -and $script:XMLSignContext.VaultName) {
                $VaultName = $script:XMLSignContext.VaultName
                Write-Verbose "Using connected vault: $VaultName"
            }
            else {
                throw "VaultName parameter is required when not connected via Connect-XMLSignKeyVault"
            }
        }
        
        # Determine output path
        if (-not $OutputPath) {
            $fileInfo = Get-Item $XmlPath
            $OutputPath = Join-Path $fileInfo.Directory "$($fileInfo.BaseName).signed.xml"
        }
        
        Write-Host "Loading XML document from: $XmlPath" -ForegroundColor Yellow
        
        # Load XML document
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.Load($XmlPath)
        
        Write-Host "Retrieving certificate '$CertificateName' from KeyVault '$VaultName'..." -ForegroundColor Yellow
        
        # Get certificate from KeyVault
        $certificate = Get-KeyVaultCertificate -VaultName $VaultName -CertificateName $CertificateName
        
        Write-Host "Signing XML document..." -ForegroundColor Yellow
        
        # Sign the XML document
        $signedDoc = Invoke-XMLSigning -XmlDocument $xmlDoc -Certificate $certificate -ReferenceUri $ReferenceUri
        
        Write-Host "Saving signed document to: $OutputPath" -ForegroundColor Yellow
        
        # Save signed document
        $signedDoc.Save($OutputPath)
        
        Write-Host "XML document signed successfully!" -ForegroundColor Green
        Write-Host "Signed file saved to: $OutputPath" -ForegroundColor Green
        
        return $OutputPath
    }
    catch {
        Write-Error "Failed to sign XML document: $_"
        throw
    }
}