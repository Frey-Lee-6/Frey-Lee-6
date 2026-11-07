param(
  [switch]$SelfTest
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$ApiBase = "https://api.frankfurter.app"
$SettingsDir = Join-Path $env:APPDATA "FxDesktopWidget"
$SettingsPath = Join-Path $SettingsDir "settings.json"
$FallbackCurrencies = @("EUR", "CNY", "USD", "HKD", "JPY", "GBP", "AUD", "CAD", "CHF", "SGD")

$Text = @{
  zh = @{
    AppTitle = "汇率桌面插件"
    Waiting = "等待刷新"
    Refresh = "刷新"
    LastYears = "近 N 年"
    Amount = "兑换金额"
    Lowest = "近 {0} 年最低点"
    Highest = "近 {0} 年最高点"
    Receive = "可兑换"
    LessThanLowest = "相比最低点少得"
    MoreThanHighest = "相比最高点多得"
    Source = "数据源：Frankfurter；每 60 秒自动刷新"
    Updated = "已更新"
    Updating = "刷新中"
    Failed = "刷新失败"
    PickTwo = "请选择不同币种"
    UpdatedSuffix = "更新"
    UseToBuy = "用 {0} 兑换 {1}"
    LanguageButton = "EN"
  }
  en = @{
    AppTitle = "FX Desktop Widget"
    Waiting = "Waiting"
    Refresh = "Refresh"
    LastYears = "Last N years"
    Amount = "Amount in quote"
    Lowest = "Lowest in {0} years"
    Highest = "Highest in {0} years"
    Receive = "You receive"
    LessThanLowest = "Less than lowest"
    MoreThanHighest = "More than highest"
    Source = "Source: Frankfurter. Auto refresh: 60 seconds."
    Updated = "Updated"
    Updating = "Refreshing"
    Failed = "Failed"
    PickTwo = "Pick two currencies"
    UpdatedSuffix = "updated"
    UseToBuy = "Use {0} to buy {1}"
    LanguageButton = "中"
  }
}

function ConvertTo-IsoDate($date) {
  return $date.ToUniversalTime().ToString("yyyy-MM-dd")
}

function Get-MinMax($points) {
  $low = $null
  $high = $null
  foreach ($point in $points) {
    if ($null -eq $low -or $point.Rate -lt $low.Rate) { $low = $point }
    if ($null -eq $high -or $point.Rate -gt $high.Rate) { $high = $point }
  }
  return [pscustomobject]@{ Low = $low; High = $high }
}

function Get-Comparison($amount, $currentRate, $lowRate, $highRate) {
  $receivedNow = $amount / $currentRate
  $receivedAtLow = $amount / $lowRate
  $receivedAtHigh = $amount / $highRate
  return [pscustomobject]@{
    ReceivedNow = $receivedNow
    LossInQuote = [Math]::Max(0.0, [double]($receivedAtLow - $receivedNow)) * $currentRate
    SavingInQuote = [Math]::Max(0.0, [double]($receivedNow - $receivedAtHigh)) * $currentRate
  }
}

function Format-Rate($value) {
  return "{0:N6}" -f [double]$value
}

function Format-Money($value, $currency) {
  return "{0} {1:N2}" -f $currency, [double]$value
}

function Read-Settings {
  if (Test-Path $SettingsPath) {
    try {
      return Get-Content -Raw -Encoding UTF8 $SettingsPath | ConvertFrom-Json
    } catch {}
  }
  return [pscustomobject]@{ Base = "EUR"; Quote = "CNY"; Years = 5; Amount = 10000; Language = "zh" }
}

function Save-Settings($base, $quote, $years, $amount, $language) {
  if (-not (Test-Path $SettingsDir)) {
    New-Item -ItemType Directory -Path $SettingsDir | Out-Null
  }
  [pscustomobject]@{
    Base = $base
    Quote = $quote
    Years = $years
    Amount = $amount
    Language = $language
  } | ConvertTo-Json | Set-Content -Encoding UTF8 $SettingsPath
}

function Invoke-FxJson($url) {
  return Invoke-RestMethod -Uri $url -TimeoutSec 20
}

function Get-Currencies {
  try {
    $rows = Invoke-FxJson "$ApiBase/currencies"
    return ($rows.PSObject.Properties.Name + $FallbackCurrencies | Sort-Object -Unique)
  } catch {
    return $FallbackCurrencies
  }
}

function Get-LatestRate($base, $quote) {
  $data = Invoke-FxJson "$ApiBase/latest?from=$base&to=$quote"
  return [pscustomobject]@{
    Date = $data.date
    Rate = [double]$data.rates.$quote
  }
}

function Get-History($base, $quote, $years) {
  $to = Get-Date
  $from = $to.AddYears(-1 * [int]$years)
  $range = "$(ConvertTo-IsoDate $from)..$(ConvertTo-IsoDate $to)"
  $data = Invoke-FxJson "$ApiBase/$range`?from=$base&to=$quote"
  $points = New-Object System.Collections.Generic.List[object]

  foreach ($prop in $data.rates.PSObject.Properties) {
    $rate = $prop.Value.$quote
    if ($null -ne $rate) {
      $points.Add([pscustomobject]@{ Date = $prop.Name; Rate = [double]$rate })
    }
  }

  return $points | Sort-Object Date
}

if ($SelfTest) {
  $comparison = Get-Comparison 10000 8 7.5 8.5
  if ([Math]::Abs($comparison.ReceivedNow - 1250) -gt 0.0001) { throw "ReceivedNow test failed" }
  if ([Math]::Abs($comparison.LossInQuote - 666.6667) -gt 0.01) { throw "LossInQuote test failed" }
  if ([Math]::Abs($comparison.SavingInQuote - 588.2353) -gt 0.01) { throw "SavingInQuote test failed" }
  Write-Host "PowerShell widget tests passed"
  exit 0
}

$settings = Read-Settings
$currencies = Get-Currencies
$script:language = if ($settings.Language -in @("zh", "en")) { $settings.Language } else { "zh" }

$form = New-Object System.Windows.Forms.Form
$form.Text = $Text[$script:language].AppTitle
$form.Size = New-Object System.Drawing.Size(430, 610)
$form.MinimumSize = New-Object System.Drawing.Size(390, 560)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(244, 247, 250)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$title = New-Object System.Windows.Forms.Label
$title.Text = "EUR/CNY"
$title.Location = New-Object System.Drawing.Point(18, 16)
$title.Size = New-Object System.Drawing.Size(190, 36)
$title.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($title)

$status = New-Object System.Windows.Forms.Label
$status.Text = $Text[$script:language].Waiting
$status.Location = New-Object System.Drawing.Point(230, 24)
$status.Size = New-Object System.Drawing.Size(160, 22)
$status.TextAlign = "MiddleRight"
$form.Controls.Add($status)

$rateLabel = New-Object System.Windows.Forms.Label
$rateLabel.Text = "--"
$rateLabel.Location = New-Object System.Drawing.Point(18, 70)
$rateLabel.Size = New-Object System.Drawing.Size(370, 54)
$rateLabel.Font = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($rateLabel)

$updateLabel = New-Object System.Windows.Forms.Label
$updateLabel.Text = "--"
$updateLabel.Location = New-Object System.Drawing.Point(20, 126)
$updateLabel.Size = New-Object System.Drawing.Size(370, 22)
$updateLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($updateLabel)

$baseBox = New-Object System.Windows.Forms.ComboBox
$baseBox.Location = New-Object System.Drawing.Point(20, 178)
$baseBox.Size = New-Object System.Drawing.Size(118, 28)
$baseBox.DropDownStyle = "DropDownList"
[void]$baseBox.Items.AddRange($currencies)
if ($currencies -contains $settings.Base) { $baseBox.SelectedItem = $settings.Base } else { $baseBox.SelectedItem = "EUR" }
$form.Controls.Add($baseBox)

$swapButton = New-Object System.Windows.Forms.Button
$swapButton.Text = "<>"
$swapButton.Location = New-Object System.Drawing.Point(150, 177)
$swapButton.Size = New-Object System.Drawing.Size(42, 30)
$form.Controls.Add($swapButton)

$quoteBox = New-Object System.Windows.Forms.ComboBox
$quoteBox.Location = New-Object System.Drawing.Point(204, 178)
$quoteBox.Size = New-Object System.Drawing.Size(118, 28)
$quoteBox.DropDownStyle = "DropDownList"
[void]$quoteBox.Items.AddRange($currencies)
if ($currencies -contains $settings.Quote) { $quoteBox.SelectedItem = $settings.Quote } else { $quoteBox.SelectedItem = "CNY" }
$form.Controls.Add($quoteBox)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = $Text[$script:language].Refresh
$refreshButton.Location = New-Object System.Drawing.Point(324, 177)
$refreshButton.Size = New-Object System.Drawing.Size(68, 30)
$form.Controls.Add($refreshButton)

$languageButton = New-Object System.Windows.Forms.Button
$languageButton.Text = $Text[$script:language].LanguageButton
$languageButton.Location = New-Object System.Drawing.Point(334, 22)
$languageButton.Size = New-Object System.Drawing.Size(58, 28)
$form.Controls.Add($languageButton)

$yearsLabel = New-Object System.Windows.Forms.Label
$yearsLabel.Text = $Text[$script:language].LastYears
$yearsLabel.Location = New-Object System.Drawing.Point(20, 224)
$yearsLabel.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($yearsLabel)

$yearsBox = New-Object System.Windows.Forms.NumericUpDown
$yearsBox.Location = New-Object System.Drawing.Point(20, 248)
$yearsBox.Size = New-Object System.Drawing.Size(118, 28)
$yearsBox.Minimum = 1
$yearsBox.Maximum = 30
$yearsBox.Value = [decimal]([Math]::Min(30, [Math]::Max(1, [int]$settings.Years)))
$form.Controls.Add($yearsBox)

$amountLabel = New-Object System.Windows.Forms.Label
$amountLabel.Text = $Text[$script:language].Amount
$amountLabel.Location = New-Object System.Drawing.Point(160, 224)
$amountLabel.Size = New-Object System.Drawing.Size(140, 20)
$form.Controls.Add($amountLabel)

$amountBox = New-Object System.Windows.Forms.NumericUpDown
$amountBox.Location = New-Object System.Drawing.Point(160, 248)
$amountBox.Size = New-Object System.Drawing.Size(232, 28)
$amountBox.Minimum = 1
$amountBox.Maximum = 1000000000
$amountBox.Increment = 100
$amountBox.DecimalPlaces = 2
$amountBox.Value = [decimal]([Math]::Min(1000000000, [Math]::Max(1, [double]$settings.Amount)))
$form.Controls.Add($amountBox)

$lowLabel = New-Object System.Windows.Forms.Label
$lowLabel.Text = ($Text[$script:language].Lowest -f "N") + "`r`n--"
$lowLabel.Location = New-Object System.Drawing.Point(20, 305)
$lowLabel.Size = New-Object System.Drawing.Size(180, 70)
$lowLabel.BorderStyle = "FixedSingle"
$lowLabel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($lowLabel)

$highLabel = New-Object System.Windows.Forms.Label
$highLabel.Text = ($Text[$script:language].Highest -f "N") + "`r`n--"
$highLabel.Location = New-Object System.Drawing.Point(212, 305)
$highLabel.Size = New-Object System.Drawing.Size(180, 70)
$highLabel.BorderStyle = "FixedSingle"
$highLabel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($highLabel)

$receiveLabel = New-Object System.Windows.Forms.Label
$receiveLabel.Text = "$($Text[$script:language].Receive)`r`n--"
$receiveLabel.Location = New-Object System.Drawing.Point(20, 398)
$receiveLabel.Size = New-Object System.Drawing.Size(372, 52)
$receiveLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($receiveLabel)

$lossLabel = New-Object System.Windows.Forms.Label
$lossLabel.Text = "$($Text[$script:language].LessThanLowest)`r`n--"
$lossLabel.Location = New-Object System.Drawing.Point(20, 465)
$lossLabel.Size = New-Object System.Drawing.Size(180, 62)
$lossLabel.BorderStyle = "FixedSingle"
$lossLabel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($lossLabel)

$savingLabel = New-Object System.Windows.Forms.Label
$savingLabel.Text = "$($Text[$script:language].MoreThanHighest)`r`n--"
$savingLabel.Location = New-Object System.Drawing.Point(212, 465)
$savingLabel.Size = New-Object System.Drawing.Size(180, 62)
$savingLabel.BorderStyle = "FixedSingle"
$savingLabel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($savingLabel)

$hintLabel = New-Object System.Windows.Forms.Label
$hintLabel.Text = $Text[$script:language].Source
$hintLabel.Location = New-Object System.Drawing.Point(20, 545)
$hintLabel.Size = New-Object System.Drawing.Size(372, 22)
$hintLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($hintLabel)

$script:lastData = $null
$script:isRefreshing = $false

function Apply-Language {
  $t = $Text[$script:language]
  $form.Text = $t.AppTitle
  $refreshButton.Text = $t.Refresh
  $languageButton.Text = $t.LanguageButton
  $yearsLabel.Text = $t.LastYears
  $amountLabel.Text = $t.Amount
  $hintLabel.Text = $t.Source
  if ($null -eq $script:lastData) {
    $status.Text = $t.Waiting
    $lowLabel.Text = ($t.Lowest -f "N") + "`r`n--"
    $highLabel.Text = ($t.Highest -f "N") + "`r`n--"
    $receiveLabel.Text = "$($t.Receive)`r`n--"
    $lossLabel.Text = "$($t.LessThanLowest)`r`n--"
    $savingLabel.Text = "$($t.MoreThanHighest)`r`n--"
  }
}

function Render-Data($latest, $history) {
  $base = [string]$baseBox.SelectedItem
  $quote = [string]$quoteBox.SelectedItem
  $amount = [double]$amountBox.Value
  $extreme = Get-MinMax $history
  $comparison = Get-Comparison $amount $latest.Rate $extreme.Low.Rate $extreme.High.Rate
  $t = $Text[$script:language]

  $title.Text = "$base/$quote"
  $rateLabel.Text = "1 $base = $(Format-Rate $latest.Rate) $quote"
  $updateLabel.Text = "$($latest.Date) $($t.UpdatedSuffix)"
  $lowLabel.Text = ($t.Lowest -f [int]$yearsBox.Value) + "`r`n$(Format-Rate $extreme.Low.Rate)`r`n$($extreme.Low.Date)"
  $highLabel.Text = ($t.Highest -f [int]$yearsBox.Value) + "`r`n$(Format-Rate $extreme.High.Rate)`r`n$($extreme.High.Date)"
  $receiveLabel.Text = ($t.UseToBuy -f (Format-Money $amount $quote), $base) + "`r`n$("{0:N4}" -f $comparison.ReceivedNow) $base"
  $lossLabel.Text = "$($t.LessThanLowest)`r`n$(Format-Money $comparison.LossInQuote $quote)"
  $savingLabel.Text = "$($t.MoreThanHighest)`r`n$(Format-Money $comparison.SavingInQuote $quote)"
}

function Refresh-Data {
  if ($script:isRefreshing) { return }

  $base = [string]$baseBox.SelectedItem
  $quote = [string]$quoteBox.SelectedItem
  $years = [int]$yearsBox.Value
  $amount = [double]$amountBox.Value

  if ($base -eq $quote) {
    $status.Text = $Text[$script:language].PickTwo
    return
  }

  Save-Settings $base $quote $years $amount $script:language
  $status.Text = $Text[$script:language].Updating
  $refreshButton.Enabled = $false
  $script:isRefreshing = $true

  try {
    $latest = Get-LatestRate $base $quote
    $history = Get-History $base $quote $years
    if (-not $history -or $history.Count -eq 0) { throw "No history returned" }
    $script:lastData = [pscustomobject]@{ Latest = $latest; History = $history }
    Render-Data $latest $history
    $status.Text = $Text[$script:language].Updated
  } catch {
    $status.Text = $Text[$script:language].Failed
    $updateLabel.Text = $_.Exception.Message
  } finally {
    $refreshButton.Enabled = $true
    $script:isRefreshing = $false
  }
}

$refreshButton.Add_Click({ Refresh-Data })
$baseBox.Add_SelectedIndexChanged({ Refresh-Data })
$quoteBox.Add_SelectedIndexChanged({ Refresh-Data })
$yearsBox.Add_ValueChanged({ Refresh-Data })
$amountBox.Add_ValueChanged({
  if ($null -ne $script:lastData) {
    Render-Data $script:lastData.Latest $script:lastData.History
    Save-Settings ([string]$baseBox.SelectedItem) ([string]$quoteBox.SelectedItem) ([int]$yearsBox.Value) ([double]$amountBox.Value) $script:language
  }
})
$swapButton.Add_Click({
  $oldBase = $baseBox.SelectedItem
  $baseBox.SelectedItem = $quoteBox.SelectedItem
  $quoteBox.SelectedItem = $oldBase
})

$languageButton.Add_Click({
  if ($script:language -eq "zh") { $script:language = "en" } else { $script:language = "zh" }
  Apply-Language
  if ($null -ne $script:lastData) {
    Render-Data $script:lastData.Latest $script:lastData.History
  }
  Save-Settings ([string]$baseBox.SelectedItem) ([string]$quoteBox.SelectedItem) ([int]$yearsBox.Value) ([double]$amountBox.Value) $script:language
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000
$timer.Add_Tick({ Refresh-Data })
$timer.Start()

$form.Add_Shown({ Refresh-Data })
[void]$form.ShowDialog()
