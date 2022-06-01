
param (
    [Parameter()]
    [string]
    $inputfile,

    [Parameter()]
    [string]
    $outputfile
)

If ($NULL -eq $inputfile){$inputfile = Read-Host -Prompt "Please provide full path to inputfile"}
If ($NULL -eq $outputfile){$outputfile = Read-Host -Prompt "Please provide full path to outputfile"}

$syncscope = Get-Content $inputfile | ConvertFrom-Json

Foreach ($connector in $syncscope)
{
    $connector.domainName | Out-File $outputfile -Append
    $domlen = $connector.domainName.split(".").count
    Foreach ($syncou in $connector.syncedou)
    {
        $ouarray = $syncou.split(",")
        $arrlength = $ouarray.length-$domlen-1
        $revarr = $NULL
        Do
        {
            $revarr += $ouarray[$arrlength].split("=")[1] + "\"
            $arrlength = $arrlength - 1
        } While ($arrlength -ge 0)
        "`t" + $revarr.substring(0,$revarr.Length-1) | Out-File $outputfile -Append
    }
    "`n" | Out-File $outputfile -Append
}