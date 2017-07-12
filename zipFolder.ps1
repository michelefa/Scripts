Param(
[string]$in,
[string]$out
)

Add-Type -assembly "system.io.compression.filesystem"

If(Test-path $out) {Remove-item $out}

[io.compression.zipfile]::CreateFromDirectory($in, $out)