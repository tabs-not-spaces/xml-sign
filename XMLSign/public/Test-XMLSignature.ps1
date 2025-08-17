function Test-XMLSignature {
    <#
    .SYNOPSIS
        Validates XML digital signatures.

    .DESCRIPTION
        Validates the digital signature of an XML document, checking signature structure,
        certificate presence, and other signature elements.

    .PARAMETER XmlFilePath
        Path to the XML file to validate

    .EXAMPLE
        # Validate a signed XML document
        Test-XMLSignature -XmlFilePath "signed-sample.xml"

    .NOTES
        This function performs structural validation of the XML signature including:
        - Signature element presence
        - SignedInfo element validation
        - SignatureValue validation
        - KeyInfo and certificate validation

        Note: Full cryptographic verification requires the signing environment or compatible verification tools.

    .OUTPUTS
        Boolean indicating if the signature validation passed or failed.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlFilePath
    )

    if (-not (Test-Path $XmlFilePath)) {
        Write-Error "XML file not found: $XmlFilePath"
        return $false
    }

    Write-Host "Validating XML document: $XmlFilePath" -ForegroundColor Cyan
    Write-Verbose "Validating XML signature..."

    try {
        # Load XML document
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.Load($XmlFilePath)

        # Find signature elements
        $signatures = $xmlDoc.GetElementsByTagName("Signature")

        if ($signatures.Count -eq 0) {
            Write-Host "✗ No signature found in the XML document" -ForegroundColor Red
            return $false
        }

        if ($signatures.Count -gt 1) {
            Write-Host "✗ Multiple signatures found in the XML document" -ForegroundColor Red
            return $false
        }

        $signatureElement = $signatures[0]

        # Check required elements
        $signedInfo = $signatureElement.SelectSingleNode("*[local-name()='SignedInfo']")
        $signatureValue = $signatureElement.SelectSingleNode("*[local-name()='SignatureValue']")
        $keyInfo = $signatureElement.SelectSingleNode("*[local-name()='KeyInfo']")

        if (-not $signedInfo) {
            Write-Host "✗ SignedInfo element not found" -ForegroundColor Red
            return $false
        }

        if (-not $signatureValue -or [string]::IsNullOrWhiteSpace($signatureValue.InnerText)) {
            Write-Host "✗ SignatureValue element not found or empty" -ForegroundColor Red
            return $false
        }

        if (-not $keyInfo) {
            Write-Host "✗ KeyInfo element not found" -ForegroundColor Red
            return $false
        }

        # Check for certificate in KeyInfo
        $x509Data = $keyInfo.SelectSingleNode("*[local-name()='X509Data']")
        $x509Certificate = $x509Data.SelectSingleNode("*[local-name()='X509Certificate']")

        if (-not $x509Certificate -or [string]::IsNullOrWhiteSpace($x509Certificate.InnerText)) {
            Write-Host "✗ X509Certificate not found in KeyInfo" -ForegroundColor Red
            return $false
        }

        Write-Host "✓ Signature structure validation: PASSED" -ForegroundColor Green
        Write-Host "✓ Certificate presence validation: PASSED" -ForegroundColor Green
        Write-Host "✓ All required signature elements found" -ForegroundColor Green

        # Try to extract certificate information
        try {
            $certBytes = [Convert]::FromBase64String($x509Certificate.InnerText)
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certBytes)
            Write-Host "Certificate Subject: $($cert.Subject)" -ForegroundColor Cyan
            Write-Host "Certificate Issuer: $($cert.Issuer)" -ForegroundColor Cyan
            Write-Host "Certificate Valid From: $($cert.NotBefore)" -ForegroundColor Cyan
            Write-Host "Certificate Valid To: $($cert.NotAfter)" -ForegroundColor Cyan
        }
        catch {
            Write-Warning "Could not parse certificate details: $($_.Exception.Message)"
        }

        Write-Host "Note: Full cryptographic verification requires the signing environment or compatible verification tools." -ForegroundColor Yellow
        Write-Host "✓ XML signature validation completed successfully" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Error "Signature validation failed: $($_.Exception.Message)"
        Write-Host "✗ XML signature validation failed" -ForegroundColor Red
        return $false
    }
}
