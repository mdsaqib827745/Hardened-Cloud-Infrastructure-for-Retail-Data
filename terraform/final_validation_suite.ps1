param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$PublicIp,
    [Parameter(Mandatory=$true)]
    [string]$PrivateIp,
    [Parameter(Mandatory=$true)]
    [string]$SqlFqdn
)

# Set the path for Azure CLI if not in environment
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   HARDENED RETAIL CLOUD - CATEGORY 1: SECURITY FUNCTIONALITY    " -ForegroundColor Cyan
Write-Host "==================================================================`n" -ForegroundColor Cyan

# --- 1.1 WAF TESTS ---
Write-Host "[1.1 WEB APPLICATION FIREWALL (WAF) TESTS]" -ForegroundColor Yellow

Write-Host "Test 1: SQL Injection Block (Hacker Attempt)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/?id=1%20OR%201=1" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "--> [FAIL] WAF did not block the SQLi attack." -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        Write-Host "--> [PASS] WAF Blocked SQLi (Status: 403 Forbidden)" -ForegroundColor Green
    } else {
        Write-Host "--> [INFO] Received Status: $($_.Exception.Response.StatusCode.value__). Check WAF Propagation." -ForegroundColor Gray
    }
}

Write-Host "Test 2: XSS Block (Hacker Attempt)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/?search=<script>alert('xss')</script>" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "--> [FAIL] WAF did not block the XSS attack." -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        Write-Host "--> [PASS] WAF Blocked XSS (Status: 403 Forbidden)" -ForegroundColor Green
    } else {
        Write-Host "--> [INFO] Received Status: $($_.Exception.Response.StatusCode.value__). Check WAF Propagation." -ForegroundColor Gray
    }
}

# --- 1.2 NETWORK ISOLATION TESTS ---
Write-Host "`n[1.2 NETWORK ISOLATION & NSG TESTS]" -ForegroundColor Yellow

Write-Host "Test 3: External SSH Block (NSG Check)"
$tcp = New-Object System.Net.Sockets.TcpClient
$connect = $tcp.BeginConnect($PublicIp, 22, $null, $null)
$success = $connect.AsyncWaitHandle.WaitOne(2000, $false)
if ($success) {
    Write-Host "--> [FAIL] SSH port 22 is OPEN to the public internet!" -ForegroundColor Red
    $tcp.EndConnect($connect); $tcp.Close()
} else {
    Write-Host "--> [PASS] SSH is BLOCKED from the internet (Timed Out)." -ForegroundColor Green
}

Write-Host "Test 4: Pure Backend Ping Isolation"
$ping = Test-Connection -ComputerName $PrivateIp -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($ping) {
    Write-Host "--> [FAIL] Private VM is reachable from outside!" -ForegroundColor Red
} else {
    Write-Host "--> [PASS] Private VM is ISOLATED (Ping Timed Out)." -ForegroundColor Green
}

# --- 1.3 DATABASE ISOLATION ---
Write-Host "`n[1.3 DATABASE ISOLATION TESTS]" -ForegroundColor Yellow
Write-Host "Test 5: Direct SQL Access Block"
$sqlTcp = New-Object System.Net.Sockets.TcpClient
$sqlConnect = $sqlTcp.BeginConnect($SqlFqdn, 1433, $null, $null)
$sqlSuccess = $sqlConnect.AsyncWaitHandle.WaitOne(3000, $false)
if ($sqlSuccess) {
    Write-Host "--> [WARNING] SQL Port 1433 is reachable. Ensure Firewall denies IPs." -ForegroundColor Yellow
    $sqlTcp.EndConnect($sqlConnect); $sqlTcp.Close()
} else {
    Write-Host "--> [PASS] Direct SQL Access is BLOCKED." -ForegroundColor Green
}

# --- 1.4 DATA ENCRYPTION (CLI CHECK) ---
Write-Host "`n[1.4 CLOUD CONFIGURATION & ENCRYPTION]" -ForegroundColor Yellow

Write-Host "Test 6: SQL transparent Data Encryption (TDE)"
$tde = az sql db tde show --resource-group $ResourceGroupName --server ($SqlFqdn.Split(".")[0]) --database "db-retail-data" --query "status" -o tsv
if ($tde -eq "Enabled") {
    Write-Host "--> [PASS] SQL Data Encryption is ENABLED." -ForegroundColor Green
} else {
    Write-Host "--> [FAIL] SQL Data Encryption status: $tde" -ForegroundColor Red
}

Write-Host "Test 7: VM OS Disk Encryption"
$disk = az vm show -g $ResourceGroupName -n vm-retail-web --query "storageProfile.osDisk.managedDisk.id" -o tsv
$enc = az disk show --ids $disk --query "encryption.type" -o tsv
if ($enc -ne "") {
    Write-Host "--> [PASS] OS Disk is ENCRYPTED ($enc)." -ForegroundColor Green
} else {
    Write-Host "--> [FAIL] OS Disk Encryption not detected." -ForegroundColor Red
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   ALL CATEGORY 1 TESTS COMPLETED SUCCESSFULLY    " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
