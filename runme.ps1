### Imports ###

Import-Module BitsTransfer

### Variables 

$log = "runme.log"

#urls for downloads
$cygwinURLx86 = "https://cygwin.com/setup-x86.exe"
$cygwinURLx64 = "https://cygwin.com/setup-x86_64.exe" 
$vimURL ="ftp://ftp.vim.org/pub/vim/pc/gvim74.exe"

#installation parameters
$cygwinInstallParams ="-D -P tmux, gvim, vim -Q"

### Functions ###

function Validate-UserRole($role)
{
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]$role)
}

#handle various file formats and protocols for downloading. I used bits where possible, > reliability.
function Download($Source,$Destination){
    #veyr basic regex for URL's.
    switch -Regex ($source){
        "(^http://|^git://).+\.git$" {
            #clone with git
            break
        }
        "^https?://((?!git$).)*$" {
            Start-BitsTransfer -Source $Source  -Destination $Destination -
            break
        }
        "ftp://.+" {
            
            $webclient = New-Object System.Net.WebClient
            $webclient.DownloadFile($Source, $Destination)
            $webclient.Dispose()
            break
        }
    }
}


function ModifyPowershellProfile()
{
    #TODO: invoke a seperate script to launch this? 
}


# Determine if OS is 64bit by declaring a pointer to an int and determining it's size
# This is compatible with all versions of powershell
function IS64BitOperatingSystem
{
    if([IntPtr]::Size -eq 8){ return $True }
    else { return $False }
}

 
### check \\HKLM\software\cygwin\installations for cygwin installation directory.
function Get-CygwinPath()
{
    $regPath = "HKLM:\SOFTWARE\Cygwin\Installations"
    
    if(test-path $regPath)
    {
        $cygwinRegKey = get-item -Path $regPath
        if($cygwinRegKey.ValueCount -eq 1)
        {
            #Not sure if the leading \??\ is normal for a cygwin path
            return $cygwinRegKey.GetValue($cygwinRegKey.property).substring(4)
        }
    }
    #prompt for location
    return $null
}

function Get-PathVim()
{
    $vimRegKey = get-item -Path "HKLM:\software\Microsoft\Windows\CurrentVersion\Uninstall\Vim 7.4"
    if($vimRegKey.ValueCount -gt 0)
    {
        $vimRoot = $vimRegKey.GetValue("UninstallString")
        $vimRoot = $vimRoot.substring(0,$vimRoot.lastindexof("\vim"))
        return $vimRoot
    }
    return $null
}

### MAIN ###

if(Validate-UserRole("Administrator") -eq $false){
    Write-Warning "This may not work if you do not have administrative privledges on this machine."
}

#get script path, this is where everything gets downloaded
if( $PSScriptRoot -eq $null)
{
    $PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition
}


#download and install vim
if((Get-PathVim) -eq $null){       
    Download -source $vimURL -destination ($PSScriptRoot + '/' + ($vimURL.Split("/")|select -Last 1))
    Start-Process ($PSScriptRoot + '/' + ($vimURL.Split("/")|select -Last 1)) -Wait
}


if(Get-CygwinPath -contains "64"){
    if( ($cygwinURLx64.Split('/')|select -Last 1|test-path) -eq $false){        
        Download -source $cygwinURLx64 -destination $PSScriptRoot
    }    
    Start-Process ($cygwinURLx64.Split('/')|select -Last 1) -ArgumentList $cygwinInstallParams -wait
}
else{
    if( ($cygwinURLx86.Split('/')|select -Last 1|test-path) -eq $false){        
        Download -source $cygwinURLx86 -destination $PSScriptRoot 
    }
    Start-Process ($cygwinURLx86.Split('/')|select -Last 1)  -ArgumentList $cygwinInstallParams -Wait
}



### use mklink to create symbolic links
# mklink c:\program files\vim\_vimrc \.vimrc
# mklink c:\program files\vim\vimfiles \vimfiles
#

### put this in a shell script to launch from cygwin?
#ln -s _vimrc /cygdrive/d/cygwin64/home/.vimrc
#ln -s _gvimrc /cygdrive/d/cygwin64/home/.gvimrc
#ln -s vimfiles /cygdrive/d/cygwin64/home/.vim