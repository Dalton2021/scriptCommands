### Run script
# Local
# powershell -ExecutionPolicy Bypass -File "C:\Users\clutch\Documents\Clutch\ScriptCommands\ApplicationAutomation.ps1" -WindowStyle Hidden

# A1
# powershell -ExecutionPolicy Bypass -File "E:\Apps\IIS Automation Script\ApplicationAutomation.ps1" -WindowStyle Hidden

### Debugging
# if the script isn't ever working check task-scheduler for preview apps monitor service and restart it.

Import-Module WebAdministration

$watchPaths = @(
    "E:/Apps/Preview/Contact",
    "E:/Apps/Preview/Civilian-Fatalities"
    "E:/Apps/Preview/Hotel"
    "E:/Apps/Preview/NFACourses"
    "E:/Apps/Preview/Publications"
    "E:/Apps/Preview/Registry"
    "E:/Apps/Preview/Thesaurus"
    "E:/Apps/Preview/Firefighter-Fatalities"
) | ForEach-Object { $_.Replace('/', '\') }

$Global:websiteName = "preview"
$Global:parentApp = "preview"
$Global:watchers = @()

function Test-IISWebsite {
    param ([string]$websiteName)
    return ($null -ne (Get-Website -Name $websiteName -ErrorAction SilentlyContinue))
}

function Get-DisplayPath {
    param ([string]$path)
    return $path.Replace('\', '/')
}

function Get-WindowsPath {
    param ([string]$path)
    return $path.Replace('/', '\')
}

function Get-RelativePath {
    param (
        [string]$fullPath,
        [string]$basePath
    )
    $normalizedPath = Get-WindowsPath -path $fullPath
    $normalizedBase = Get-WindowsPath -path $basePath
    return $normalizedPath.Substring($normalizedBase.Length).TrimStart('\')
}

function New-IISApplicationSetup {
    param (
        [string]$folderPath,
        [string]$websiteName,
        [string]$parentApp,
        [string]$watchPath
    )
    try {
        # Convert to Windows paths for processing
        $folderPath = Get-WindowsPath -path $folderPath
        $watchPath = Get-WindowsPath -path $watchPath

        # Only process if it's a direct child of the watch path
        $parentFolder = (Split-Path -Parent $folderPath)
        if ($parentFolder -eq $watchPath) {
            $subfolderName = Split-Path -Parent $folderPath | Split-Path -Leaf
            $newFolderName = Split-Path -Leaf $folderPath

            # Construct the application name
            $appPoolName = "$subfolderName`_$newFolderName"
            $applicationPath = "$parentApp/$subfolderName/$newFolderName"

            # Create Application Pool
            $appPool = Get-IISAppPool -Name $appPoolName -ErrorAction SilentlyContinue
            if ($null -eq $appPool) {
                $appPool = New-WebAppPool -Name $appPoolName -ErrorAction Stop
                Set-ItemProperty -Path "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value "v4.0"
                Set-ItemProperty -Path "IIS:\AppPools\$appPoolName" -Name "startMode" -Value "AlwaysRunning"
                Write-Host "Application Pool '$appPoolName' created successfully" -ForegroundColor Green
            }

            # Create IIS Application
            $existingApp = Get-WebApplication -Site $websiteName -Name $applicationPath -ErrorAction SilentlyContinue

            if ($null -eq $existingApp) {
                # Use Windows path for IIS
                $webApp = New-WebApplication -Site $websiteName -Name $applicationPath -PhysicalPath $folderPath -ApplicationPool $appPoolName
                if ($null -ne $webApp) {
                    Write-Host "IIS Application '$applicationPath' created successfully at path $folderPath" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-IISApplicationSetup {
  param (
      [string]$folderPath,
      [string]$websiteName,
      [string]$parentApp,
      [string]$watchPath
  )
  try {
      # Convert to Windows paths for processing
      $folderPath = Get-WindowsPath -path $folderPath
      $watchPath = Get-WindowsPath -path $watchPath

      # Only process if it's a direct child of the watch path
      $parentFolder = (Split-Path -Parent $folderPath)
      if ($parentFolder -eq $watchPath) {
          $subfolderName = Split-Path -Parent $folderPath | Split-Path -Leaf
          $folderName = Split-Path -Leaf $folderPath

          $appPoolName = "$subfolderName`_$folderName"
          $applicationPath = "$parentApp/$subfolderName/$folderName"

          # Remove Application
          $sitePath = "IIS:\Sites\$websiteName\$applicationPath"
          if (Test-Path $sitePath) {
              Write-Host "Removing IIS Application: $applicationPath" -ForegroundColor Yellow
              Remove-WebApplication -Name $applicationPath -Site $websiteName
              Write-Host "IIS Application '$applicationPath' removed successfully" -ForegroundColor Green
          } else {
              Write-Host "WARNING: IIS Application '$applicationPath' does not exist" -ForegroundColor Red
          }

          # Remove Application Pool
          Start-Sleep -Seconds 1 # Small delay to ensure state consistency
          if (Test-Path "IIS:\AppPools\$appPoolName") {
              Write-Host "Removing Application Pool: $appPoolName" -ForegroundColor Yellow
              Remove-WebAppPool -Name $appPoolName
              Write-Host "Application Pool '$appPoolName' removed successfully" -ForegroundColor Green
          } else {
              Write-Host "WARNING: Application Pool '$appPoolName' does not exist" -ForegroundColor Red
          }
      }
  }
  catch {
      Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
  }
}



try {
    if (-not (Test-IISWebsite -websiteName $Global:websiteName)) {
        throw "Website '$Global:websiteName' does not exist in IIS"
    }

    # Create a watcher for each path
    foreach ($path in $watchPaths) {
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $path
        $watcher.IncludeSubdirectories = $false  # Only watch direct children
        $watcher.Filter = ""
        $watcher.EnableRaisingEvents = $true
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::DirectoryName

        # Register events for this watcher
        Register-ObjectEvent $watcher "Created" -Action {
            $fullPath = $Event.SourceEventArgs.FullPath
            if (Test-Path -Path $fullPath -PathType Container) {
                Write-Host "New folder detected: $fullPath" -ForegroundColor Green
                New-IISApplicationSetup -folderPath $fullPath -websiteName $Global:websiteName -parentApp $Global:parentApp -watchPath $Event.MessageData
            }
        } -MessageData $path

        Register-ObjectEvent $watcher "Deleted" -Action {
            $fullPath = $Event.SourceEventArgs.FullPath
            Write-Host "Folder deleted: $fullPath" -ForegroundColor Yellow
            Remove-IISApplicationSetup -folderPath $fullPath -websiteName $Global:websiteName -parentApp $Global:parentApp -watchPath $Event.MessageData
        } -MessageData $path

        $Global:watchers += $watcher
        Write-Host "Monitoring folder changes in $path" -ForegroundColor Cyan
    }

    while ($true) { Start-Sleep -Seconds 1 }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Clean up all watchers
    foreach ($watcher in $Global:watchers) {
        $watcher.Dispose()
    }
    Get-EventSubscriber | Unregister-Event
}