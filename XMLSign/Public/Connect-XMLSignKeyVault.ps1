function Connect-XMLSignKeyVault {
    <#
    .SYNOPSIS
    Establishes connection to Azure and validates KeyVault access
    
    .DESCRIPTION
    Connects to Azure using interactive authentication and validates access to the specified KeyVault
    
    .PARAMETER VaultName
    The name of the Azure KeyVault to connect to
    
    .PARAMETER SubscriptionId
    Optional Azure subscription ID
    
    .EXAMPLE
    Connect-XMLSignKeyVault -VaultName "MyKeyVault"
    
    .EXAMPLE
    Connect-XMLSignKeyVault -VaultName "MyKeyVault" -SubscriptionId "12345678-1234-1234-1234-123456789012"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VaultName,
        
        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId
    )
    
    try {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        
        # Check if already connected
        $context = Get-AzContext
        if (-not $context) {
            # Connect to Azure interactively
            if ($SubscriptionId) {
                Connect-AzAccount -SubscriptionId $SubscriptionId
            }
            else {
                Connect-AzAccount
            }
        }
        else {
            Write-Host "Already connected to Azure as $($context.Account.Id)" -ForegroundColor Green
        }
        
        # Validate KeyVault access
        Write-Host "Validating access to KeyVault '$VaultName'..." -ForegroundColor Yellow
        
        try {
            $vault = Get-AzKeyVault -VaultName $VaultName
            if ($vault) {
                Write-Host "Successfully connected to KeyVault '$VaultName'" -ForegroundColor Green
                
                # Store connection info in module context
                $script:XMLSignContext.VaultName = $VaultName
                $script:XMLSignContext.VaultUri = $vault.VaultUri
                $script:XMLSignContext.Connected = $true
                
                return $true
            }
        }
        catch {
            throw "Cannot access KeyVault '$VaultName'. Please verify the vault name and your permissions."
        }
    }
    catch {
        Write-Error "Failed to connect to Azure KeyVault: $_"
        $script:XMLSignContext.Connected = $false
        throw
    }
}