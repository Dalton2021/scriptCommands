$apps = $args

$useProdSetup = $false

# Check for the -prod flag in the arguments
if ($args -contains '-prod') {
    $useProdSetup = $true
    # Remove the -prod flag from the $args array so it doesn't get treated as an app name
    $args = $args | Where-Object { $_ -ne '-prod' }
}


# Define base path
$baseAppPath = "C:\Users\clutch\Documents\Clutch\Apps"

# Define the mapping between short names and full app names
$appMappings = @{
    "civ" = "Civilian-Fatalities"
    "contact" = "Contact"
    "ff" = "Firefighter-Fatalities"
    "hotel" = "Hotel"
    "nfa" = "NFACourses"
    "pubs" = "Publications"
    "reg" = "Registry"
    "thes" = "Thesaurus"
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

# Debugging: Output the apps being processed
Write-Host "Apps recieved: $apps" -ForegroundColor Cyan
Write-Host "Using: $(if ($useProdSetup) { 'setup:prod' } else { 'setup' })" -ForegroundColor Yellow


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
        Start-Sleep -Seconds 8

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

# If no apps are specified, exit with a message

foreach ($app in $apps) {
    # Map short name to full name
    if ($appMappings.Values -contains $app) {
        Write-Host "Zipping $app ($zipIndex/$totalApps)..." -ForegroundColor DarkCyan

        $zipIndex++

        # Define the path to the Production folder
        $productionPath = Join-Path -Path $baseReleasePath -ChildPath "$app\Production"

        # Check if the Production directory exists
        if (Test-Path $productionPath) {
            # Define the destination zip file within the Production folder
            $zipFilePath = Join-Path -Path $productionPath -ChildPath "$app.zip"

            # Compress the contents of the Production folder into a zip file
            Write-Host " - zipping contents into $app.zip..." -ForegroundColor DarkGray
            Compress-Archive -Path (Join-Path $productionPath '*') -DestinationPath $zipFilePath -Force

            Write-Host "$app has been zipped successfully." -ForegroundColor DarkGreen
        } else {
            Write-Host "Production directory for $app not found at $productionPath. Skipping." -ForegroundColor Yellow
        }
    } else {
        Write-Host "App short name '$app' not recognized. Skipping." -ForegroundColor Red
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

