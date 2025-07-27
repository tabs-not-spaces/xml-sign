function New-XMLSignature {
    <#
    .SYNOPSIS
        Creates an XML digital signature using Azure Key Vault.
    
    .DESCRIPTION
        Creates a digital signature for an XML document using the certificate and key from Azure Key Vault.
    
    .PARAMETER XmlDocument
        The XML document to be signed.
    
    .PARAMETER OutputPath
        The path where the signed XML document should be saved.
    
    .PARAMETER Certificate
        The certificate object from Key Vault.
    
    .PARAMETER Key
        The key object from Key Vault.
    
    .PARAMETER KeyVaultName
        The name of the Key Vault.
    
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$XmlDocument,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [object]$Certificate,
        
        [Parameter(Mandatory = $true)]
        [object]$Key,
        
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName
    )
    
    Write-Host "Creating XML signature..." -ForegroundColor Yellow
    
    try {
        # Load required .NET assemblies
        Add-Type -AssemblyName System.Security
        Add-Type -AssemblyName System.Xml
        
        # Create SignedXml object
        $signedXml = New-Object System.Security.Cryptography.Xml.SignedXml($XmlDocument)
        
        # Create reference for the document
        $reference = New-Object System.Security.Cryptography.Xml.Reference("")
        
        # Add enveloped signature transform
        $envelopedTransform = New-Object System.Security.Cryptography.Xml.XmlDsigEnvelopedSignatureTransform
        $reference.AddTransform($envelopedTransform)
        
        # Set digest method to SHA256
        $reference.DigestMethod = "http://www.w3.org/2001/04/xmlenc#sha256"
        
        # Add reference to SignedXml
        $signedXml.AddReference($reference)
        
        # Set signature method to RSA-SHA256
        $signedXml.SignedInfo.SignatureMethod = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
        
        # Add certificate info to KeyInfo
        $keyInfo = New-Object System.Security.Cryptography.Xml.KeyInfo
        $keyInfoData = New-Object System.Security.Cryptography.Xml.KeyInfoX509Data
        
        # Create X509Certificate from the Key Vault certificate
        $x509Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Certificate.Certificate)
        $keyInfoData.AddCertificate($x509Cert)
        $keyInfoData.AddIssuerSerial($x509Cert.Issuer, $x509Cert.SerialNumber)
        
        $keyInfo.AddClause($keyInfoData)
        $signedXml.KeyInfo = $keyInfo
        
        Write-Host "Building digested references..." -ForegroundColor Yellow
        
        # Use reflection to call the internal BuildDigestedReferences method (similar to C# version)
        $buildDigestedReferencesMethod = $signedXml.GetType().GetMethod("BuildDigestedReferences", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        $buildDigestedReferencesMethod.Invoke($signedXml, $null)
        
        Write-Host "Computing signature hash..." -ForegroundColor Yellow
        
        # Get the canonical form of SignedInfo for signing
        $getC14NDigestMethod = $signedXml.GetType().GetMethod("GetC14NDigest", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $signedInfoHash = $getC14NDigestMethod.Invoke($signedXml, @($sha256))
        
        Write-Host "Signing with Azure Key Vault..." -ForegroundColor Yellow
        
        # Sign the hash using Azure Key Vault
        $signature = Invoke-AzureKeyVaultSign -DataToSign $signedInfoHash -KeyVaultName $KeyVaultName -Key $Key -Algorithm "RS256"
        
        # Set the signature value using reflection (accessing private field)
        $signatureField = $signedXml.GetType().GetField("m_signature", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        $signatureObject = $signatureField.GetValue($signedXml)
        $signatureObject.SignatureValue = $signature
        
        # Get the signature XML
        $signatureElement = $signedXml.GetXml()
        
        # Import and append signature to the original document
        $importedSignature = $XmlDocument.ImportNode($signatureElement, $true)
        $XmlDocument.DocumentElement.AppendChild($importedSignature)
        
        # Save the signed document
        $XmlDocument.Save($OutputPath)
        
        Write-Host "✓ XML document signed successfully" -ForegroundColor Green
        Write-Host "✓ Signed document saved to: $OutputPath" -ForegroundColor Green
        
        $sha256.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Failed to create XML signature: $($_.Exception.Message)"
        Write-Host "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
        return $false
    }
}
