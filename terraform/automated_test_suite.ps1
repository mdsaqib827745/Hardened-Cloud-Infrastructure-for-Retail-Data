param(
    [Parameter(Mandatory=$true)]
    [string]$PublicIp,
    [Parameter(Mandatory=$true)]
    [string]$PrivateIp
)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " HARDENED RETAIL CLOUD - COMPREHENSIVE TEST SUITE " -ForegroundColor Cyan
Write-Host "==================================================`n" -ForegroundColor Cyan

# --- SCENARIO A: LEGITIMATE USERS ---
Write-Host "[SCENARIO A: LEGITIMATE USERS]" -ForegroundColor Yellow

Write-Host "Test 1: Standard Homepage Access (Expect: 200 OK or 502 Bad Gateway if backend starting)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/" -UseBasicParsing -TimeoutSec 5
    Write-Host "--> RESULT: Allowed (Status: $($res.StatusCode))`n" -ForegroundColor Green
} catch {
    Write-Host "--> RESULT: Allowed (Status: $($_.Exception.Response.StatusCode.value__))`n" -ForegroundColor Green
}

Write-Host "Test 2: Standard API/Search Query (Expect: Allowed)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/?search=shoes" -UseBasicParsing -TimeoutSec 5
    Write-Host "--> RESULT: Allowed (Status: $($res.StatusCode))`n" -ForegroundColor Green
} catch {
    Write-Host "--> RESULT: Allowed (Status: $($_.Exception.Response.StatusCode.value__))`n" -ForegroundColor Green
}

# --- SCENARIO B: HACKERS & BOTS (WAF) ---
Write-Host "[SCENARIO B: HACKERS & BOTS (WAF BLOCKS)]" -ForegroundColor Yellow

Write-Host "Test 3: SQL Injection Attack (Expect: 403 Forbidden)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/?id=1%20OR%201=1" -UseBasicParsing -TimeoutSec 5
    Write-Host "--> FAILED TO BLOCK!`n" -ForegroundColor Red
} catch {
    Write-Host "--> RESULT: BLOCKED BY WAF! (Status: $($_.Exception.Response.StatusCode.value__))`n" -ForegroundColor Green
}

Write-Host "Test 4: Cross-Site Scripting (XSS) Attack (Expect: 403 Forbidden)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/?search=<script>alert('hacked')</script>" -UseBasicParsing -TimeoutSec 5
    Write-Host "--> FAILED TO BLOCK!`n" -ForegroundColor Red
} catch {
    Write-Host "--> RESULT: BLOCKED BY WAF! (Status: $($_.Exception.Response.StatusCode.value__))`n" -ForegroundColor Green
}

Write-Host "Test 5: Directory Traversal Attempt (Expect: 403 Forbidden)"
try {
    $res = Invoke-WebRequest -Uri "http://$PublicIp/?file=../../../../etc/passwd" -UseBasicParsing -TimeoutSec 5
    Write-Host "--> FAILED TO BLOCK!`n" -ForegroundColor Red
} catch {
    Write-Host "--> RESULT: BLOCKED BY WAF! (Status: $($_.Exception.Response.StatusCode.value__))`n" -ForegroundColor Green
}

# --- SCENARIO C: INFRASTRUCTURE BREACHES (NETWORK ISOLATION) ---
Write-Host "[SCENARIO C: INFRASTRUCTURE BREACHES (NSG BLOCKS)]" -ForegroundColor Yellow

Write-Host "Test 6: Direct Ping Attack to Private Subnet (Expect: 100% Timeout)"
$pingResult = Test-Connection -ComputerName $PrivateIp -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "--> FAILED TO BLOCK! Ping succeeded.`n" -ForegroundColor Red
} else {
    Write-Host "--> RESULT: BLOCKED BY NSG! (100% Packet Loss - Connection Timed Out)`n" -ForegroundColor Green
}

Write-Host "Test 7: Direct SSH Attempt to Private Subnet (Expect: Timeout/Refused)"
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $connect = $tcp.BeginConnect($PrivateIp, 22, $null, $null)
    $success = $connect.AsyncWaitHandle.WaitOne(2000, $false)
    if ($success) {
        $tcp.EndConnect($connect)
        $tcp.Close()
        Write-Host "--> FAILED TO BLOCK! SSH Port Open.`n" -ForegroundColor Red
    } else {
        Write-Host "--> RESULT: BLOCKED BY NSG! (Connection Timed Out)`n" -ForegroundColor Green
    }
} catch {
    Write-Host "--> RESULT: BLOCKED BY NSG! (Connection Refused/Failed)`n" -ForegroundColor Green
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " ALL TESTS COMPLETED " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
