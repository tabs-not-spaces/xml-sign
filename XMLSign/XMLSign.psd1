@{
    # Module manifest for XMLSign
    RootModule = 'XMLSign.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'XMLSign Team'
    CompanyName = 'Unknown'
    Copyright = '(c) XMLSign Team. All rights reserved.'
    Description = 'PowerShell module for signing XML files using certificates stored in Azure KeyVault'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Required modules
    RequiredModules = @('Az.Accounts', 'Az.KeyVault')
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Sign-XMLDocument',
        'Connect-XMLSignKeyVault'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('XML', 'Signing', 'Azure', 'KeyVault', 'Security')
            LicenseUri = ''
            ProjectUri = 'https://github.com/tabs-not-spaces/xml-sign'
            IconUri = ''
            ReleaseNotes = 'Initial release of XMLSign module'
        }
    }
}