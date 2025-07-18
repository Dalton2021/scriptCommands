. "C:\Users\clutch\Documents\Clutch\ScriptCommands\functions.ps1"

# Initial setup
$apps = @()
$branch = ""

# Parse arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '-branch' {
            if ($i + 1 -lt $args.Count) {
                $branch = $args[$i + 1]
                $i++  # Skip the next argument since we've used it
            }
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
    Write-Host -NoNewline "~ No specific apps provided, using all apps. `t" -ForegroundColor Yellow
    Show-LoadingSpinner -Duration 1
    Write-Host ""  # Add a new line after the spinner

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
        Write-Host "~ No valid apps specified, exiting." -ForegroundColor Red
        exit 1
    }

    Write-Host "~ Apps received: `t" -NoNewline -ForegroundColor Yellow
    Show-LoadingSpinner -Duration 1

    foreach ($app in $apps) {
        # Start-Sleep -Milliseconds 250

        if ($app -ne $apps[$apps.Count - 1] -and $apps.Count -ne 1) {
            # Print the app with a bar
            Write-Host -NoNewline " $app |" -ForegroundColor Cyan
        } else {
            Write-Host " $app" -ForegroundColor Cyan
        }
    }

}

if (-not $branch) {
    Write-Error "Please provide a branch name via the -branch parameter."
    exit 1
}

Write-Host "`n"

### Create new branches
# Iterate through resolved app repos
foreach ($app in $apps) {
    $repoPath = Join-Path $baseAppPath $app
    if (!(Test-Path "$repoPath\.git")) {
        Write-Error "Not a git repository for $app at: $repoPath"
        exit 1
    }

    if (Has-UncommittedChanges -Path $repoPath) {
        Write-Error "Uncommitted changes detected in $repoPath. Commit or stash before proceeding."
        exit 1
    }

    try {
        $defaultBranch = Get-DefaultBranch -RepoPath $repoPath
    } catch {
        Write-Error $_
        exit 1
    }

    git -C $repoPath checkout $defaultBranch *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to checkout '$defaultBranch' in $repoPath"
        exit 1
    }

    git -C $repoPath pull origin $defaultBranch *> $null
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to pull '$defaultBranch' in $repoPath"
      exit 1
    }


    # Check if the branch already exists
    $null = git -C $repoPath show-ref --verify --quiet "refs/heads/$branch"
    $branchExists = $LASTEXITCODE -eq 0

    if ($branchExists) {
        # Branch exists: switch to it
        git -C $repoPath checkout $branch *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to switch to existing branch '$branch' in $repoPath"
            exit 1
        }
    } else {
        # Branch doesn't exist: create it
        git -C $repoPath checkout -b $branch *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create and switch to branch '$branch' in $repoPath"
            exit 1
        }
    }


    # Confirm final branch
    $currentBranch = git -C $repoPath rev-parse --abbrev-ref HEAD
    if ($currentBranch -ne $branch) {
        Write-Error "Expected to be on branch '$branch', but found '$currentBranch'"
        exit 1
    }


    Write-Host "[OK] Checked out branch '$branch' in $app" -ForegroundColor Green
}