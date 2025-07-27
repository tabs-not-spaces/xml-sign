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
        It "Should import the module successfully" -Skip:(-not $AzModulesAvailable) {
            Get-Module XMLSign | Should -Not -BeNullOrEmpty
        }

        It "Should export the Sign-XMLDocument function" -Skip:(-not $AzModulesAvailable) {
            $commands = Get-Command -Module XMLSign
            $commands.Name | Should -Contain "Sign-XMLDocument"
        }

        It "Should not export Connect-XMLSignKeyVault function" -Skip:(-not $AzModulesAvailable) {
            $commands = Get-Command -Module XMLSign
            $commands.Name | Should -Not -Contain "Connect-XMLSignKeyVault"
        }

        It "Should have exactly two exported functions" -Skip:(-not $AzModulesAvailable) {
            $commands = Get-Command -Module XMLSign
            $commands.Count | Should -Be 2
        }
    }

    Context "Sign-XMLDocument Function" {
        BeforeAll {
            if ($AzModulesAvailable) {
                $function = Get-Command Sign-XMLDocument
            }
        }

        It "Should have the correct parameters" -Skip:(-not $AzModulesAvailable) {
            $parameters = $function.Parameters.Keys
            $parameters | Should -Contain "XmlPath"
            $parameters | Should -Contain "CertificateName"
            $parameters | Should -Contain "VaultName"
            $parameters | Should -Contain "OutputPath"
            $parameters | Should -Contain "ReferenceUri"
        }

        It "Should have mandatory parameters" -Skip:(-not $AzModulesAvailable) {
            $function.Parameters.XmlPath.Attributes.Mandatory | Should -Be $true
            $function.Parameters.CertificateName.Attributes.Mandatory | Should -Be $true
            $function.Parameters.VaultName.Attributes.Mandatory | Should -Be $true
        }

        It "Should have optional parameters" -Skip:(-not $AzModulesAvailable) {
            $function.Parameters.OutputPath.Attributes.Mandatory | Should -Be $false
            $function.Parameters.ReferenceUri.Attributes.Mandatory | Should -Be $false
        }

        It "Should have help documentation" -Skip:(-not $AzModulesAvailable) {
            $help = Get-Help Sign-XMLDocument
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "Should have parameter help" -Skip:(-not $AzModulesAvailable) {
            $help = Get-Help Sign-XMLDocument -Parameter XmlPath
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "Should have examples in help" -Skip:(-not $AzModulesAvailable) {
            $help = Get-Help Sign-XMLDocument
            $help.Examples.Example.Count | Should -BeGreaterThan 0
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
            $manifestContent | Should -Match "'Sign-XMLDocument'"
            $manifestContent | Should -Not -Match "Connect-XMLSignKeyVault"
        }
    }

    Context "Sample XML File" {
        BeforeAll {
            $SampleXmlPath = Join-Path $PSScriptRoot ".." "sample.xml"
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
    }

    Context "Private Functions" {
        It "Should have Get-KeyVaultCertificate private function" {
            $privatePath = Join-Path $PSScriptRoot ".." "XMLSign" "Private" "Get-KeyVaultCertificate.ps1"
            Test-Path $privatePath | Should -Be $true
        }

        It "Should have Invoke-XMLSigning private function" {
            $privatePath = Join-Path $PSScriptRoot ".." "XMLSign" "Private" "Invoke-XMLSigning.ps1"
            Test-Path $privatePath | Should -Be $true
        }

        It "Should not have Connect-XMLSignKeyVault function" {
            $publicPath = Join-Path $PSScriptRoot ".." "XMLSign" "Public" "Connect-XMLSignKeyVault.ps1"
            Test-Path $publicPath | Should -Be $false
        }
    }

    Context "Error Handling" -Skip:(-not $AzModulesAvailable) {
        It "Should throw error for non-existent XML file" {
            { Sign-XMLDocument -XmlPath "C:\NonExistent\file.xml" -CertificateName "TestCert" -VaultName "TestVault" } | Should -Throw
        }

        It "Should validate parameters correctly" {
            { Sign-XMLDocument -XmlPath "" -CertificateName "TestCert" -VaultName "TestVault" } | Should -Throw
            { Sign-XMLDocument -XmlPath "test.xml" -CertificateName "" -VaultName "TestVault" } | Should -Throw
            { Sign-XMLDocument -XmlPath "test.xml" -CertificateName "TestCert" -VaultName "" } | Should -Throw
        }
    }
}