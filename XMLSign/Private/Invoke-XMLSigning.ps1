function Invoke-XMLSigning {
    <#
    .SYNOPSIS
    Signs an XML document using the provided certificate
    
    .DESCRIPTION
    Performs XML digital signature using a certificate with private key
    
    .PARAMETER XmlDocument
    The XML document to sign (as XmlDocument object)
    
    .PARAMETER Certificate
    The X509Certificate2 object with private key for signing
    
    .PARAMETER ReferenceUri
    The reference URI for the signature (default: empty string for entire document)
    
    .EXAMPLE
    Invoke-XMLSigning -XmlDocument $doc -Certificate $cert
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$XmlDocument,
        
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        
        [Parameter(Mandatory = $false)]
        [string]$ReferenceUri = ""
    )
    
    try {
        Write-Verbose "Starting XML document signing process"
        
        # Check if certificate has private key
        if (-not $Certificate.HasPrivateKey) {
            throw "Certificate does not contain a private key"
        }
        
        # Create SignedXml object
        $signedXml = New-Object System.Security.Cryptography.Xml.SignedXml($XmlDocument)
        
        # Set the signing key
        $signedXml.SigningKey = $Certificate.PrivateKey
        
        # Create reference
        $reference = New-Object System.Security.Cryptography.Xml.Reference($ReferenceUri)
        
        # Add enveloped signature transform
        $envTransform = New-Object System.Security.Cryptography.Xml.XmlDsigEnvelopedSignatureTransform
        $reference.AddTransform($envTransform)
        
        # Add C14N transform
        $c14nTransform = New-Object System.Security.Cryptography.Xml.XmlDsigC14NTransform
        $reference.AddTransform($c14nTransform)
        
        # Add reference to SignedXml
        $signedXml.AddReference($reference)
        
        # Create KeyInfo and add certificate
        $keyInfo = New-Object System.Security.Cryptography.Xml.KeyInfo
        $keyInfo.AddClause((New-Object System.Security.Cryptography.Xml.KeyInfoX509Data($Certificate)))
        $signedXml.KeyInfo = $keyInfo
        
        # Compute signature
        $signedXml.ComputeSignature()
        
        # Get signature XML element
        $signatureElement = $signedXml.GetXml()
        
        # Append signature to document
        $XmlDocument.DocumentElement.AppendChild($XmlDocument.ImportNode($signatureElement, $true))
        
        Write-Verbose "XML document signed successfully"
        return $XmlDocument
    }
    catch {
        Write-Error "Failed to sign XML document: $_"
        throw
    }
}