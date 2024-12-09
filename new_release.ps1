# $apps = $args

# $useProdSetup = $false
# $zip = $false

# # Check for the -prod flag in the arguments
# if ($args -contains '-prod') {
#     $useProdSetup = $true
#     # Remove the -prod flag from the $args array so it doesn't get treated as an app name
#     $args = $args | Where-Object { $_ -ne '-prod' }
# }

# # Check for the -zip flag in the arguments
# if ($args -contains '-zip') {
#     $zip = $true
#     # Remove the -zip flag from the $args array so it doesn't get treated as an app name
#     $args = $args | Where-Object { $_ -ne '-zip' }
# }


# # Define base path
# $baseAppPath = "C:\Users\clutch\Documents\Clutch\Apps"

# # Define the mapping between short names and full app names
# $appMappings = @{
#     "civ" = "Civilian-Fatalities"
#     "contact" = "Contact"
#     "ff" = "Firefighter-Fatalities"
#     "hotel" = "Hotel"
#     "nfa" = "NFACourses"
#     "pubs" = "Publications"
#     "reg" = "Registry"
#     "thes" = "Thesaurus"
# }
# # Define the list of all full app names
# $allApps = $appMappings.Values

# # If no apps are specified, use the full list
# if (-not $apps -or $apps.Count -eq 0) {
#     Write-Host "No specific apps provided, using all apps." -ForegroundColor Yellow
#     $apps = $allApps
# } else {
#     # Convert short names to full names using the mapping
#     $apps = $apps | ForEach-Object {
#         if ($appMappings.ContainsKey($_)) {
#             $appMappings[$_]
#         } else {
#             $_  # If not a short name, keep the original name
#         }
#     }

#     # Validate the specified apps
#     $apps = $apps | Where-Object { $allApps -contains $_ }
#     if ($apps.Count -eq 0) {
#         Write-Host "No valid apps specified, exiting." -ForegroundColor Red
#         exit 1
#     }
# }

# # Debugging: Output the apps being processed
# Write-Host "Apps recieved: $apps" -ForegroundColor Cyan
# Write-Host "Using: $(if ($useProdSetup) { 'setup:prod' } else { 'setup' })" -ForegroundColor Yellow


### code above suddenly stopped working? Still works for update_apps though?

# Initial setup
$useProdSetup = $false
$zip = $false
$apps = @()

# Parse arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '-prod' {
            $useProdSetup = $true
        }
        '-zip' {
            $zip = $true
        }
        '-apps' {
            # Collect all app names following the -apps flag
            for ($j = $i + 1; $j -lt $args.Count; $j++) {
                if ($args[$j].StartsWith('-')) {
                    break
                }
                $apps += $args[$j]
                $i = $j
            }
        }
        default {
            # Handle arguments not preceded by a recognized flag
            $apps += $args[$i]
        }
    }
}

# Define base path
$baseAppPath = "C:\Users\clutch\Documents\Clutch\Apps"

# Define the mapping between short names and full app names
$appMappings = @{
    "civ"    = "Civilian-Fatalities"
    "contact" = "Contact"
    "ff"      = "Firefighter-Fatalities"
    "hotel"   = "Hotel"
    "nfa"     = "NFACourses"
    "pubs"    = "Publications"
    "reg"     = "Registry"
    "thes"    = "Thesaurus"
}
# Define the list of all full app names
$allApps = $appMappings.Values

# If no apps are specified, use the full list
if (-not $apps -or $apps.Count -eq 0) {
    Write-Host "No specific apps provided, using all apps." -ForegroundColor Yellow
    $apps = $allApps
} else {
    # Convert short names to full names using the mapping
    $apps = $apps | ForEach-Object {
        if ($appMappings.ContainsKey($_)) {
            $appMappings[$_]
        } else {
            $_  # If not a short name, keep the original name
        }
    }

    # Validate the specified apps
    $apps = $apps | Where-Object { $allApps -contains $_ }
    if ($apps.Count -eq 0) {
        Write-Host "No valid apps specified, exiting." -ForegroundColor Red
        exit 1
    }
}

# Debugging: Output the parsed values
Write-Host "Apps received: $apps" -ForegroundColor Cyan
Write-Host "Using: $(if ($useProdSetup) { 'setup:prod' } else { 'setup' })" -ForegroundColor Yellow


if (!$zip) {
    Write-Host "Skipping zip files." -ForegroundColor Yellow
}


$scriptStartTime = Get-Date

# Function to start a command in a new terminal window
function Start-TerminalAndRun {
    param (
        [string]$command,
        [string]$workingDirectory
    )
    $process = Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "cd `"$workingDirectory`"; $command; exit" -PassThru
    return $process
}

$totalApps = $apps.Count

$buildIndex = 1
$zipIndex = 1


foreach ($app in $apps) {
    Write-Host "Processing $app ($buildIndex/$totalApps)..." -ForegroundColor DarkCyan

    $buildIndex++

    # Start timing for this app
    $appStartTime = Get-Date

    # Define paths for dotnet app and client app
    $dotnetAppPath = Join-Path -Path $baseAppPath -ChildPath "$app\$app"
    $clientAppPath = Join-Path -Path $baseAppPath -ChildPath "$app\$app\ClientApp"

    try {
        # Start dotnet run in a new terminal window
        $dotnetProcess = Start-TerminalAndRun -command "dotnet run" -workingDirectory $dotnetAppPath
        if ($dotnetProcess) {
            Write-Host "  - dotnet run started" -ForegroundColor DarkGray
        } else {
            Write-Host "Error: dotnet run failed to start for $app" -ForegroundColor Red
            continue
        }

        # Wait for dotnet run to start properly
        Start-Sleep -Seconds 16 #used to be 8 seconds, but dotnet updated and is a lot slower to start up.

        # Start npm run setup in a new terminal window
        # $npmProcess = Start-TerminalAndRun -command "npm run setup" -workingDirectory $clientAppPath

        $npmCommand = if ($useProdSetup) { "npm run setup:prod" } else { "npm run setup" }
        $npmProcess = Start-TerminalAndRun -command $npmCommand -workingDirectory $clientAppPath

        if ($npmProcess) {
            Write-Host "  - npm run setup started"  -ForegroundColor DarkGray
        } else {
            Write-Host "Error: npm run setup failed to start for $app" -ForegroundColor Red
            continue
        }

        # Wait for npm setup to complete
        $npmProcess.WaitForExit()
        Write-Host "  - COMPLETED npm run setup"  -ForegroundColor DarkGray

        $dotnetProcess = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
        if ($dotnetProcess) {
            Stop-Process -Id $dotnetProcess.Id -Force
            Write-Host "  - STOPPED dotnet run terminal"  -ForegroundColor DarkGray
        }


        # Kill npm process if not already
        $npmProcess = Get-Process -Id $npmProcess.Id -ErrorAction SilentlyContinue
        if ($npmProcess) {
            Stop-Process -Id $npmProcess.Id -Force
            Write-Host "  - STOPPED npm terminal" -ForegroundColor DarkGray
        }


        if ($useProdSetup -eq $false) {
            # Run the first msbuild command for Staging in the same terminal window
            $msbuildStagingCommand = "dotnet msbuild -p:DeployOnBuild=true -p:PublishProfile=Properties\PublishProfiles\Staging.pubxml"
            $stagingProcess = Start-TerminalAndRun -command "$msbuildStagingCommand" -workingDirectory $dotnetAppPath
            Write-Host "  - dotnet msbuild for Staging started" -ForegroundColor DarkGray

            $stagingProcess.WaitForExit()

            Write-Host "  - COMPLETED dotnet msbuild for Staging"  -ForegroundColor DarkGray
        }
        # Run the second msbuild command for Production in the same terminal window
        $msbuildProductionCommand = "dotnet msbuild -p:DeployOnBuild=true -p:PublishProfile=Properties\PublishProfiles\Production.pubxml"
        $productionProcess = Start-TerminalAndRun -command "$msbuildProductionCommand" -workingDirectory $dotnetAppPath
        Write-Host "  - dotnet msbuild for Production"  -ForegroundColor DarkGray

        $productionProcess.WaitForExit()

        Write-Host "  - COMPLETED dotnet msbuild for Production"  -ForegroundColor DarkGray

        # Calculate and log the time taken for this app
        $appEndTime = Get-Date
        $appDuration = $appEndTime - $appStartTime
        $minutes = [math]::Floor($appDuration.TotalMinutes)
        $seconds = $appDuration.Seconds
        $minuteLabel = if ($minutes -eq 1) { "minute" } else { "minutes" }
        $secondLabel = if ($seconds -eq 1) { "second" } else { "seconds" }

        Write-Host "Finished $app in $minutes $minuteLabel and $seconds $secondLabel" -ForegroundColor DarkGreen
    }
    catch {
        Write-Host "Error encountered while processing {$app}: $_" -ForegroundColor Red
    }
}


# Define the base path where the folders are located
$baseReleasePath = "C:\Users\clutch\Documents\Clutch\Apps\Releases"


# Creates a zip file for each app inside the apps/APP_NAME/Releases folder using the contents of the baseReleasePath Production folder
if ($zip) {
    foreach ($app in $apps) {
        # Map short name to full name
        if ($appMappings.Values -contains $app) {
            Write-Host "Zipping $app ($zipIndex/$totalApps)..." -ForegroundColor DarkCyan

            $zipIndex++

            # Define the paths for the app and client app
            $appReleasesPath = Join-Path -Path $baseAppPath -ChildPath "$app\Releases"
            $clientAppPath = Join-Path -Path $baseAppPath -ChildPath "$app\$app\ClientApp"

            # Define the path to the Production folder
            $productionPath = Join-Path -Path $baseReleasePath -ChildPath "$app\Production"

            # Check if the Production directory exists
            if (Test-Path $productionPath) {
                # Check if the Releases directory exists; if not, create it
                if (-not (Test-Path $appReleasesPath)) {
                    Write-Host "  - Releases directory for $app not found at $appReleasesPath. Creating directory..." -ForegroundColor Yellow
                    New-Item -Path $appReleasesPath -ItemType Directory | Out-Null
                }

                # Read the version from package.json
                $packageJsonPath = Join-Path -Path $clientAppPath -ChildPath "package.json"
                if (Test-Path $packageJsonPath) {
                    $packageJson = Get-Content $packageJsonPath | Out-String | ConvertFrom-Json
                    $version = $packageJson.version

                    # Ask the user if they want to increment the version number
                    Write-Host "  - Current version: $version" -ForegroundColor Yellow
                    $incrementVersion = Read-Host "  - Do you want to increment the version number? (y/n)"

                    if ($incrementVersion -eq 'y') {
                        # Ask for new version input
                        $newVersion = Read-Host "  - Enter the new version number (x.x.x)"
                        if ($newVersion -match '^\d+\.\d+\.\d+$') { # Optional: Simple validation for semantic versioning format
                            $packageJson.version = $newVersion
                            $version = $newVersion

                            # Convert the updated JSON object back to a string and write it to the file
                            $packageJson | ConvertTo-Json -Depth 100 | Set-Content -Path $packageJsonPath
                            Write-Host "  - Version updated to $newVersion in package.json" -ForegroundColor DarkGray
                        } else {
                            Write-Host "  - Invalid version format. Using the existing version: $version" -ForegroundColor Yellow
                        }
                    }


                    $zipFileName = "$app" + "_$version.zip"
                } else {
                    Write-Host "  - Package.json not found in $clientAppPath. Skipping $app." -ForegroundColor Yellow
                    continue
                }


                # Define the destination zip file within the app's root releases folder
                $zipFilePath = Join-Path -Path $appReleasesPath -ChildPath $zipFileName

                # Compress the contents of the Production folder into a zip file
                Write-Host "  - Zipping contents into $zipFileName..." -ForegroundColor DarkGray
                Compress-Archive -Path (Join-Path $productionPath '*') -DestinationPath $zipFilePath -Force

                Write-Host "  - $zipFileName created successfully." -ForegroundColor DarkGray

                # Delete the oldest zip file if there are more than 2 zip files in the Releases folder
                $zipFiles = Get-ChildItem -Path $appReleasesPath -Filter "*.zip" | Sort-Object LastWriteTime
                if ($zipFiles.Count -gt 5) {
                    $oldestZipFile = $zipFiles[0]
                    Write-Host "  - Deleting oldest zip file: $($oldestZipFile.Name)..." -ForegroundColor DarkGray
                    Remove-Item -Path $oldestZipFile.FullName -Force
                    Write-Host "  - Oldest zip file $($oldestZipFile.Name) has been deleted." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  - Production directory for $app not found at $productionPath. Skipping." -ForegroundColor Yellow
            }
        } else {
            Write-Host "App short name '$app' not recognized. Skipping." -ForegroundColor Red
        }
    }
}

# Calculate and log the total time taken for all apps
$scriptEndTime = Get-Date
$scriptDuration = $scriptEndTime - $scriptStartTime
$totalMinutes = [math]::Floor($scriptDuration.TotalMinutes)
$totalSeconds = $scriptDuration.Seconds
$totalMinutesLabel = if ($totalMinutes -eq 1) { "minute" } else { "minutes" }
$totalSecondsLabel = if ($totalSeconds -eq 1) { "second" } else { "seconds" }

Write-Host "All apps finished in $totalMinutes $totalMinutesLabel and $totalSeconds $totalSecondsLabel" -ForegroundColor Cyan

