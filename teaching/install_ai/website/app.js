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
  vscodeProfileUrl: 'https://vscode.dev/editor/profile/github/0cf6696b0aa251846a9b1ed761267f88',
  cursorProfileUrl: 'cursor://profile/github/0cf6696b0aa251846a9b1ed761267f88',
  teachingSlidesUrl: '/ai_install/slides/ai_coding_agents_workshop_slides.pptx',
  githubEducationUrl: 'https://education.github.com/pack'
};

const nav = document.getElementById('stepNav');
const content = document.getElementById('stepContent');
const backBtn = document.getElementById('backBtn');
const nextBtn = document.getElementById('nextBtn');
const progressBar = document.getElementById('progressBar');

function attachCopyButtons() {
  content.querySelectorAll('.code').forEach(block => {
    if (block.parentElement && block.parentElement.classList.contains('code-wrap')) return;

    const wrapper = document.createElement('div');
    wrapper.className = 'code-wrap';
    block.parentNode.insertBefore(wrapper, block);
    wrapper.appendChild(block);

    const copyBtn = document.createElement('button');
    copyBtn.type = 'button';
    copyBtn.className = 'copy-btn';
    copyBtn.textContent = 'Copy';

    copyBtn.addEventListener('click', async () => {
      const text = block.innerText.replace(/\u00a0/g, ' ').trim();
      let copied = false;

      if (navigator.clipboard && navigator.clipboard.writeText) {
        try {
          await navigator.clipboard.writeText(text);
          copied = true;
        } catch (_) {
          copied = false;
        }
      }

      if (!copied) {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.focus();
        ta.select();
        try {
          copied = document.execCommand('copy');
        } catch (_) {
          copied = false;
        }
        document.body.removeChild(ta);
      }

      copyBtn.textContent = copied ? 'Copied' : 'Copy failed';
      copyBtn.disabled = true;
      setTimeout(() => {
        copyBtn.textContent = 'Copy';
        copyBtn.disabled = false;
      }, 1200);
    });

    wrapper.appendChild(copyBtn);
  });
}

function osLabel(os) {
  return os === 'windows' ? 'Windows' : os === 'mac' ? 'Mac' : 'Not selected';
}

function toolLabel(tool) {
  if (tool === 'codex') return 'Codex';
  if (tool === 'claude') return 'Claude Code';
  if (tool === 'gemini') return 'Gemini CLI';
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
  const hasGithubEdu = hasConfiguredUrl(distribution.githubEducationUrl);
  const githubEduLink = hasGithubEdu
    ? `<p><a href="${distribution.githubEducationUrl}" target="_blank">Free AI models for students/teachers (GitHub Education Pack)</a></p>`
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
      ${githubEduLink}
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
      <p>Pick one AI coding tool to install first.</p>
      <p><strong>Accounts:</strong> Codex uses ChatGPT, Claude Code uses Anthropic/Claude, and Gemini CLI uses Google AI Studio.</p>
      <div class="choice-grid">
        <button class="btn choice ${state.tool === 'codex' ? 'is-selected' : ''}" data-tool="codex">Codex</button>
        <button class="btn choice ${state.tool === 'claude' ? 'is-selected' : ''}" data-tool="claude">Claude Code</button>
        <button class="btn choice ${state.tool === 'gemini' ? 'is-selected' : ''}" data-tool="gemini">Gemini CLI</button>
      </div>
      <p class="small">Current selection: <strong>${toolLabel(state.tool)}</strong></p>
      ${learnBlock('Learn more', '<p>Install one now and add the others later if you want.</p>')}
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
      ${state.editor ? '<p><strong>Next page:</strong> restart terminal, then install your AI agent.</p>' : ''}
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

function restartTerminalStep() {
  const editorName = editorLabel(state.editor) || 'your editor';

  return {
    id: 'restart-terminal',
    title: 'Restart terminal',
    html: `
      <h2>Page 4: Restart terminal</h2>
      <p>Before page 5, restart your terminal:</p>
      <ol>
        <li>Close the terminal window/tab you used in step 3.</li>
        <li>Open a fresh terminal: <strong>Terminal → New Terminal</strong>.</li>
      </ol>
      <p class="small">No need to restart ${editorName}.</p>
    `
  };
}

function installAgentStep() {
  const editorName = editorLabel(state.editor) || 'your editor';
  let installCommand = '';
  let nextStepCopy = '';
  let note = '';

  if (state.tool === 'codex') {
    installCommand = 'npm install -g @openai/codex';
    nextStepCopy = 'sign in to Codex and start it.';
    note = 'This installs the latest Codex CLI.';
  } else if (state.tool === 'claude') {
    installCommand = 'npm install -g @anthropic-ai/claude-code';
    nextStepCopy = 'sign in to Claude Code and start it.';
    note = 'This installs the latest Claude Code CLI.';
  } else {
    installCommand = 'npm install -g @google/gemini-cli@latest';
    nextStepCopy = 'set your Gemini API key permanently, then run Gemini.';
    note = 'This installs or updates Gemini CLI to the latest version.';
  }

  return {
    id: 'install-agent',
    title: 'Install AI agent',
    html: `
      <h2>Page 5: Install ${toolLabel(state.tool)}</h2>
      <p>Step 3 installed prerequisites and step 4 restarted your terminal. Now install ${toolLabel(state.tool)}.</p>
      <p>Open <strong>${editorName}</strong>, then open <strong>Terminal → New Terminal</strong> and run:</p>
      <div class="code">${installCommand}</div>
      <p class="small">${note}</p>
      <p><strong>Next page:</strong> ${nextStepCopy}</p>
    `
  };
}

function authStep() {
  if (state.tool === 'codex') {
    return {
      id: 'auth-step',
      title: 'Sign in to Codex',
      html: `
        <h2>Page 6: Sign in to Codex</h2>
        <p>Run this in terminal, then complete the login flow in your browser:</p>
        <div class="code">codex --login</div>
        <p>Start Codex:</p>
        <div class="code">codex</div>
      `
    };
  }

  if (state.tool === 'claude') {
    return {
      id: 'auth-step',
      title: 'Sign in to Claude Code',
      html: `
        <h2>Page 6: Sign in to Claude Code</h2>
        <p>Run Claude Code and follow the sign-in prompts:</p>
        <div class="code">claude</div>
      `
    };
  }

  const isMac = state.os === 'mac';
  const setPersistentKey = isMac
    ? "echo 'export GEMINI_API_KEY=\"PASTE_KEY_HERE\"' >> ~/.zshrc\nsource ~/.zshrc"
    : 'setx GEMINI_API_KEY "PASTE_KEY_HERE"';

  return {
    id: 'auth-step',
    title: 'Set Gemini API key',
    html: `
      <h2>Page 6: Set your Gemini API key (permanent)</h2>
      <ol>
        <li>Open <a href="https://aistudio.google.com/apikey" target="_blank">Google AI Studio API keys</a>.</li>
        <li>Sign in with your Google account.</li>
        <li>Click <strong>Create API key</strong>.</li>
        <li>Copy the new key.</li>
      </ol>
      <p>Back in terminal, set it permanently (single copy command):</p>
      <div class="code">${setPersistentKey}</div>
      <p>Then close and reopen terminal, and start Gemini:</p>
      <div class="code">gemini</div>
      <div class="callout callout--warn">
        <strong>Important:</strong> never paste API keys into GitHub commits or shared files.
      </div>
      ${learnBlock('Learn more', '<p>Gemini has a free tier for light usage and paid usage for higher limits. If you need more usage, upgrade later.</p>')}
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
      title: 'Starter Folder Setup (Optional)',
      html: `
      <h2>Page 7: Starter folder setup (optional)</h2>
      <p>Start with Basic if you are new. You can try both.</p>

      <h3>Basic starter folder</h3>
      <p>Best if you want fewer moving parts. Open <code>README.md</code> first, then <code>memory/README.md</code>.</p>
      <p class="small">Includes core <code>agents/</code>, core <code>skills/</code>, a simple project template, and referee-response templates.</p>
      ${basicZipBlock}
      ${basicOneDriveBlock}

      <h3>Full starter folder</h3>
      <p>Best if you want stronger defaults and more structure. Open <code>README.md</code> first, then <code>memory/global_notes.md</code>.</p>
      <p class="small">Includes everything in Basic plus more agents/skills, standards, numbered notes, and workflow preferences.</p>
      <div class="callout callout--warn">
        <p><strong>Warning for Full starter terminal presets:</strong></p>
        <ul>
          <li><strong>AI terminal tools can run commands and edit files quickly.</strong></li>
          <li><strong>Always review commands and file edits before approving.</strong></li>
        </ul>
      </div>
      ${advancedZipBlock}
      ${advancedOneDriveBlock}
      <p class="small">You can try both packs and keep whichever works best for you.</p>

      <ol>
        <li>Download and extract the pack you want to test.</li>
        <li>Open the extracted folder in your IDE (for example: <strong>File > Open Folder</strong> in ${editor}).</li>
        <li>Read the root <code>README.md</code>.</li>
        <li>Copy <code>projects/_project_template/</code> to start a real project.</li>
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
    ? `<p>Use this profile link:</p><div class="code">${selectedProfileUrl}</div>`
    : `<p>No ${editorName} profile link is configured yet. This step is optional, so you can skip it and continue.</p>`;

  return {
    id: 'profile',
    title: 'Import Profile',
    html: `
      <h2>Page 8: Import ${editorName} profile (optional)</h2>
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
  const assistantName = state.tool === 'claude' ? 'Claude' : state.tool === 'gemini' ? 'Gemini' : 'Codex';

  return {
    id: 'github',
    title: 'Pair with GitHub',
    html: `
      <h2>Page 9: Pair with GitHub (beginner backup)</h2>
      <p>GitHub is a free backup for your project files and gives you version history.</p>
      <p>If you are new, ask ${toolLabel(state.tool)} to guide you step-by-step.</p>
      <p><a href="https://github.com/" target="_blank">Create or sign in to GitHub</a></p>
      <p><strong>Try pasting this into ${assistantName}:</strong></p>
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
      <h2>Page 10: Quick glossary</h2>
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
  const assistantName = state.tool === 'claude' ? 'Claude' : state.tool === 'gemini' ? 'Gemini' : 'Codex';

  return {
    id: 'done',
    title: 'Done',
    html: `
      <h2>Setup complete</h2>
      <p>You finished the <strong>${osLabel(state.os)}</strong> path with <strong>${toolLabel(state.tool)}</strong> in <strong>${editorLabel(state.editor)}</strong>.</p>
      <p class="small">Press <strong>Restart</strong> to run the wizard again.</p>
      ${learnBlock('Learn more', `<p>Next step: open your project folder and ask ${assistantName} for one small task to get comfortable.</p>`)}
    `
  };
}

function buildSteps() {
  state.steps = [
    chooseOsStep(),
    chooseToolStep(),
    installEverythingStep(),
    restartTerminalStep(),
    installAgentStep(),
    authStep(),
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
  attachCopyButtons();
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
    alert('Select Codex, Claude Code, or Gemini CLI first.');
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
