function get-bits($base, $startBit, $endBit)
{
     if ( $endBit -eq $null) {$endBit = $startBit}
     $string = $input |  Select-String "^.{5}$base" 
     $string
     $value = $string | ConvertFrom-String | % { ([convert]::ToString("0x$($_.p3)", 2)).padleft(32, '0').tochararray()[(31-$endBit)..(31-$startBit)] } | join-string
     "$base[$endBit" + ":"+ "$startBit" + "] = $value"
}

export-modulemember -function get-bits
