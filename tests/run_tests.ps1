#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

function Split-Numbers($s) {
    $list = @()
    foreach ($m in ([regex]::Matches([string]$s,'[0-9]+'))) { $list += [int]$m.Value }
    return $list
}

function Compare-Versions($a, $b) {
    if (-not $a -or -not $b) { return 0 }
    $a = $a -replace '^v',''
    $b = $b -replace '^v',''
    $ta = Split-Numbers $a
    $tb = Split-Numbers $b
    $n = [Math]::Max($ta.Count, $tb.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $va = if ($i -lt $ta.Count) { $ta[$i] } else { 0 }
        $vb = if ($i -lt $tb.Count) { $tb[$i] } else { 0 }
        if ($va -lt $vb) { return -1 }
        if ($va -gt $vb) { return 1 }
    }
    return 0
}

$tests = @(
    @{ a='1.2.3'; b='1.2.3'; expected=0; name='equal versions' },
    @{ a='1.2.3'; b='1.2.4'; expected=-1; name='older' },
    @{ a='1.3.0'; b='1.2.99'; expected=1; name='newer' },
    @{ a='v1.2'; b='1.2.0'; expected=0; name='v prefix and padding' }
)

$ok = $true
foreach ($t in $tests) {
    $res = Compare-Versions $t.a $t.b
    if ($res -ne $t.expected) {
        Write-Host "TEST FAIL: $($t.name) - expected $($t.expected) got $res"
        $ok = $false
    }
}

if ($ok) { Write-Host 'version compare tests: OK'; exit 0 } else { exit 1 }
