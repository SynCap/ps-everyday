
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

function gAddIgnore($mode = 'universal', [Alias('n')] [Switch]$New) {
    Switch ($mode) {
        'list' {gIgnore list;return};
        'universal' {$rules = 'windows,linux,macos,visualstudiocode,sublimetext,vim'}
        default {$rules = $mode}
    }
    if ($New) {
        gIgnore $rules > .gitgnore
    } else {
        gIgnore $rules >> .gitgnore
    }
    print "`e[93;40m",".gitignore","`e[0m"," from ","`e[96;40m","gitignore.io","`e[om`n"
    "-" * 35
    println "`e[93m",($New ? "Created new:" : "Added:")
    println "`e[33m",($mode -join ','),"`e[0m"
    $rules | Sort-Object
}

# initialize git repository here
function InitGitRepo($remoteUrl) {
    Get-Date;
    hr;
    # create .gitignore file if not exists
    if (-Not (Test-Path '.gitignore')) {
        draw "Create new " DarkRed;
        draw " .gitignore " Red Yellow;
        echo "";
        gIgnore 'universal' > '.\.gitignore';
        & $env:EDITOR .gitignore;
        hr;
    }
    # init repository in current directory and push it to origin
    git init
    git add .
    git commit -m 'init'
    if ( $remoteUrl -ne $null ) {
        hr
        git remote add origin $remoteUrl
        git push -u origin master
    }
    hr
    git checkout -b develop
    git log
    git branch --all
}
