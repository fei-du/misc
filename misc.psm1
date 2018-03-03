function get-bits($base, $startBit, $endBit)
{
     if ( $endBit -eq $null) {$endBit = $startBit}
     $string = $input |  Select-String "^.{5}$base" 
     $string
     $value = $string | ConvertFrom-String | % { ([convert]::ToString("0x$($_.p3)", 2)).padleft(32, '0').tochararray()[(31-$endBit)..(31-$startBit)] } | join-string
     "$base[$endBit" + ":"+ "$startBit" + "] = $value"
}


function com {
    [System.IO.Ports.SerialPort]::GetPortNames()
}

function Hex($decimal, $base=16) {
    [convert]::ToString($decimal, $base)
}

function jl{
    JLink.exe -new_console:s
}

function nm($file, [switch]$v){
	$ex = gci $file | select -ExpandProperty extension
	if($v){
	    $split = '-new_console:s40V'
	} else{
	    $split = '-new_console:s40H'
	}
	switch($ex){
		".ps1" {
		    nodemon $split --exec 'C:\windows\System32\WindowsPowerShell\v1.0\powershell.exe -noprofile' $file   --ext ps1
		    break
		    }
		".R"{
		    # somehow not working when updating node from v6 to v8

		    $env:Path += ";C:\Program Files\R\R-3.4.0\bin\"
		    nodemon $split --exec 'Rscript.exe' $file   --ext R
		    break
		    }
		# ".py"{
		#     nodemon $split --exec 'python' $file   --ext py
		#     break
		# }
		".jlk"{
		    nodemon $split --exec 'jlink' $file   --ext jlk
		    break
		    }
		".js"{
			nodemon $split $file
		    }
		default {"not supported yet"}
	    }
}

export-modulemember -function get-bits, com, hex, jl, nm
