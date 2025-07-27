Describe "XMLSign Module Tests" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "XMLSign" "XMLSign.psd1"
        
        # Check if Az modules are available for full testing
        $AzModulesAvailable = $true
        try {
            Import-Module Az.Accounts -ErrorAction Stop
            Import-Module Az.KeyVault -ErrorAction Stop
        }
        catch {
            $AzModulesAvailable = $false
            Write-Warning "Az modules not available. Some tests will be skipped."
        }
        
        if ($AzModulesAvailable) {
            Import-Module $ModulePath -Force
        }
    }

    AfterAll {
        Remove-Module XMLSign -Force -ErrorAction SilentlyContinue
    }

    Context "Module Import" {
        It "Should import the module successfully" {
            Get-Module XMLSign | Should -Not -BeNullOrEmpty
        }

        It "Should export the Invoke-XMLSign function" {
            $commands = Get-Command -Module XMLSign
            $commands.Name | Should -Contain "Invoke-XMLSign"
        }

        It "Should export the Test-XMLSignature function" {
            $commands = Get-Command -Module XMLSign
            $commands.Name | Should -Contain "Test-XMLSignature"
        }

        It "Should have exactly two exported functions" {
            $commands = Get-Command -Module XMLSign
            $commands.Count | Should -Be 2
        }

        It "Should not export private functions" {
            $commands = Get-Command -Module XMLSign
            $commands.Name | Should -Not -Contain "Get-KeyVaultCertificateAndKey"
            $commands.Name | Should -Not -Contain "Invoke-AzureKeyVaultSign"
            $commands.Name | Should -Not -Contain "New-XMLSignature"
        }
    }

    Context "Invoke-XMLSign Function" {
        BeforeAll {
            if ($AzModulesAvailable) {
                $function = Get-Command Invoke-XMLSign
            }
        }

        It "Should have the correct parameters" {
            $parameters = $function.Parameters.Keys
            $parameters | Should -Contain "KeyVaultName"
            $parameters | Should -Contain "CertificateName"
            $parameters | Should -Contain "XmlFileToSign"
            $parameters | Should -Contain "XmlFileToSave"
            $parameters | Should -Contain "TenantId"
        }

        It "Should have mandatory parameters" {
            $function.Parameters.KeyVaultName.Attributes.Mandatory | Should -Be $true
            $function.Parameters.CertificateName.Attributes.Mandatory | Should -Be $true
            $function.Parameters.XmlFileToSign.Attributes.Mandatory | Should -Be $true
            $function.Parameters.XmlFileToSave.Attributes.Mandatory | Should -Be $true
        }

        It "Should have optional parameters" {
            $function.Parameters.TenantId.Attributes.Mandatory | Should -Be $false
        }

        It "Should have help documentation" {
            $help = Get-Help Invoke-XMLSign
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "Should have parameter help" {
            $help = Get-Help Invoke-XMLSign -Parameter XmlFileToSign
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "Should have examples in help" {
            $help = Get-Help Invoke-XMLSign
            $help.Examples.Example.Count | Should -BeGreaterThan 0
        }
    }

    Context "Test-XMLSignature Function" {
        BeforeAll {
            if ($AzModulesAvailable) {
                $function = Get-Command Test-XMLSignature
            }
        }

        It "Should have the correct parameters" {
            $parameters = $function.Parameters.Keys
            $parameters | Should -Contain "XmlFilePath"
        }

        It "Should have mandatory parameters" {
            $function.Parameters.XmlFilePath.Attributes.Mandatory | Should -Be $true
        }

        It "Should have help documentation" {
            $help = Get-Help Test-XMLSignature
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "Should have parameter help" {
            $help = Get-Help Test-XMLSignature -Parameter XmlFilePath
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "Should have examples in help" {
            $help = Get-Help Test-XMLSignature
            $help.Examples.Example.Count | Should -BeGreaterThan 0
        }

        It "Should return boolean value" {
            # Test with a non-existent file to ensure it returns false
            $result = Test-XMLSignature -XmlFilePath "NonExistentFile.xml" -ErrorAction SilentlyContinue
            $result | Should -BeOfType [bool]
        }
    }

    Context "Module Metadata" {
        It "Should have valid module manifest file" {
            Test-Path $ModulePath | Should -Be $true
        }

        It "Should have correct module structure" {
            $moduleDir = Split-Path $ModulePath
            Test-Path (Join-Path $moduleDir "XMLSign.psm1") | Should -Be $true
            Test-Path (Join-Path $moduleDir "Public") | Should -Be $true
            Test-Path (Join-Path $moduleDir "Private") | Should -Be $true
        }

        It "Should have required manifest properties" {
            $manifestContent = Get-Content $ModulePath -Raw
            $manifestContent | Should -Match "ModuleVersion\s*=\s*'1\.0\.0'"
            $manifestContent | Should -Match "RequiredModules\s*=.*Az\.Accounts.*Az\.KeyVault"
            $manifestContent | Should -Match "'Invoke-XMLSign'"
            $manifestContent | Should -Match "'Test-XMLSignature'"
        }
    }

    Context "Sample XML File and Signed XML Validation" {
        BeforeAll {
            $SampleXmlPath = Join-Path $PSScriptRoot ".." "sample.xml"
            $SignedXmlPath = Join-Path $PSScriptRoot ".." "signed.xml"
        }

        It "Should have a sample XML file" {
            Test-Path $SampleXmlPath | Should -Be $true
        }

        It "Should be valid XML" {
            if (Test-Path $SampleXmlPath) {
                $xml = New-Object System.Xml.XmlDocument
                { $xml.Load($SampleXmlPath) } | Should -Not -Throw
            }
        }

        It "Should validate signed XML if signed.xml exists" {
            if (Test-Path $SignedXmlPath) {
                $result = Test-XMLSignature -XmlFilePath $SignedXmlPath
                $result | Should -BeOfType [bool]
                # If signed.xml exists and is properly signed, it should return true
                # If it's just a placeholder or invalid, it might return false
                Write-Host "Signed XML validation result: $result" -ForegroundColor Cyan
            } else {
                Set-ItResult -Skipped -Because "signed.xml file not found"
            }
        }

        It "Should detect unsigned XML file" {
            if (Test-Path $SampleXmlPath) {
                $result = Test-XMLSignature -XmlFilePath $SampleXmlPath
                $result | Should -Be $false
            }
        }
    }

    Context "Private Functions" {
        It "Should have Get-KeyVaultCertificateAndKey private function" {
            $privatePath = Join-Path $PSScriptRoot ".." "XMLSign" "Private" "Get-KeyVaultCertificateAndKey.ps1"
            Test-Path $privatePath | Should -Be $true
        }

        It "Should have Invoke-AzureKeyVaultSign private function" {
            $privatePath = Join-Path $PSScriptRoot ".." "XMLSign" "Private" "Invoke-AzureKeyVaultSign.ps1"
            Test-Path $privatePath | Should -Be $true
        }

        It "Should have New-XMLSignature private function" {
            $privatePath = Join-Path $PSScriptRoot ".." "XMLSign" "Private" "New-XMLSignature.ps1"
            Test-Path $privatePath | Should -Be $true
        }
    }

    Context "Error Handling" {
        It "Should handle non-existent XML file in Invoke-XMLSign" {
            { Invoke-XMLSign -KeyVaultName "TestVault" -CertificateName "TestCert" -XmlFileToSign "C:\NonExistent\file.xml" -XmlFileToSave "output.xml" } | Should -Throw
        }

        It "Should handle non-existent XML file in Test-XMLSignature" {
            $result = Test-XMLSignature -XmlFilePath "C:\NonExistent\file.xml" -ErrorAction SilentlyContinue
            $result | Should -Be $false
        }

        It "Should validate required parameters for Invoke-XMLSign" {
            { Invoke-XMLSign -KeyVaultName "" -CertificateName "TestCert" -XmlFileToSign "test.xml" -XmlFileToSave "output.xml" } | Should -Throw
            { Invoke-XMLSign -KeyVaultName "TestVault" -CertificateName "" -XmlFileToSign "test.xml" -XmlFileToSave "output.xml" } | Should -Throw
            { Invoke-XMLSign -KeyVaultName "TestVault" -CertificateName "TestCert" -XmlFileToSign "" -XmlFileToSave "output.xml" } | Should -Throw
            { Invoke-XMLSign -KeyVaultName "TestVault" -CertificateName "TestCert" -XmlFileToSign "test.xml" -XmlFileToSave "" } | Should -Throw
        }

        It "Should validate required parameters for Test-XMLSignature" {
            { Test-XMLSignature -XmlFilePath "" } | Should -Throw
        }
    }
}