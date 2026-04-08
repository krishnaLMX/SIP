Get-ChildItem -Path lib -Recurse -Filter *.dart | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    if ($content.Contains('â‚¹')) {
        $content = $content.Replace('â‚¹', '₹')
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed $($_.FullName)"
    }
}
