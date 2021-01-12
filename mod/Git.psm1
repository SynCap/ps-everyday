
##############################################################################
##############################################################################
# GIT utils

# make .gitignore file here via gitignore.io
#
# show posible configuratios list
# @example: gitignore list
#
# make common configuration
# @example: gitignore windows,macos,node
function gIgnore($mode) {
    curl -L -s "https://www.gitignore.io/api/$([string]$mode)"
}

function gAddIgnore {
    param (
        # `list` just show possible values, `universl` for seversl OS and editors rules, or a set of values from `list`
        [String[]] $mode = 'universal',
        # Create new .gitignore file. Replace if exists
        [Switch] $New
    )
    Switch ($mode) {
        'list' {gIgnore list;break};
        'universal' {$rules = 'windows,linux,macos,visualstudiocode,sublimetext,vim';break}
        default {$rules = $mode}
    }
    if ($New) {
        gIgnore $rules > .gitignore
    } else {
        gIgnore $rules >> .gitignore
    }
    print "`e[93;40m",".gitignore","`e[0m"," from ","`e[96;40m","gitignore.io","`e[om`n"
    "-" * 35
    println "`e[93m",($New ? "Created new:" : "Added:")
    println "`e[33m",($mode -join ','),"`e[0m"
    $rules | Sort-Object
}

# initialize git repository here
function InitGitRepo {
    [CmdletBinding()]
    param (
        [Parameter(position=0)][String] $RemoteUrl,
        [String] $BranchName,
        [Switch] $NoDevBranch
    )
    Get-Date;
    hr;
    # create .gitignore file if not exists
    if (-Not (Test-Path '.gitignore')) {
        draw "Create new " DarkRed;
        draw " .gitignore `n" Red Yellow;
        gAddIgnore -New
        & $env:EDITOR .gitignore;
        hr;
    }
    # init repository in current directory and push it to origin
    git init ($BranchName ? "--initial-branch=$BranchName" : '')
    git add .
    git commit -m 'init'
    if($RemoteUrl) {
        hr
        git remote add origin $RemoteUrl
        git push -u origin ($BranchName ?? (git config --get init.defaultBranch))
    }
    hr;
    if(-not $NoDevBranch) {
        git checkout -b develop
    }
    git log
    draw "Branches" Yellow
    hr
    git branch --all
}
