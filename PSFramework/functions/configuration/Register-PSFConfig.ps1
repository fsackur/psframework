﻿function Register-PSFConfig
{
<#
	.SYNOPSIS
		Registers an existing configuration object in registry.
	
	.DESCRIPTION
		Registers an existing configuration object in registry.
		This allows simple persisting of settings across powershell consoles.
		It also can be used to generate a registry template, which can then be used to create policies.
	
	.PARAMETER Config
		The configuration object to write to registry.
		Can be retrieved using Get-PSFConfig.
	
	.PARAMETER FullName
		The full name of the setting to be written to registry.
	
	.PARAMETER Module
		The name of the module, whose settings should be written to registry.
	
	.PARAMETER Name
		Default: "*"
		Used in conjunction with the -Module parameter to restrict the number of configuration items written to registry.
	
	.PARAMETER Scope
		Default: UserDefault
		Who will be affected by this export how? Current user or all? Default setting or enforced?
		Legal values: UserDefault, UserMandatory, SystemDefault, SystemMandatory
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Get-PSFConfig psframework.message.* | Register-PSFConfig
	
		Retrieves all configuration items that that start with psframework.message. and registers them in registry for the current user.
	
	.EXAMPLE
		PS C:\> Register-PSFConfig -FullName "psframework.developer.mode.enable" -Scope SystemDefault
	
		Retrieves the configuration item "psframework.developer.mode.enable" and registers it in registry as the default setting for all users on this machine.
	
	.EXAMPLE
		PS C:\> Register-PSFConfig -Module MyModule -Scope SystemMandatory
	
		Retrieves all configuration items of the module MyModule, then registers them in registry to enforce them for all users on the current system.
#>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	Param (
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Name", Position = 0)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Name", Position = 1)]
		[string]
		$Name = "*",
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault",
		
		[switch]
		$EnableException
	)
	
	begin
	{
		if ($script:NoRegistry -and ($Scope -band 14))
		{
			Stop-PSFFunction -Message "Cannot register configurations on non-windows machines to registry. Please specify a file-based scope" -Tag 'NotSupported' -Category NotImplemented
			return
		}
		
		# Linux and MAC default to local user store file
		if ($script:NoRegistry -and ($Scope -eq "UserDefault"))
		{
			$Scope = [PSFramework.Configuration.ConfigScope]::FileUserLocal
		}
		
		$parSet = $PSCmdlet.ParameterSetName
		
		function Write-Config
		{
			[CmdletBinding()]
			Param (
				[PSFramework.Configuration.Config]
				$Config,
				
				[PSFramework.Configuration.ConfigScope]
				$Scope,
				
				[bool]
				$EnableException,
				
				[string]
				$FunctionName = (Get-PSCallStack)[0].Command
			)
			
			if (-not $Config -or ($Config.RegistryData -eq "<type not supported>"))
			{
				Stop-PSFFunction -Message "Invalid Input, cannot export $($Config.FullName), type not supported" -EnableException $EnableException -Category InvalidArgument -Tag "config", "fail" -Target $Config -FunctionName $FunctionName -ModuleName "PSFramework"
				return
			}
			
			try
			{
				Write-PSFMessage -Level Verbose -Message "Registering $($Config.FullName) for $Scope" -Tag "Config" -Target $Config -FunctionName $FunctionName -ModuleName "PSFramework"
				#region User Default
				if (1 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryUserDefault -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryUserDefault -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion User Default
				
				#region User Mandatory
				if (2 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryUserEnforced -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryUserEnforced -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion User Mandatory
				
				#region System Default
				if (4 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryMachineDefault -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryMachineDefault -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion System Default
				
				#region System Mandatory
				if (8 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryMachineEnforced -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryMachineEnforced -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion System Mandatory
			}
			catch
			{
				Stop-PSFFunction -Message "Failed to export $($Config.FullName), to scope $Scope" -EnableException $EnableException -Tag "config", "fail" -Target $Config -ErrorRecord $_ -FunctionName $FunctionName -ModuleName "PSFramework"
				return
			}
		}
		
		function Ensure-RegistryPath
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
			[CmdletBinding()]
			Param (
				[string]
				$Path
			)
			
			if (-not (Test-Path $Path))
			{
				$null = New-Item $Path -Force
			}
		}
		
		# For file based persistence
		$configurationItems = @()
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		#region Registry Based
		if ($Scope -band 15)
		{
			switch ($parSet)
			{
				"Default"
				{
					foreach ($item in $Config)
					{
						Write-Config -Config $item -Scope $Scope -EnableException $EnableException
					}
					
					foreach ($item in $FullName)
					{
						if ([PSFramework.Configuration.ConfigurationHost]::Configurations.ContainsKey($item.ToLower()))
						{
							Write-Config -Config ([PSFramework.Configuration.ConfigurationHost]::Configurations[$item.ToLower()]) -Scope $Scope -EnableException $EnableException
						}
					}
				}
				"Name"
				{
					foreach ($item in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object Module -EQ $Module | Where-Object Name -Like $Name))
					{
						Write-Config -Config $item -Scope $Scope -EnableException $EnableException
					}
				}
			}
		}
		#endregion Registry Based
		
		#region File Based
		else
		{
			switch ($parSet)
			{
				"Default"
				{
					foreach ($item in $Config)
					{
						$configurationItems += $item
					}
					
					foreach ($item in $FullName)
					{
						if ([PSFramework.Configuration.ConfigurationHost]::Configurations.ContainsKey($item.ToLower()))
						{
							$configurationItems += [PSFramework.Configuration.ConfigurationHost]::Configurations[$item.ToLower()]
						}
					}
				}
				"Name"
				{
					foreach ($item in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object Module -EQ $Module | Where-Object Name -Like $Name))
					{
						$configurationItems += $item
					}
				}
			}
		}
		#endregion File Based
	}
	end
	{
		#region Finish File Based Persistence
		if ($Scope -band 16)
		{
			Write-PsfConfigFile -Config ($configurationItems | Select-Object -Unique) -Path (Join-Path $script:path_FileUserLocal "psf_config.json")
		}
		if ($Scope -band 32)
		{
			Write-PsfConfigFile -Config ($configurationItems | Select-Object -Unique) -Path (Join-Path $script:path_FileUserShared "psf_config.json")
		}
		if ($Scope -band 64)
		{
			Write-PsfConfigFile -Config ($configurationItems | Select-Object -Unique) -Path (Join-Path $script:path_FileSystem "psf_config.json")
		}
		#endregion Finish File Based Persistence
	}
}
