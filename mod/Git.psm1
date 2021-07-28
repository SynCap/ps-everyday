
##############################################################################
##############################################################################
# GIT utils

# make .gitignore file here via gitignore.io
#
# show posible configuratios list
# @example: gIgnore list
#
# make common configuration
# @example: gIgnore windows,macos,node
function gIgnore($mode) {
	curl -L -s "https://www.gitignore.io/api/$([string]$mode)"
}

# Add/replace `.gitignore` file at current location
#
# replace existing file with `universal`
# @example: gAddIgnore -n
function gAddIgnore {
	param (
		# `list` just show possible values, `universl` for seversl OS
		# and editors rules, or a set of values from `list`
		[String[]] $mode = 'universal',
		# Create new .gitignore file. Replace if exists
		[Switch] $New
	)
	Switch ($mode) {
		'list' {gIgnore list;break};
		'universal' {$rules = 'windows,linux,macos,visualstudiocode,sublimetext,vim';break}
		default {$rules = ($mode -join ',')}
	}
	if ($New) {
		gIgnore $rules > .gitignore
	} else {
		gIgnore $rules >> .gitignore
	}
	print "`e[93;40m",".gitignore","`e[0m"," from ","`e[96;40m","gitignore.io","`e[om`n"
	"-" * 35
	println "`e[93m",($New ? "Created new:" : "Added:")
	println "`e[33m",($mode -join ', '),"`e[0m"
	$rules | Sort-Object
}

# initialize git repository here
#
# init local repo with `main` default branch and no `develop` branch
# @example    : InitGitRepo -b main
#
# init repo with remote origin and `stream` default branch also make `develop`
# branch and switch to it
# @example    : InitGitRepo -b main -d git@github.com:SynCap/ps-everyday.git
function InitGitRepo {
	[CmdletBinding()]
	param (
		[Parameter(position=0)][String] $RemoteUrl,
		[String] $BranchName = (git config --get init.defaultBranch),
		[String] $DevBranch,
		[Alias('m')][String] $CommitMessage = 'init'
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
	# init repository in current directory and push it to origin if any
	git init ($BranchName ? "--initial-branch=$BranchName" : '')
	git add .
	git commit -m $CommitMessage
	if($RemoteUrl) {
		hr
		git remote add origin $RemoteUrl
		git push -u origin $BranchName
	}
	hr;
	if($DevBranch) {
		git checkout -b $DevBranch
		git push -u origin
	}
	git log
	draw "Branches`n" Yellow
	hr
	git branch --all
}

# try to download subdir of repo at GitHub
function Get-GitHubDir {
	[CmdletBinding()]
	param (
		[Parameter(mandatory=$true,position=0)][String] $RepoName,
		[Parameter(Position=1)][String] $dir
	)
	git archive --format zip --remote "https://github.com/$repo.git" HEAD $path |
		7z x -si -o(Join-Path $pwd ('packages/playground/' -split '[/\\]')[-2]);
}

# Raname current branch Locally and Remote
function Rename-GitBranch {
	[CmdletBinding()]
	param(
		[Parameter(mandatory=$true)][String] $OldName,
		[Parameter(mandatory=$true)][String] $NewName,
		[String] $UpstreamName = 'origin'
	)
	# Rename the local branch to the new name
	git branch -m $OldName $NewName
	# Delete the old branch on remote - where $remote is, for example, origin
	#   `git push $remote --delete $OldName`
	# OR shorter way to delete remote branch [:]
	git push $UpstreamName :$OldName
	# Prevent git from using the old name when pushing in the next step.
	# Otherwise, git will use the $OldName on upstream instead of $NewName.
	git branch --unset-upstream $OldName
	# Push the new branch to remote
	git push $UpstreamName $NewName
	# Reset the upstream branch for the NewName local branch
	git push $UpstreamName -u $NewName
	# Somtimes when delete of branch is prohibited at remote server (at GitHub for example)
	# then delete remote operation fails and old refs stay locally
	# even you kill manually old branch at remote server
	# so old refs have to be cleaned at local repo configs
	$oldRef = Join-Path (git rev-parse --show-toplevel) ".git\refs\remotes\$UpstreamName\$OldName"
	if (Test-Path $oldRf) {
		Remove-Item $oldRef
	}
}
