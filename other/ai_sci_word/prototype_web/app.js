const editor = document.getElementById("editor");
const statusText = document.getElementById("statusText");

const MATH_FIELD_SELECTOR = "math-field.ai-math";
let greekModeArmed = false;
let lastFocusedMathField = null;
let statusHideTimer = null;

const GREEK_MAP = {
  a: "\\alpha ",
  b: "\\beta ",
  g: "\\gamma ",
  d: "\\delta ",
  e: "\\epsilon ",
  z: "\\zeta ",
  h: "\\eta ",
  q: "\\theta ",
  i: "\\iota ",
  k: "\\kappa ",
  l: "\\lambda ",
  m: "\\mu ",
  n: "\\nu ",
  x: "\\xi ",
  o: "\\omega ",
  p: "\\pi ",
  r: "\\rho ",
  s: "\\sigma ",
  t: "\\tau ",
  u: "\\upsilon ",
  f: "\\phi ",
  c: "\\chi ",
  y: "\\psi ",
  "8": "\\infty "
};

function setStatus(message) {
  if (!statusText) {
    return;
  }

  statusText.textContent = message;
  statusText.classList.add("visible");

  if (statusHideTimer) {
    clearTimeout(statusHideTimer);
  }

  statusHideTimer = setTimeout(() => {
    statusText.classList.remove("visible");
  }, 1300);
}

function getMathValue(mathField) {
  if (!mathField) {
    return "";
  }

  if (typeof mathField.getValue === "function") {
    return mathField.getValue("latex") || "";
  }

  if (typeof mathField.value === "string") {
    return mathField.value;
  }

  return mathField.textContent || "";
}

function setMathValue(mathField, latex) {
  if (!mathField) {
    return;
  }

  if (typeof mathField.setValue === "function") {
    mathField.setValue(latex);
    return;
  }

  if ("value" in mathField) {
    mathField.value = latex;
    return;
  }

  mathField.textContent = latex;
}

function getActiveMathField() {
  const active = document.activeElement;
  if (active && active.matches && active.matches(MATH_FIELD_SELECTOR)) {
    return active;
  }

  if (active && active.closest) {
    const container = active.closest(MATH_FIELD_SELECTOR);
    if (container) {
      return container;
    }
  }

  if (lastFocusedMathField && lastFocusedMathField.isConnected && editor.contains(lastFocusedMathField)) {
    return lastFocusedMathField;
  }

  return null;
}

function isEditorContext() {
  const active = document.activeElement;
  if (active && editor.contains(active)) {
    return true;
  }

  const selection = window.getSelection();
  if (selection && selection.rangeCount > 0) {
    const range = selection.getRangeAt(0);
    if (editor.contains(range.commonAncestorContainer)) {
      return true;
    }
  }

  return false;
}

function placeCaretAfter(node) {
  const selection = window.getSelection();
  const range = document.createRange();

  if (!node.nextSibling) {
    const spacer = document.createTextNode(node.classList.contains("display") ? "\n" : " ");
    node.after(spacer);
    range.setStart(spacer, spacer.textContent.length);
  } else {
    range.setStartAfter(node);
  }

  range.collapse(true);
  selection.removeAllRanges();
  selection.addRange(range);
  editor.focus();
}

function insertNodeAtCaret(node) {
  const selection = window.getSelection();
  if (!selection || selection.rangeCount === 0) {
    editor.appendChild(node);
    return;
  }

  let range = selection.getRangeAt(0);

  if (!editor.contains(range.commonAncestorContainer)) {
    editor.appendChild(node);
    return;
  }

  const activeMath = getActiveMathField();
  if (activeMath) {
    placeCaretAfter(activeMath);
    range = selection.getRangeAt(0);
  }

  range.deleteContents();
  range.insertNode(node);
}

function createMathField(displayMode) {
  const mf = document.createElement("math-field");
  mf.className = "ai-math";
  if (displayMode) {
    mf.classList.add("display");
  }

  mf.setAttribute("smart-fence", "true");
  mf.setAttribute("virtual-keyboard-mode", "off");
  mf.setAttribute("letter-shape-style", "tex");

  mf.addEventListener("focus", () => {
    lastFocusedMathField = mf;
    setStatus(mf.classList.contains("display") ? "Display equation mode." : "Inline math mode.");
  });

  // Ensure legacy Ctrl shortcuts still work while MathLive owns focus.
  mf.addEventListener("keydown", (event) => {
    if (handleMathShortcut(event, mf)) {
      greekModeArmed = false;
    }
  }, true);

  return mf;
}

function insertMathField(displayMode) {
  const mathField = createMathField(displayMode);
  insertNodeAtCaret(mathField);

  requestAnimationFrame(() => {
    mathField.focus();
  });

  setStatus(displayMode ? "Display equation mode." : "Inline math mode.");
}

function exitMathMode() {
  const activeMath = getActiveMathField();
  if (!activeMath) {
    return false;
  }

  activeMath.blur();
  placeCaretAfter(activeMath);
  setStatus("Text mode.");
  return true;
}

function toggleInlineMath() {
  if (exitMathMode()) {
    return;
  }

  insertMathField(false);
}

function newDisplayEquation() {
  exitMathMode();
  insertMathField(true);
}

function toggleMathFontMode() {
  if (exitMathMode()) {
    return;
  }

  insertMathField(false);
}

function insertIntoTargetMath(mathField, snippet) {
  if (!mathField) {
    return false;
  }

  if (typeof mathField.insert === "function") {
    mathField.insert(snippet, { insertionMode: "replaceSelection" });
  } else {
    const current = getMathValue(mathField);
    setMathValue(mathField, `${current}${snippet}`);
  }

  return true;
}

function insertIntoMath(snippet) {
  return insertIntoTargetMath(getActiveMathField(), snippet);
}

function armGreekMode() {
  greekModeArmed = true;
  setStatus("Greek mode: next key inserts symbol.");
}

function handleArmedGreekMode(event) {
  if (!greekModeArmed) {
    return false;
  }

  if (event.key === "Escape") {
    greekModeArmed = false;
    setStatus("Greek mode cancelled.");
    event.preventDefault();
    return true;
  }

  if (event.ctrlKey || event.metaKey || event.altKey) {
    return false;
  }

  const key = event.key.toLowerCase();
  const command = GREEK_MAP[key];
  greekModeArmed = false;

  if (!command) {
    setStatus("No Greek mapping for that key.");
    return false;
  }

  if (getActiveMathField()) {
    insertIntoMath(command);
    setStatus(`Inserted ${command.trim()}.`);
    event.preventDefault();
    return true;
  }

  insertMathField(false);
  requestAnimationFrame(() => {
    insertIntoMath(command);
    setStatus(`Inserted ${command.trim()}.`);
  });

  event.preventDefault();
  return true;
}

function handleMathShortcut(event, targetMathField = null) {
  if (event.defaultPrevented) {
    return false;
  }

  const activeMath = targetMathField || getActiveMathField();
  const ctrlPressed = event.ctrlKey || event.metaKey;
  if (!activeMath || !ctrlPressed || event.altKey) {
    return false;
  }

  const key = event.key.toLowerCase();
  const code = (event.code || "").toLowerCase();

  if (key === "r") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "\\sqrt{} ");
    return true;
  }

  if (key === "f") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "\\frac{}{} ");
    return true;
  }

  if (key === "i") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "\\int ");
    return true;
  }

  if (key === "h") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "^{} ");
    return true;
  }

  if (key === "l") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "_{} ");
    return true;
  }

  if (key === "9") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "() ");
    return true;
  }

  if (key === "arrowup" || key === "up" || code === "arrowup") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "^{} ");
    return true;
  }

  if (key === "arrowdown" || key === "down" || code === "arrowdown") {
    event.preventDefault();
    event.stopPropagation();
    insertIntoTargetMath(activeMath, "_{} ");
    return true;
  }

  return false;
}

function findMathFieldFromEvent(event) {
  const path = typeof event.composedPath === "function" ? event.composedPath() : [];
  for (const node of path) {
    if (node && node.matches && node.matches(MATH_FIELD_SELECTOR)) {
      return node;
    }
  }

  if (event.target && event.target.closest) {
    return event.target.closest(MATH_FIELD_SELECTOR);
  }

  return null;
}

function handleEditorKeydown(event) {
  const eventMathField = findMathFieldFromEvent(event);
  if (eventMathField && handleMathShortcut(event, eventMathField)) {
    greekModeArmed = false;
    return;
  }

  if (handleArmedGreekMode(event)) {
    return;
  }

  if (!isEditorContext()) {
    return;
  }

  const ctrlPressed = event.ctrlKey || event.metaKey;
  const key = event.key.toLowerCase();
  const code = (event.code || "").toLowerCase();

  if (ctrlPressed && !event.shiftKey && !event.altKey && key === "m") {
    event.preventDefault();
    greekModeArmed = false;
    toggleInlineMath();
    return;
  }

  if (ctrlPressed && !event.shiftKey && !event.altKey && key === "d") {
    event.preventDefault();
    greekModeArmed = false;
    newDisplayEquation();
    return;
  }

  if (ctrlPressed && !event.shiftKey && !event.altKey && key === "t") {
    event.preventDefault();
    greekModeArmed = false;
    toggleMathFontMode();
    return;
  }

  if (ctrlPressed && !event.shiftKey && !event.altKey && key === "g") {
    event.preventDefault();
    armGreekMode();
    return;
  }

  if (handleMathShortcut(event)) {
    greekModeArmed = false;
    return;
  }

  if (ctrlPressed && !event.shiftKey && !event.altKey) {
    const wantsSuper = key === "arrowup" || key === "up" || code === "arrowup";
    const wantsSub = key === "arrowdown" || key === "down" || code === "arrowdown";

    if (wantsSuper || wantsSub) {
      event.preventDefault();
      if (!getActiveMathField()) {
        insertMathField(false);
      }

      requestAnimationFrame(() => {
        const activeMath = getActiveMathField();
        if (!activeMath) {
          return;
        }

        insertIntoTargetMath(activeMath, wantsSuper ? "^{} " : "_{} ");
        greekModeArmed = false;
      });
      return;
    }
  }

  if (event.key === "Escape") {
    const exited = exitMathMode();
    if (exited) {
      event.preventDefault();
    }
  }
}

window.addEventListener("keydown", handleEditorKeydown, true);

editor.addEventListener("mousedown", () => {
  if (greekModeArmed) {
    greekModeArmed = false;
    setStatus("Greek mode cancelled.");
  }
});
