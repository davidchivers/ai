# Price Monitor — Setup

## 1. Install dependencies

```bash
pip install requests beautifulsoup4
```

## 2. Create a Gmail App Password

1. Go to https://myaccount.google.com/security
2. Enable **2-Step Verification** if not already on
3. Go to https://myaccount.google.com/apppasswords
4. Select **Mail** and **Windows Computer**
5. Click **Generate** — you'll get a 16-character password like `abcd efgh ijkl mnop`
6. Copy it (you won't see it again)

## 3. Configure .env

```bash
cd C:/Users/Dave_/OneDrive/Desktop/Economics/other/price_monitor
cp .env.example .env
```

Edit `.env` and paste your App Password:

```
GMAIL_ADDRESS=davechivers123@gmail.com
GMAIL_APP_PASSWORD=abcd efgh ijkl mnop
```

## 4. Test it

```bash
python price_monitor.py
```

Check `monitor.log` for output and your inbox for any alerts.

## 5. Schedule daily at 9am (Windows Task Scheduler)

Open PowerShell **as Administrator** and run:

```powershell
$action = New-ScheduledTaskAction -Execute "python" -Argument "C:\Users\Dave_\OneDrive\Desktop\Economics\other\price_monitor\price_monitor.py" -WorkingDirectory "C:\Users\Dave_\OneDrive\Desktop\Economics\other\price_monitor"
$trigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries
Register-ScheduledTask -TaskName "PriceMonitor" -Action $action -Trigger $trigger -Settings $settings -Description "Daily price monitor for Tikamoon and Dreams"
```

To verify: open Task Scheduler (`taskschd.msc`) and check the `PriceMonitor` task.

## 6. Stopping / Pausing

**From email:** Reply to any alert with the word **STOP** in the subject or body.

**From Cursor terminal:**
```bash
python price_monitor.py --pause    # pause monitoring
python price_monitor.py --resume   # resume monitoring
python price_monitor.py --status   # see current state
```

**Manual:** Create a file called `PAUSE` (no extension) in the price_monitor folder.

## Files

| File | Purpose |
|---|---|
| `price_monitor.py` | Main script |
| `.env` | Your Gmail credentials (git-ignored) |
| `price_state.json` | Last known prices and page states (auto-created) |
| `monitor.log` | Run log |
| `PAUSE` | If this file exists, monitoring is skipped |
