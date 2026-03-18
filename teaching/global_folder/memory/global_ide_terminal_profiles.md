# global IDE terminal profiles

This note records the shared VS Code or Cursor terminal launcher setup for AI CLIs.

## Goal

Provide three one-click terminal profiles in the IDE terminal dropdown, in this order:

1. `codex`
2. `claude`
3. `gemini`

Keep `codex` as the default profile.

## Windows user settings example

Add or merge the following into the editor user `settings.json`:

```json
"terminal.integrated.profiles.windows": {
  "codex": {
    "source": "PowerShell",
    "args": [
      "-NoExit",
      "-Command",
      "& 'C:\\Users\\Dave_\\AppData\\Roaming\\npm\\codex.cmd' --dangerously-bypass-approvals-and-sandbox"
    ],
    "overrideName": true,
    "icon": "tools",
    "color": "terminal.ansiBlue"
  },
  "claude": {
    "source": "PowerShell",
    "args": [
      "-NoExit",
      "-Command",
      "claude --permission-mode bypassPermissions"
    ],
    "overrideName": true,
    "icon": "hubot",
    "color": "terminal.ansiYellow"
  },
  "gemini": {
    "source": "PowerShell",
    "args": [
      "-NoExit",
      "-Command",
      "$env:GEMINI_API_KEY = if ($env:GEMINI_API_KEY) { $env:GEMINI_API_KEY } else { [Environment]::GetEnvironmentVariable('GEMINI_API_KEY','User') }; gemini"
    ],
    "overrideName": true,
    "icon": "sparkle",
    "color": "terminal.ansiGreen"
  },
  "PowerShell": {
    "source": "PowerShell"
  }
},
"terminal.integrated.defaultProfile.windows": "codex"
```

## Why Gemini needs the extra command

`setx GEMINI_API_KEY "..."` writes the key to the Windows user environment for future processes.
Some IDE terminals still inherit an older environment snapshot until the full IDE is restarted.
The Gemini launcher above explicitly reloads `GEMINI_API_KEY` from the Windows user environment before starting `gemini`.

## Usage note

If `gemini` still cannot see the key after `setx`, fully quit and reopen the IDE, not just the terminal tab.
