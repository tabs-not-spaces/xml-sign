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

    .PARAMETER AccessToken
        The Azure access token for Key Vault authentication.

    .OUTPUTS
        Boolean indicating success or failure.
    #>

    [CmdletBinding()]
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
        [string]$KeyVaultName,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    Write-Verbose "Creating XML signature..."

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

        # FUTURE: Figure out why $signedXml.SigningKey = $Key.Key.ToRSA() doesn't work
        $azureKey = [AzureKeyVaultRsaKey]::new($KeyVaultName, $Key, $AccessToken)
        $signedXml.SigningKey = $azureKey
        $signedXml.KeyInfo = $keyInfo

        Write-Verbose "Building digested references..."
        $signedXml.ComputeSignature()

        # Get the signature XML
        $signatureElement = $signedXml.GetXml()

        # Import and append signature to the original document
        $importedSignature = $XmlDocument.ImportNode($signatureElement, $true)
        $XmlDocument.DocumentElement.AppendChild($importedSignature)

        # Save the signed document
        $XmlDocument.Save($OutputPath)

        Write-Host "✓ XML document signed successfully" -ForegroundColor Green
        Write-Host "✓ Signed document saved to: $OutputPath" -ForegroundColor Green

        $azureKey.Dispose()

        return $true
    }
    catch {
        Write-Error "Failed to create XML signature: $($_.Exception.Message)"
        Write-Host "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
        return $false
    }
}
