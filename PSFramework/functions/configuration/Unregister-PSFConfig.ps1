﻿function Unregister-PSFConfig
{
<#
	.SYNOPSIS
		Removes registered configuration settings.
	
	.DESCRIPTION
		Removes registered configuration settings.
		This function can be used to remove settings that have been persisted for either user or computer.
	
		Note: This command has no effect on configuration setings currently in memory.
	
	.PARAMETER ConfigurationItem
		A configuration object as returned by Get-PSFConfig.
	
	.PARAMETER FullName
		The full name of the configuration setting to purge.
	
	.PARAMETER Module
		The module, amongst which settings should be unregistered.
	
	.PARAMETER Name
		The name of the setting to unregister.
		For use together with the module parameter, to limit the amount of settings that are unregistered.
	
	.PARAMETER Scope
		Settings can be set to either default or enforced, for user or the entire computer.
		By default, only DefaultSettings for the user are unregistered.
		Use this parameter to choose the actual scope for the command to process.
	
	.EXAMPLE
		PS C:\> Get-PSFConfig | Unregister-PSFConfig
	
		Completely removes all registered configurations currently loaded in memory.
		In most cases, this will mean removing all registered configurations.
	
	.EXAMPLE
		PS C:\> Unregister-PSFConfig -Scope SystemDefault -FullName 'MyModule.Path.DefaultExport'
	
		Unregisters the setting 'MyModule.Path.DefaultExport' from the list of computer-wide defaults.
		Note: Changing system wide settings requires running the console with elevation.
	
	.EXAMPLE
		PS C:\> Unregister-PSFConfig -Module MyModule
	
		Unregisters all configuration settings for the module MyModule.
#>
	[CmdletBinding(DefaultParameterSetName = 'Pipeline')]
    param (
        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
        [PSFramework.Configuration.Config[]]
		$ConfigurationItem,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = 'Module')]
		[string]
		$Name = "*",
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault"
	)
	
	begin
	{
		if (($PSVersionTable.PSVersion.Major -ge 6) -and ($PSVersionTable.OS -notlike "*Windows*"))
		{
			Stop-PSFFunction -Message "Cannot unregister configurations on non-windows machines. Currently, only registering in registry is supported (This will be updated!)" -Tag 'NotSupported' -Category NotImplemented
			return
		}
		
		switch ("$Scope")
		{
			"UserDefault" { $path = $script:path_RegistryUserDefault }
			"UserMandatory" { $path = $script:path_RegistryUserEnforced }
			"SystemDefault" { $path = $script:path_RegistryMachineDefault }
			"SystemMandatory" { $path = $script:path_RegistryMachineEnforced }
		}
		
		if (Test-Path $path) { $properties = Get-ItemProperty -Path $path }
		else { $properties = $false }
		
		$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		# Silently skip since no action necessary
		if (-not $properties) { return }
		
		foreach ($item in $ConfigurationItem)
		{
			$itemName = $item.FullName
			if ($properties.PSObject.Properties.Name | Where-Object { $_ -eq $itemName })
			{
				Remove-ItemProperty -Path $path -Name $itemName
			}
		}
		
		foreach ($item in $FullName)
		{
			# Ignore string-casted configurations
			if ($item -ceq "PSFramework.Configuration.Config") { continue }
			
			if ($properties.PSObject.Properties.Name | Where-Object { $_ -eq $item })
			{
				Remove-ItemProperty -Path $path -Name $item
			}
		}
		
		if ($Module)
		{
			foreach ($item in $properties.PSObject.Properties.Name)
			{
				if ($item -in $common) { continue }
				
				if ($item -like "$($Module).$($Name)")
				{
					Remove-ItemProperty -Path $path -Name $item
				}
			}
		}
	}
	end
	{
	
	}
}
