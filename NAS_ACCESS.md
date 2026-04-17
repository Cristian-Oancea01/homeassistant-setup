# NAS Access & MCP — OpenCode Reference

## NAS details
- **Host**: 192.168.68.106
- **SMB user**: MCP
- **SMB password**: stored in `C:\Users\oance\.config\opencode\opencode.json` under `_nas`
- **MCP token**: stored in `opencode.json` under `mcp.QNAP NAS.headers.Authorization`

---

## Mount NAS share in OpenCode session

Run this at the start of any session that needs to read/write NAS files.
Z: is the recommended drive letter (check it's free first).

```powershell
# Check if already mounted
Get-PSDrive Z -ErrorAction SilentlyContinue

# Mount (replace password from opencode.json if rotated)
$cred = New-Object System.Management.Automation.PSCredential(
    "MCP",
    (ConvertTo-SecureString "95zMsNR@B2HzeHB" -AsPlainText -Force)
)
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\192.168.68.106\Public" -Credential $cred -Persist
```

After mounting:
- HA config is at `Z:\HomeAssistantConfig\`
- Backups land at `Z:\HomeAssistantConfig_backup_<date>\`

### Unmount when done
```powershell
Remove-PSDrive Z
```

---

## QNAP MCP server

- **URL**: http://192.168.68.106:8442/sse
- **Protocol**: MCP JSON-RPC 2.0 over SSE (Server-Sent Events)
- **Auth**: Bearer token (see opencode.json)
- **App**: "MCP Assistant" (qmcp) QPKG on the NAS — must be running

### Check if MCP is online
```powershell
Test-NetConnection -ComputerName 192.168.68.106 -Port 8442
# TcpTestSucceeded: True = server is up
```

### Call an MCP tool via PowerShell (reusable script)

Save this as `C:\Users\oance\AppData\Local\Temp\mcp_call.ps1` or use the existing one.

```powershell
# Usage: .\mcp_call.ps1 -ToolName "list_qpkgs" -Arguments '{}'
param([string]$ToolName, [string]$Arguments = '{}')

$token = 'gHgWU1L4NaKoihHzMyU22UoGQC6SUWeGEuTySB8EowHo3hgtunFS86O2PVZSDFr0'
$baseUrl = 'http://192.168.68.106:8442'

Add-Type -AssemblyName System.Net.Http
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [System.TimeSpan]::FromSeconds(30)
$client.DefaultRequestHeaders.Add('Authorization', "Bearer $token")

$cts = New-Object System.Threading.CancellationTokenSource
$cts.CancelAfter(25000)

$request = New-Object System.Net.Http.HttpRequestMessage(
    [System.Net.Http.HttpMethod]::Get, "$baseUrl/sse"
)
$response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $cts.Token).GetAwaiter().GetResult()
$reader = New-Object System.IO.StreamReader($response.Content.ReadAsStreamAsync().GetAwaiter().GetResult())

# Read SSE until endpoint line
$sessionUrl = $null
for ($i = 0; $i -lt 20; $i++) {
    $line = $reader.ReadLineAsync(); if (-not $line.Wait(4000)) { break }
    if ($line.Result -match 'data:\s*(/message\?sessionId=.+)') { $sessionUrl = $Matches[1]; break }
}
if (-not $sessionUrl) { Write-Error 'No session'; exit 1 }

# POST the tool call
$body = "{`"jsonrpc`":`"2.0`",`"id`":1,`"method`":`"tools/call`",`"params`":{`"name`":`"$ToolName`",`"arguments`":$Arguments}}"
$postClient = New-Object System.Net.Http.HttpClient
$postClient.DefaultRequestHeaders.Add('Authorization', "Bearer $token")
$postClient.PostAsync("$baseUrl$sessionUrl",
    (New-Object System.Net.Http.StringContent($body, [System.Text.Encoding]::UTF8, 'application/json'))
).GetAwaiter().GetResult() | Out-Null

# Read response from SSE stream
for ($i = 0; $i -lt 40; $i++) {
    $line = $reader.ReadLineAsync(); if (-not $line.Wait(5000)) { Write-Host 'Timeout'; break }
    if ($line.Result -match '"result"') { Write-Host $line.Result; break }
}
$cts.Cancel(); $client.Dispose()
```

### Available MCP tools
| Tool | Description |
|------|-------------|
| `list_qpkgs` | List installed QNAP apps |
| `get_system_info` | CPU, memory, storage, network |
| `list_shared_folder` | List all shared folders |
| `get_shared_folder` | Folder info + permissions |
| `list_files` | Browse files (slow, often times out — use SMB instead) |
| `search_files` | File Station search |
| `advanced_search` | Qsirch full-text search |
| `create_folder` | Create a subfolder |
| `create_shared_folder` | Create a new shared folder |
| `list_storages` | Storage pools, RAID, disks |
| `list_logs` | NAS system logs |
| `get_qvr_logs` | QVR surveillance logs |
| `query_load_avg` | Load average over time |
| `query_top_processes` | Top processes |
| `update_shared_folder_permission` | Update folder ACL |

> **Note**: `list_files`, `search_files`, `advanced_search` frequently time out on large shares.
> Use the SMB mount (Z:) for direct file access instead.

---

## HA config location on NAS
```
\\192.168.68.106\Public\HomeAssistantConfig\
  configuration.yaml          ← main config
  automations/
    existing.yaml             ← original 3 automations (dishwasher, sunset lamp)
    blinds.yaml               ← VELUX (placeholders — needs real entity IDs)
    climate.yaml              ← AC (placeholders — ACs not set up yet)
    lighting.yaml             ← Hue motion lights (needs Hue motion sensor IDs)
    ventilation.yaml          ← Komfovent (fix: wrong entity ID names)
  integrations/
    cover_groups.yaml         ← VELUX group (placeholders)
    groups.yaml               ← Presence group (fix: wrong person entity IDs)
    google_assistant.yaml     ← Disabled (needs HTTPS + credentials)
  lovelace/
    ui-lovelace.yaml          ← Dashboard entry point
    views/01_home.yaml .. 06_settings.yaml
  secrets.yaml
  custom_components/
    komfovent/                ← Modbus HRV integration (working)
    miele/                    ← Dishwasher (auth expired — needs re-auth)
    hacs/                     ← HACS package manager (working)
    govee_light_ble/          ← Govee BLE (archived repo, consider removing)
```

## Backup convention
Before any changes:
```powershell
# Run nas_backup.ps1 or manually:
$date = Get-Date -Format 'yyyyMMdd_HHmmss'
# Script at: C:\Users\oance\AppData\Local\Temp\nas_backup.ps1
powershell -ExecutionPolicy Bypass -File "C:\Users\oance\AppData\Local\Temp\nas_backup.ps1"
# Creates: Z:\HomeAssistantConfig_backup_<date>\
```
