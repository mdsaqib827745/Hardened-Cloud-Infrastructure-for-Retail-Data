$rg = "rg-retail-hardened-prod"
$vm = "vm-retail-web"
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

$files = @(
    "auth.py",
    "blob_utils.py",
    "app.py",
    "templates/base.html",
    "templates/login.html",
    "templates/index.html",
    "templates/decrypt.html"
)

foreach ($f in $files) {
    Write-Host "Deploying $f..."
    # Ensure directory exists on VM
    if ($f -match "/") {
        $dir = Split-Path $f -Parent
        $cmdDir = "mkdir -p /home/azureuser/retailvault/$dir"
        az vm run-command invoke -g $rg -n $vm --command-id RunShellScript --scripts $cmdDir | Out-Null
    }

    $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("e:\saqib\app\$f"))
    $cmd = "echo '$b64' | base64 -d > /home/azureuser/retailvault/$f && wc -c /home/azureuser/retailvault/$f"
    $result = az vm run-command invoke -g $rg -n $vm --command-id RunShellScript --scripts $cmd 2>&1
    Write-Host $result
}

Write-Host "Configuring Nginx and starting Gunicorn..."
$cmdFinal = @'
sudo tee /etc/nginx/sites-available/retailvault > /dev/null << 'NGEOF'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGEOF
sudo ln -sf /etc/nginx/sites-available/retailvault /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx
sudo pkill gunicorn 2>/dev/null || true
cd /home/azureuser/retailvault
nohup gunicorn --workers 3 --bind 127.0.0.1:5000 app:app > /home/azureuser/retailvault/app.log 2>&1 &
sleep 2
ps aux | grep gunicorn | grep -v grep
'@

# It might be safer to pass $cmdFinal in a way that doesn't mess up quotes, or just do a bash one-liner.
$cmdFinal = "sudo bash -c `"cat > /etc/nginx/sites-available/retailvault << 'NGEOF'`nserver { listen 80; server_name _; location / { proxy_pass http://127.0.0.1:5000; proxy_set_header Host `$host; proxy_set_header X-Real-IP `$remote_addr; proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto `$scheme; } }`nNGEOF`n`"; sudo ln -sf /etc/nginx/sites-available/retailvault /etc/nginx/sites-enabled/; sudo rm -f /etc/nginx/sites-enabled/default; sudo systemctl restart nginx; sudo pkill gunicorn 2>/dev/null || true; cd /home/azureuser/retailvault; nohup gunicorn --workers 3 --bind 127.0.0.1:5000 app:app > /home/azureuser/retailvault/app.log 2>&1 & sleep 2; ps aux | grep gunicorn | grep -v grep"

$resultFinal = az vm run-command invoke -g $rg -n $vm --command-id RunShellScript --scripts $cmdFinal 2>&1
Write-Host $resultFinal
Write-Host "Deployment Complete."
