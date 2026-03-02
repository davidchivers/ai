# VS Code Setup Wizard

A simple setup guide for beginners. Follow one step at a time.

## Fast Help (keep this handy)

If any command fails, copy the full error message and paste it into ChatGPT or Claude with: 
`Please explain this error and tell me the exact next command for my computer.`

---

## Page 1: Choose your path

Choose one:
- **Windows path**
- **Mac path**

You can still install **both Codex and Claude Code** on either system.

What this step does:
- Helps you pick the correct install instructions for your computer.

---

## Page 2: Codex vs Claude Code (what each one is)

### Codex (OpenAI)

Codex is a terminal coding assistant from OpenAI. It helps with project setup, code edits, scripts, and command-line workflows.

Getting started links:
- Codex docs: https://help.openai.com/en/articles/11096431-openai-codex-ci-getting-started
- Codex auth/login: https://help.openai.com/en/articles/11381614

### Claude Code (Anthropic)

Claude Code is a terminal coding assistant from Anthropic. It helps with code changes, explanations, automation, and repo navigation.

Getting started links:
- Claude Code docs: https://docs.anthropic.com/en/docs/claude-code/getting-started

### Which should I choose?

- Choose **Codex only** if your team mainly uses OpenAI tools.
- Choose **Claude only** if your team mainly uses Anthropic tools.
- Choose **both** if you want flexibility and to compare outputs.

What this step does:
- Clarifies that these are two different tools and you may install one or both.

---

## Page 3: Install VS Code

### Windows

1. Open: https://code.visualstudio.com/Download
2. Download **Windows** installer.
3. Run installer with default options.
4. Open VS Code.

### Mac

1. Open: https://code.visualstudio.com/Download
2. Download **macOS** build for your Mac.
3. Open the downloaded file and move VS Code to Applications.
4. Open VS Code.

What this step does:
- Installs the editor where you will run terminal commands and manage project files.

Common problems:
- VS Code does not open after install: restart computer and try again.
- First open warning on macOS: allow app in Privacy/Security settings.

---

## Page 4: Install Git (required)

### What is Git?

Git is a version control tool that tracks file changes. These AI terminal tools rely on Git-style project workflows.

### Why Git is required here

- Many AI coding tools expect Git commands and Git repository context.
- On Windows, installing Git also gives **Git Bash**, which is commonly needed for Claude Code.

### Install Git

- Windows: https://git-scm.com/download/win
- Mac option A (recommended): install Apple Command Line Tools
  - Open Terminal and run:

```bash
xcode-select --install
```

- Mac option B: https://git-scm.com/download/mac

### Verify Git install (step by step)

1. Open a terminal.
- VS Code terminal: `Terminal -> New Terminal`
- Windows system terminal: Windows Terminal or Command Prompt
- Mac system terminal: Terminal app (Applications -> Utilities -> Terminal)

2. Type:

```bash
git --version
```

3. Good output example:

```text
git version 2.48.1
```

4. If it says command not found:
- Close and reopen terminal.
- Reinstall Git (or rerun `xcode-select --install` on Mac).
- Restart computer.
- Check PATH setup and try again.

### Why `--version` has two dashes

`--version` is a long command option. Two dashes start a full option name.

What this step does:
- Installs and verifies Git so terminal AI tools can run reliably.

Common problems:
- Wrong command like `git dash version`: use exactly `git --version`.
- Terminal opened before install: close and reopen terminal.

---

## Page 5: Install Node.js LTS (required)

Node and npm are used to install Codex and Claude Code CLI tools.

### Windows and Mac

1. Open: https://nodejs.org/
2. Download **LTS** version.
3. Install with defaults.
4. Verify in terminal:

```bash
node -v
npm -v
```

What this step does:
- Installs the package manager needed to install CLI AI tools.

Common problems:
- `node` not found: restart terminal and reinstall Node LTS.

---

## Page 6: Terminal basics before running commands

Use this before any command block.

### Which terminal are we using?

- Preferred: **VS Code built-in terminal**
- Also fine: system terminal (Windows Terminal/Command Prompt on Windows, Terminal app on Mac)

### What folder/path should I be in?

Run this to see current folder:

```bash
pwd
```

### How to change folder (`cd`) examples

```bash
cd Documents
cd "C:\Users\YourName\Desktop\MyProject"   # Windows example
cd ~/Documents/MyProject                         # Mac example
```

### How to open terminal in VS Code

- Menu: `Terminal -> New Terminal`
- Shortcut:
- Windows: `Ctrl + \``
- Mac: `Control + \``

What this step does:
- Prevents confusion about where commands run and which folder they affect.

Common problems:
- Running commands in the wrong folder.
- Mixing PowerShell, Command Prompt, and Bash without noticing.

---

## Page 7: Install Codex and/or Claude Code

Install one or both.

### Codex install

```bash
npm install -g @openai/codex
codex --login
codex
```

### Claude Code install

```bash
npm install -g @anthropic-ai/claude-code
claude
```

### Update and remove

```bash
codex --upgrade
claude update
npm uninstall -g @openai/codex
npm uninstall -g @anthropic-ai/claude-code
```

Terminal note:
- Run these in VS Code terminal or your system terminal.
- Check folder with `pwd` first.

What this step does:
- Installs the AI assistant command tools and starts login flow.

Common problems:
- Browser sign-in opens wrong account.
- Firewall/VPN blocks login callback.

---

## Page 8: Use the demo template folder (replaces manual skeleton)

Do this instead of creating folder structure manually.

### 1) Get the demo template

Download from: `[TEMPLATE_LINK_HERE]`

### 2) Copy/extract template

#### Windows

1. If ZIP, right-click -> **Extract All**.
2. Copy extracted folder to a working location, for example:
- `C:\Users\YourName\Documents\AI_Projects\`

#### Mac

1. Double-click ZIP to extract.
2. Move extracted folder to a working location, for example:
- `~/Documents/AI_Projects/`

### 3) Open template in VS Code

1. In VS Code: `File -> Open Folder`
2. Select extracted template folder.

### 4) Confirm it worked

Check you can see expected files/folders such as:
- `agents/`
- `skills/`
- `memory/`
- `.md` guide files

What this step does:
- Gives you a ready-made working project layout with less setup effort.

Common problems:
- Opening parent folder instead of the extracted template folder.
- ZIP not extracted before opening.

---

## Page 9: Terminal shortcuts and navigation (beginner version)

### Open/close terminal

- Open: `Terminal -> New Terminal`
- Close active terminal: trash/bin icon in terminal panel

### New terminal

- Click `+` in terminal panel

### Split terminal

- Click split icon in terminal panel

### Search in terminal output

- Use terminal search (`Ctrl + F` in terminal panel)

### Copy/paste tips

- Windows terminal copy/paste often uses `Ctrl + C` / `Ctrl + V`
- In some shells, right-click paste also works
- Mac terminal paste is usually `Cmd + V`

### Command Palette

- Open Command Palette:
- Windows: `Ctrl + Shift + P`
- Mac: `Cmd + Shift + P`

What this step does:
- Makes terminal usage less intimidating and faster.

Common problems:
- Copying smart quotes from documents into terminal commands.
- Pasting extra spaces/hidden characters.

---

## Page 10 (Optional): VS Code profile import

What it is:
- A profile is a bundle of settings and extensions.

Why beginners can skip:
- You can work fine without it and add it later.

Optional steps:
1. Open Command Palette.
2. Run `Profiles: Import Profile`.
3. Use link/file if provided.

Placeholders:
- `PROFILE_LINK_HERE`
- `PROFILE_FILE_NAME_HERE`

Status:
- If not ready yet, mark as: `Coming soon`.

What this step does:
- Applies a shared environment quickly when available.

---

## Page 11 (Optional): Pair with GitHub

### What is GitHub?

GitHub is a cloud platform for storing and collaborating on Git repositories.

### Why pairing helps

- Backup and version history
- Easier collaboration
- Faster sharing of projects

### Minimal sign-in from VS Code

1. Create/sign in: https://github.com/
2. In VS Code, open Accounts menu.
3. Click **Sign in with GitHub**.
4. Approve in browser.

### Clone/open repo vs local folders

- Clone a repo if you are joining an existing project.
- Use local folder only if you are starting privately and not syncing yet.

Clone command example:

```bash
git clone https://github.com/ORG/REPO.git
cd REPO
code .
```

What this step does:
- Connects local work to collaborative version control.

Common problems:
- Wrong GitHub account in browser during auth.

---

## Page 12: Appendix - troubleshooting + glossary

### Troubleshooting quick list

- `git` not found:
- Reinstall Git, restart terminal, rerun `git --version`.

- `node`/`npm` not found:
- Reinstall Node LTS and reopen terminal.

- `claude` or `codex` not found:
- Reinstall with npm global command and reopen terminal.

- Login/auth fails:
- Check browser account, disable strict VPN/proxy temporarily, retry.

- VS Code terminal opens wrong shell:
- Use Command Palette -> `Terminal: Select Default Profile`.

### Simple glossary

- **IDE**: app for editing code and running tools.
- **Terminal**: text interface where you run commands.
- **CLI**: command-line interface tool.
- **PATH**: list of folders where system looks for commands.
- **Repository (repo)**: project folder tracked by Git.
- **Profile (VS Code)**: saved settings/extensions bundle.
- **Bash**: common command shell.
- **Git Bash**: Bash shell packaged for Windows with Git.
- **WSL**: Linux environment inside Windows.

What this step does:
- Gives quick fixes and plain-language definitions for beginners.

---

## Official links (plain URLs)

- VS Code download: https://code.visualstudio.com/Download
- Git for Windows: https://git-scm.com/download/win
- Git for Mac: https://git-scm.com/download/mac
- Apple command line tools: https://developer.apple.com/xcode/resources/
- Node.js LTS: https://nodejs.org/
- Codex docs: https://help.openai.com/en/articles/11096431-openai-codex-ci-getting-started
- Codex auth: https://help.openai.com/en/articles/11381614
- Claude Code docs: https://docs.anthropic.com/en/docs/claude-code/getting-started
- GitHub: https://github.com/
