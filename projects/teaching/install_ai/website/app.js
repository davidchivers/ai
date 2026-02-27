const state = {
  os: null,
  tool: null,
  editor: null,
  pack: null,
  current: 0,
  steps: []
};

const distribution = {
  github: {
    owner: 'davidchivers',
    repo: 'ai_install',
    branchBasic: 'starter_basic',
    branchAdvanced: 'starter_advanced'
  },
  oneDriveFolderUrlBasic: '',
  oneDriveFolderUrlAdvanced: '',
  vscodeProfileUrl: '',
  cursorProfileUrl: 'cursor://profile/github/0cf6696b0aa251846a9b1ed761267f88',
  teachingSlidesUrl: 'https://1drv.ms/p/c/34def9d130aed1a9/IQBwHWaK-I16T7yC88Wf80p5AdKUKL3gW8454f3iwOOWwCk?e=lDNPKN'
};

const nav = document.getElementById('stepNav');
const content = document.getElementById('stepContent');
const backBtn = document.getElementById('backBtn');
const nextBtn = document.getElementById('nextBtn');
const progressBar = document.getElementById('progressBar');

function osLabel(os) {
  return os === 'windows' ? 'Windows' : os === 'mac' ? 'Mac' : 'Not selected';
}

function toolLabel(tool) {
  if (tool === 'codex') return 'Codex';
  if (tool === 'claude') return 'Claude Code';
  if (tool === 'both') return 'Codex + Claude Code';
  return 'Not selected';
}

function editorLabel(editor) {
  if (editor === 'vscode') return 'VS Code';
  if (editor === 'cursor') return 'Cursor';
  return 'Not selected';
}

function packLabel(pack) {
  if (pack === 'basic') return 'Basic starter';
  if (pack === 'advanced') return 'Advanced starter';
  return 'Not selected';
}

function learnBlock(title, body) {
  return `<details class="learn"><summary>${title}</summary>${body}</details>`;
}

function githubZipUrlForPack(pack) {
  const { owner, repo, branchBasic, branchAdvanced } = distribution.github;
  if (!owner || !repo || owner.startsWith('YOUR_') || repo.startsWith('YOUR_')) return null;
  if (pack === 'basic' && branchBasic) {
    return `https://github.com/${owner}/${repo}/archive/refs/heads/${branchBasic}.zip`;
  }
  if (pack === 'advanced' && branchAdvanced) {
    return `https://github.com/${owner}/${repo}/archive/refs/heads/${branchAdvanced}.zip`;
  }
  return null;
}

function hasConfiguredUrl(url) {
  return Boolean(url) && !url.startsWith('YOUR_');
}

function chooseOsStep() {
  const hasSlides = hasConfiguredUrl(distribution.teachingSlidesUrl);
  const slidesLink = hasSlides
    ? `<p><a href="${distribution.teachingSlidesUrl}" target="_blank">Open powerpoint slides for Agentic Coding Introduction</a></p>`
    : '';

  return {
    id: 'choose-os',
    title: 'Choose OS',
    html: `
      <h2>Page 1: Choose your computer type</h2>
      <p>Pick one to start your setup path.</p>
      <div class="callout callout--warn">This installation is for personal computers or computers where you have administrator install rights.</div>
      <div class="choice-grid">
        <button class="btn choice ${state.os === 'windows' ? 'is-selected' : ''}" data-os="windows">Windows</button>
        <button class="btn choice ${state.os === 'mac' ? 'is-selected' : ''}" data-os="mac">Mac</button>
      </div>
      <p class="small">Current selection: <strong>${osLabel(state.os)}</strong></p>
      ${learnBlock('Learn more', '<p>This wizard combines quick actions with optional explanation. You can expand only what you need.</p>')}
      ${slidesLink}
    `,
    onRender: () => {
      document.querySelectorAll('[data-os]').forEach(btn => {
        btn.addEventListener('click', () => {
          state.os = btn.dataset.os;
          buildSteps();
          state.current = state.steps.findIndex(s => s.id === 'choose-tool');
          render();
        });
      });
    }
  };
}

function chooseToolStep() {
  return {
    id: 'choose-tool',
    title: 'Choose AI Agent',
    html: `
      <h2>Page 2: Choose your AI agent</h2>
      <p>Next, install one AI agent: Codex, Claude Code, or both.</p>
      <p><strong>Paid accounts needed:</strong> <a href="https://chatgpt.com/" target="_blank">ChatGPT (OpenAI)</a> and/or <a href="https://claude.ai/" target="_blank">Claude (Anthropic)</a>, depending on whether you install Codex and/or Claude Code.</p>
      <div class="choice-grid">
        <button class="btn choice ${state.tool === 'codex' ? 'is-selected' : ''}" data-tool="codex">Codex only</button>
        <button class="btn choice ${state.tool === 'claude' ? 'is-selected' : ''}" data-tool="claude">Claude only</button>
        <button class="btn choice ${state.tool === 'both' ? 'is-selected' : ''}" data-tool="both">Both</button>
      </div>
      <p class="small">Current selection: <strong>${toolLabel(state.tool)}</strong></p>
      ${learnBlock('Learn more', '<p>Codex and Claude can both help in terminal workflows. You can install one now and add the other later.</p>')}
    `,
    onRender: () => {
      document.querySelectorAll('[data-tool]').forEach(btn => {
        btn.addEventListener('click', () => {
          state.tool = btn.dataset.tool;
          buildSteps();
          state.current = state.steps.findIndex(s => s.id === 'install-prereqs');
          render();
        });
      });
    }
  };
}

function installEverythingStep() {
  const isMac = state.os === 'mac';
  const platformLabel = isMac ? 'Mac' : 'Windows';

  // Build the winget / brew editor package name
  const editorWinget = state.editor === 'cursor' ? 'Cursor.Cursor' : 'Microsoft.VisualStudioCode';
  const editorBrew = state.editor === 'cursor' ? 'cursor' : 'visual-studio-code';
  const editorName = editorLabel(state.editor) || 'your editor';

  let fastBlock = '';
  let manualBlock = '';
  let manualDropdown = '';

  if (isMac) {
    fastBlock = `
      <h3>Fast install (two commands)</h3>
      <p>Open <strong>Terminal</strong> (Applications → Utilities → Terminal) and paste each line:</p>
      <div class="code">xcode-select --install</div>
      <p class="small">Wait for the popup to finish, then paste:</p>
      <div class="code">brew install --cask ${editorBrew} && brew install node</div>
      <p class="small">Don't have Homebrew? Install it first: <a href="https://brew.sh/" target="_blank">brew.sh</a></p>
    `;
    manualBlock = `
      <ol>
        <li>Git: run <code>xcode-select --install</code> or download from <a href="https://git-scm.com/download/mac" target="_blank">git-scm.com</a></li>
        <li>Node.js: <a href="https://nodejs.org/" target="_blank">nodejs.org</a> (choose <strong>LTS</strong>)</li>
        <li>${editorName}: <a href="${state.editor === 'cursor' ? 'https://www.cursor.com/downloads' : 'https://code.visualstudio.com/Download'}" target="_blank">Download ${editorName}</a></li>
      </ol>
    `;
  } else {
    fastBlock = `
      <h3>Fast install (one command)</h3>
      <ol>
        <li>Click the <strong>Start</strong> button (or press the Windows key).</li>
        <li>Type <strong>PowerShell</strong> in the search bar.</li>
        <li>Open <strong>Windows PowerShell</strong>.</li>
      </ol>
      <p><strong>Run this command:</strong></p>
      <div class="code">winget install ${editorWinget} Git.Git OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements</div>
      <div class="callout callout--warn"><strong>Important:</strong> After it finishes, <strong>close and reopen your terminal</strong> before moving to page 4.</div>
    `;
    manualBlock = `
      <ol>
        <li>${editorName}: <a href="${state.editor === 'cursor' ? 'https://www.cursor.com/downloads' : 'https://code.visualstudio.com/Download'}" target="_blank">Download ${editorName}</a></li>
        <li>Git: <a href="https://git-scm.com/download/win" target="_blank">git-scm.com/download/win</a></li>
        <li>Node.js: <a href="https://nodejs.org/" target="_blank">nodejs.org</a> (choose <strong>LTS</strong>)</li>
      </ol>
    `;
  }

  manualDropdown = `
    <details class="learn">
      <summary>Not working? Use manual install</summary>
      <h3>Manual install</h3>
      ${manualBlock}
    </details>
  `;

  return {
    id: 'install-prereqs',
    title: 'Install prerequisites',
    html: `
      <h2>Page 3: Install prerequisites (${platformLabel})</h2>
      <p>First, choose your editor:</p>
      <div class="choice-grid">
        <button class="btn choice ${state.editor === 'vscode' ? 'is-selected' : ''}" data-editor="vscode">VS Code</button>
        <button class="btn choice ${state.editor === 'cursor' ? 'is-selected' : ''}" data-editor="cursor">Cursor</button>
      </div>
      <p class="small">Current selection: <strong>${editorLabel(state.editor)}</strong></p>
      ${state.editor ? fastBlock + manualDropdown : '<p>Select an editor above to see the install command.</p>'}
      ${state.editor ? '<p><strong>Next page:</strong> verify versions and install your AI agent.</p>' : ''}
    `,
    onRender: () => {
      document.querySelectorAll('[data-editor]').forEach(btn => {
        btn.addEventListener('click', () => {
          state.editor = btn.dataset.editor;
          buildSteps();
          state.current = state.steps.findIndex(s => s.id === 'install-prereqs');
          render();
        });
      });
    }
  };
}

function installAgentStep() {
  const editorName = editorLabel(state.editor) || 'your editor';
  let agentCommands = '';

  if (state.tool === 'codex') {
    agentCommands = 'npm install -g @openai/codex\ncodex --login\ncodex';
  } else if (state.tool === 'claude') {
    agentCommands = 'npm install -g @anthropic-ai/claude-code\nclaude';
  } else {
    agentCommands = 'npm install -g @openai/codex\nnpm install -g @anthropic-ai/claude-code\ncodex --login\nclaude';
  }

  return {
    id: 'install-agent',
    title: 'Install AI agent',
    html: `
      <h2>Page 4: Install ${toolLabel(state.tool)}</h2>
      <p>Step 3 installed prerequisites (editor, Git, Node). Now install your AI agent.</p>
      <p>Open <strong>${editorName}</strong>, then open <strong>Terminal → New Terminal</strong> and run:</p>
      <div class="code">${agentCommands}</div>
      <p>If a command fails, paste the full error message into chat and ask for the exact next command.</p>
    `
  };
}

function templateStep() {
  const editor = editorLabel(state.editor);
  const basicZipUrl = githubZipUrlForPack('basic');
  const advancedZipUrl = githubZipUrlForPack('advanced');
  const hasBasicOneDrive = hasConfiguredUrl(distribution.oneDriveFolderUrlBasic);
  const hasAdvancedOneDrive = hasConfiguredUrl(distribution.oneDriveFolderUrlAdvanced);

  const basicZipBlock = basicZipUrl
    ? `<p><a href="${basicZipUrl}" target="_blank">Download Basic starter ZIP</a></p>`
    : '<p><strong>Basic ZIP link not configured yet.</strong></p>';
  const advancedZipBlock = advancedZipUrl
    ? `<p><a href="${advancedZipUrl}" target="_blank">Download Full starter ZIP</a></p>`
    : '<p><strong>Full starter ZIP link not configured yet.</strong></p>';
  const basicOneDriveBlock = hasBasicOneDrive
    ? `<p><a href="${distribution.oneDriveFolderUrlBasic}" target="_blank">Open Basic starter on OneDrive</a></p>`
    : '';
  const advancedOneDriveBlock = hasAdvancedOneDrive
    ? `<p><a href="${distribution.oneDriveFolderUrlAdvanced}" target="_blank">Open Full starter on OneDrive</a></p>`
    : '';

  return {
    id: 'template',
    title: 'Basic Starter Folder Setup (Optional)',
    html: `
      <h2>Page 5: Basic starter folder setup (optional)</h2>
      <p>Start with Basic if you are new. You can try both.</p>

      <h3>Basic starter folder</h3>
      <p>This includes a folder with core <code>agents/</code> and <code>skills/</code>, plus a simple project template.</p>
      ${basicZipBlock}
      ${basicOneDriveBlock}

      <h3>Full starter folder</h3>
      <p>This includes everything in Basic plus profile-style preferences and workflow settings that may be helpful.</p>
      <div class="callout callout--warn">
        <p><strong>Warning for Full starter terminal presets:</strong></p>
        <ul>
          <li><strong>Claude (bypass):</strong> fewer confirmation checks. Use only in trusted project folders.</li>
          <li><strong>Codex (bypass):</strong> can move quickly and make larger changes. Review commands and file edits before approving.</li>
        </ul>
      </div>
      ${advancedZipBlock}
      ${advancedOneDriveBlock}
      <p class="small">You can try both packs and keep whichever works best for you.</p>

      <ol>
        <li>Download and extract the pack you want to test.</li>
        <li>Open the folder in your IDE (for example: <strong>File > Open Folder</strong> in ${editor}).</li>
        <li>Select the extracted starter folder.</li>
      </ol>
      ${learnBlock('Learn more', '<p>Once you have loaded a starter folder, ask your AI: "Please give me a quick overview of these folders and what each one is for."</p>')}
    `
  };
}

function profileStep() {
  const editor = editorLabel(state.editor);
  const editorName = state.editor ? editor : 'your editor';
  const shortcut = state.os === 'mac'
    ? '<strong>Cmd + Shift + P</strong> on Mac'
    : '<strong>Ctrl + Shift + P</strong> on Windows';
  const isCursor = state.editor === 'cursor';
  const selectedProfileUrl = isCursor ? distribution.cursorProfileUrl : distribution.vscodeProfileUrl;
  const hasProfileUrl = hasConfiguredUrl(selectedProfileUrl);
  const profileLink = hasProfileUrl
    ? `<p><a href="${selectedProfileUrl}">Download ${editorName} profile</a></p>`
    : `<p>No ${editorName} profile link is configured yet. This step is optional, so you can skip it and continue.</p>`;

  return {
    id: 'profile',
    title: 'Download Profile',
    html: `
      <h2>Page 6: Download ${editorName} profile (optional)</h2>
      <p>This step is optional. Use it to quickly load the same settings as the workshop.</p>
      ${profileLink}
      <ol>
        <li>Open ${editorName}.</li>
        <li>Press ${shortcut}.</li>
        <li>Run <strong>Profiles: Import Profile</strong>.</li>
        <li>Paste the downloaded profile link and complete the import.</li>
      </ol>
      <p class="small">You can skip this step and continue. Your setup will still work.</p>
      ${learnBlock('Learn more', '<p>A profile imports settings and extensions quickly. It is optional, and you can always customize later.</p>')}
    `
  };
}

function githubStep() {
  return {
    id: 'github',
    title: 'Pair with GitHub',
    html: `
      <h2>Page 7: Pair with GitHub (beginner backup)</h2>
      <p>GitHub is a free backup for your project files and gives you version history.</p>
      <p>If you are new, ask Claude or Codex to guide you step-by-step.</p>
      <p><a href="https://github.com/" target="_blank">Create or sign in to GitHub</a></p>
      <p><strong>Try pasting this into Claude/Codex chat:</strong></p>
      <div class="code">I want to back up and pair my folders with Git. I am a beginner. Please explain each step, why it matters, and give me the exact commands for my computer.</div>
      <p><strong>If you want direct commands:</strong></p>
      <div class="code">git init\ngit add .\ngit commit -m "Initial backup"\ngit branch -M main\ngit remote add origin https://github.com/YOUR_USER/YOUR_REPO.git\ngit push -u origin main</div>
      ${learnBlock('Learn more', '<p>GitHub is used by many software developers, so it links well with AI coding tools and workflows.</p>')}
    `
  };
}

function appendixStep() {
  return {
    id: 'appendix',
    title: 'Glossary',
    html: `
      <h2>Page 8: Quick glossary</h2>
      <ul>
        <li><strong>IDE:</strong> The app where you edit code (for example VS Code or Cursor).</li>
        <li><strong>Terminal:</strong> Text window where you run commands.</li>
        <li><strong>CLI:</strong> Command-line tool you run in the terminal.</li>
        <li><strong>Git:</strong> Version control system that tracks changes.</li>
        <li><strong>GitHub:</strong> Website for hosting Git repositories.</li>
        <li><strong>Repository (repo):</strong> Project folder tracked by Git.</li>
        <li><strong>Branch:</strong> Separate line of development in a repo.</li>
        <li><strong>Commit:</strong> Saved checkpoint of changes in Git.</li>
        <li><strong>ZIP:</strong> Compressed folder download.</li>
        <li><strong>Profile:</strong> Bundle of editor settings and extensions.</li>
      </ul>
      ${learnBlock('Learn more', '<p>You can return to this glossary whenever a new term appears during setup.</p>')}
    `
  };
}

function doneStep() {
  return {
    id: 'done',
    title: 'Done',
    html: `
      <h2>Setup complete</h2>
      <p>You finished the <strong>${osLabel(state.os)}</strong> path with <strong>${toolLabel(state.tool)}</strong> in <strong>${editorLabel(state.editor)}</strong>.</p>
      <p class="small">Press <strong>Restart</strong> to run the wizard again.</p>
      ${learnBlock('Learn more', '<p>Next step: open your project folder and ask Codex or Claude for one small task to get comfortable.</p>')}
    `
  };
}

function buildSteps() {
  state.steps = [
    chooseOsStep(),
    chooseToolStep(),
    installEverythingStep(),
    installAgentStep(),
    templateStep(),
    profileStep(),
    githubStep(),
    appendixStep(),
    doneStep()
  ];
}

function renderNav() {
  nav.innerHTML = '';
  const step = state.steps[state.current];
  const li = document.createElement('li');
  li.className = 'step-nav__item active';
  li.textContent = `Step ${state.current + 1} of ${state.steps.length}: ${step.title}`;
  nav.appendChild(li);
}

function render() {
  const step = state.steps[state.current];
  content.innerHTML = step.html;
  if (typeof step.onRender === 'function') step.onRender();

  backBtn.disabled = state.current === 0;
  nextBtn.textContent = state.current === state.steps.length - 1 ? 'Restart' : 'Next';
  progressBar.style.width = `${Math.round((state.current / (state.steps.length - 1)) * 100)}%`;
  renderNav();
}

function restartWizard() {
  state.os = null;
  state.tool = null;
  state.editor = null;
  state.pack = null;
  state.current = 0;
  buildSteps();
  render();
}

backBtn.addEventListener('click', () => {
  if (state.current > 0) {
    state.current -= 1;
    render();
  }
});

nextBtn.addEventListener('click', () => {
  if (state.current === state.steps.length - 1) {
    restartWizard();
    return;
  }

  const step = state.steps[state.current];
  if (step.id === 'choose-os' && !state.os) {
    alert('Select Windows or Mac first.');
    return;
  }
  if (step.id === 'choose-tool' && !state.tool) {
    alert('Select Codex, Claude, or Both first.');
    return;
  }
  if (step.id === 'install-prereqs' && !state.editor) {
    alert('Select VS Code or Cursor first.');
    return;
  }
  if (state.current < state.steps.length - 1) {
    state.current += 1;
    render();
  }
});

buildSteps();
render();
