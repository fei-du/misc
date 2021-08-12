enum Device {
    M7
    M33
}
function Invoke-Srec {
<#
.Synopsis
   download srec and run 
.DESCRIPTION
   build a jlink script according to srec file and then execute the jlink file to download srec and run
.EXAMPLE
   Invoke-Srec .\Single_core_power_mode_switch_bm_core0.srec
.EXAMPLE
   Invoke-Srec ..\hello_world_demo_cm7.srec -ip 10.207.203.219
.EXAMPLE
   gci .\Single_core_power_mode_switch_bm_core0.srec | Invoke-Srec
.EXAMPLE
   Invoke-Srec .\Single_core_power_mode_switch_bm_core0.srec -verbose

   VERBOSE: target srec is C:\Users\nxa13836\OneDrive - NXP\Project\1170\testplan\idd\b0\temp\Single_core_power_mode_switch_bm_core0.srec
   VERBOSE: entry address is 81BD
   VERBOSE: running jlink script C:\Users\nxa13836\AppData\Local\Temp\tmpAE27.tmp

#>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        $srec, 
        [Parameter(Mandatory = $false,
            Position = 1)]
        [Device]$device = [device]::M33,
        
        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$entry,
        [Parameter(Mandatory = $false,
            Position = 3)]
        [IPAddress]$ip
    )

    Process {
        $target = Get-ChildItem $srec -ErrorAction Stop
        $a = Get-Content -Tail 1 $target
        if (-not ($PSBoundParameters.ContainsKey("entry"))) {
            $entry = $a[4..$($a.Length - 3)] -join ''
            #$entry = ($(srec_info.exe $srec)[2] -split ' ')[3]
        }
        $temp = New-TemporaryFile
        @"

Device CORTEX-$device

Si SWD
speed 400
r
h
Sleep 150
loadfile "$(Resolve-Path $target)"
setPC 0x$entry
Sleep 1000
go
q
"@  | Set-Content -path $temp -Encoding UTF8 -WhatIf:$false
        if ($PSCmdlet.ShouldProcess($srec, "executing SREC file")) {
            if ($ip) {
                if (Test-Connection $ip -Count 1 -ErrorAction Stop) {
                    JLink.exe -IP $ip $temp
                }
            }
            else {
                JLink.exe $temp
            }
            Get-Content $temp
        }
        else{
            Get-Content $temp
        }
        Write-Verbose "target srec is $(Resolve-Path $target)"
        Write-Verbose "entry address is $entry"
        Write-Verbose  "running jlink script $(Resolve-Path $temp)"
        return $temp
    }
}


function get-bits($base, $startBit, $endBit) {
    if ( $endBit -eq $null) { $endBit = $startBit }
    $string = $input |  Select-String "^.{5}$base" 
    $value = $string | ConvertFrom-String | ForEach-Object { ([convert]::ToString("0x$($_.p3)", 2)).padleft(32, '0').tochararray()[(31 - $endBit)..(31 - $startBit)] } | join-string
    [PSCustomObject] @{
        rawValue = $string
        address  = "$base[$endBit" + ":" + "$startBit" + "]"
        value    = $value
    }
}

function send-file($file) {
    Copy-Item $file \\ZCH01FPC01.fsl.freescale.net\Microcontrollers\BACES\DF\ -Verbose
}

function get-file() {
    Get-ChildItem \\ZCH01FPC01.fsl.freescale.net\Microcontrollers\BACES\DF  | Sort-Object LastAccessTime -Descending | Select-Object -First 1 | Copy-Item -Destination . -Verbose
}

function get-temp() {
    Invoke-Command -ComputerName  nxw19057.wbi.nxp.com  -ScriptBlock { Get-Content temp }
}
function com {
    [System.IO.Ports.SerialPort]::GetPortNames()
}

function Hex($decimal, $base = 16) {
    [convert]::ToString($decimal, $base)
}

function new-address($start, $number) {
    0..($number - 1) | ForEach-Object { hex (4 * $_ + ('0x' + $start)) 16 }
} 

function binary($decimal, $base = 2) {
    [convert]::toint32($decimal, $base)
}

function jl {
    JLink.exe -new_console:s
}

function s {
    set-theme paradox
}

function p {
    com  | ForEach-Object { putty.exe -load "$_"; $_ }   
}

function nnn($file, [switch]$v) {
    $ex = Get-ChildItem $file | Select-Object -ExpandProperty extension
    # if($v){
    #     $split = '-new_console:s40V'
    # } else{
    #     $split = '-new_console:s40H'
    # }
    $split = ''
    switch ($ex) {
        ".ps1" {
            nodemon $split --exec 'C:\windows\System32\WindowsPowerShell\v1.0\powershell.exe -noprofile' $file   --ext ps1
            break
        }
        ".R" {
            # somehow not working when updating node from v6 to v8

            $env:Path += ";C:\Program Files\R\R-3.4.0\bin\"
            nodemon $split --exec 'Rscript.exe' $file   --ext R
            break
        }
        ".py" {
            nodemon $split --exec 'python' $file   --ext py
            break
        }
        ".jlk" {
            nodemon $split --exec 'jlink' $file   --ext jlk
            break
        }
        ".js" {
            nodemon $split $file
        }
        ".tcl" {
            tclsh.exe $split $file
        }
        ".rb" {
            nodemon $split $file --config nodemon.json
        }
        default { "not supported yet" }
    }
}


function Get-ResetHandler() {
    Get-ChildItem *map -re | Get-Content | Select-String "Reset_Handler"
}

function read-mem() {
    # QuoteList 4006c000 4006c140 | read-mem
    $content = $input | ForEach-Object { "mem32 $_,1" } -END { "q" }
    $jlkFile = New-TemporaryFile
    Set-Content $jlkFile $content
    $content
    jlink.exe $jlkFile
}

function find-fileInDepth($depth = 1, $pattern) {
    Get-ChildItem -Recurse -Depth $depth | Where-Object { $_ -like "*$pattern*" } | Select-Object fullname
}

Function vf () {
    $filepaths = $input | Get-Item | ForEach-Object { $_.fullname }
    vim $filepaths
}

Function eod() {
    Get-ChildItem dl:*eod | Sort-Object -Property LastWriteTime | Select-Object -Last 1 | Invoke-Item
}

function Switch-files ($file1, $file2) {
    Move-Item $file1 '__a__' -Verbose
    Move-Item $file2 $file1 -Verbose
    Move-Item '__a__' $file2 -Verbose
}

function shanghai() { Invoke-Item dl:\shanghai.eod }
function india() { Invoke-Item dl:\india.eod }
function time() { Get-Date -Format "_yyyyMMdd_HH_mm" | Set-Clipboard }
function last() { Get-ChildItem | Sort-Object -Property LastAccessTime -Descending | Select-Object -First 1 | Invoke-Item }
function lastboottime() { Get-CimInstance -ClassName win32_operatingsystem | Select-Object csname, lastbootuptime }
export-modulemember -function *
