const fs = require("fs");
const path = require("path");

const PROJECT_ROOT = path.resolve(__dirname, "..");
const OUTPUT_ROOT = path.join(
  PROJECT_ROOT,
  "calibration",
  "self_employment_baseline",
  "runtime",
  "data",
  "output"
);

const DEFAULTS = {
  baselineStableDirName: "case_test_new_147_baseline_paper_current",
  baselineSnapshotPrefix: "case_test_new_147_baseline_snapshot_",
  comparisonStableDirName: "case_test_new_147_nourisk_paper_current",
  comparisonSnapshotPrefix: "case_test_new_147_nourisk_snapshot_",
  comparisonLabel: "No unemployment risk",
  maxAsset: 45,
  outputFileName: "case147_no_unemployment_risk_cutoff_panels.tex",
  figureLabel: "fig:case147_no_unemployment_risk_cutoffs",
  employerThreshold: 1.0e-4,
};

const OCCP_EMP = 1;
const OCCP_UNEMP_UI = 2;
const EDU_COUNT = 3;
const EDU_LABELS = ["Low education", "Middle education", "High education"];

function parseArgs(argv) {
  const options = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) {
      continue;
    }
    const key = arg.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith("--")) {
      options[key] = true;
      continue;
    }
    options[key] = next;
    i += 1;
  }
  return options;
}

function resolveDirectory(candidate) {
  if (!candidate) {
    return null;
  }
  const resolved = path.isAbsolute(candidate)
    ? candidate
    : path.resolve(PROJECT_ROOT, candidate);
  return fs.existsSync(resolved) ? resolved : null;
}

function latestDirectoryByPrefix(rootDir, prefix) {
  const matches = fs
    .readdirSync(rootDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name.startsWith(prefix))
    .map((entry) => path.join(rootDir, entry.name))
    .sort();

  return matches.length > 0 ? matches[matches.length - 1] : null;
}

function pickScenarioDirectory(rootDir, stableDirName, snapshotPrefix, explicitDir) {
  const explicit = resolveDirectory(explicitDir);
  if (explicit) {
    return explicit;
  }

  const stable = path.join(rootDir, stableDirName);
  if (fs.existsSync(stable)) {
    return stable;
  }

  const latestSnapshot = latestDirectoryByPrefix(rootDir, snapshotPrefix);
  if (latestSnapshot) {
    return latestSnapshot;
  }

  throw new Error(
    `Could not find scenario output directory. Looked for "${stableDirName}" and prefix "${snapshotPrefix}".`
  );
}

function parseChooseStateNext(filePath, maxAsset) {
  const grouped = new Map();

  for (const rawLine of fs.readFileSync(filePath, "utf8").trim().split(/\r?\n/)) {
    const [aText, xText, eduText, occpText, choiceText] = rawLine.trim().split(/\s+/);
    const asset = Number(aText);
    if (!Number.isFinite(asset) || asset > maxAsset) {
      continue;
    }

    const x = Number(xText);
    const edu = Number(eduText);
    const occpState = Number(occpText);
    const choice = Number(choiceText);

    const key = `${edu}|${asset.toFixed(6)}|${occpState}`;
    if (!grouped.has(key)) {
      grouped.set(key, []);
    }
    grouped.get(key).push({ asset, x, choice });
  }

  const thresholds = {
    employed: Array.from({ length: EDU_COUNT }, () => []),
    unemployed: Array.from({ length: EDU_COUNT }, () => []),
  };

  for (let edu = 0; edu < EDU_COUNT; edu += 1) {
    const assetSet = new Set();
    for (const key of grouped.keys()) {
      const [eduText, assetText] = key.split("|");
      if (Number(eduText) === edu) {
        assetSet.add(Number(assetText));
      }
    }

    const assets = Array.from(assetSet).sort((a, b) => a - b);
    for (const asset of assets) {
      const assetKey = asset.toFixed(6);
      const employedCutoff = firstEntrepreneurChoiceX(
        grouped.get(`${edu}|${assetKey}|${OCCP_EMP}`) || []
      );
      const unemployedCutoff = firstEntrepreneurChoiceX(
        grouped.get(`${edu}|${assetKey}|${OCCP_UNEMP_UI}`) || []
      );

      if (employedCutoff !== null) {
        thresholds.employed[edu].push({ asset, x: employedCutoff });
      }
      if (unemployedCutoff !== null) {
        thresholds.unemployed[edu].push({ asset, x: unemployedCutoff });
      }
    }
  }

  return thresholds;
}

function firstEntrepreneurChoiceX(rows) {
  if (!rows || rows.length === 0) {
    return null;
  }
  rows.sort((left, right) => left.x - right.x);
  const match = rows.find((row) => row.choice === 0);
  return match ? match.x : null;
}

function parseEmployerThresholds(filePath, employerThreshold, maxAsset) {
  const lines = fs.readFileSync(filePath, "utf8").trim().split(/\r?\n/);
  const linesPerEdu = Math.floor(lines.length / EDU_COUNT);
  const grouped = Array.from({ length: EDU_COUNT }, () => new Map());

  lines.forEach((rawLine, index) => {
    const edu = Math.min(EDU_COUNT - 1, Math.floor(index / linesPerEdu));
    const [aText, xText, _kStar, _revStar, _kOpt, nOptText] = rawLine
      .trim()
      .split(/\s+/);
    const asset = Number(aText);
    if (!Number.isFinite(asset) || asset > maxAsset) {
      return;
    }

    const x = Number(xText);
    const nOpt = Number(nOptText);
    const assetKey = asset.toFixed(6);

    if (!grouped[edu].has(assetKey)) {
      grouped[edu].set(assetKey, { asset, x: null });
    }

    if (nOpt > employerThreshold && grouped[edu].get(assetKey).x === null) {
      grouped[edu].get(assetKey).x = x;
    }
  });

  return grouped.map((byAsset) =>
    Array.from(byAsset.values())
      .filter((point) => point.x !== null)
      .sort((left, right) => left.asset - right.asset)
  );
}

function formatNumber(value) {
  return value.toFixed(4).replace(/\.?0+$/, "");
}

function coordinates(points) {
  return points
    .map((point) => `(${formatNumber(point.asset)},${formatNumber(point.x)})`)
    .join(" ");
}

function valueRange(seriesCollection, padding) {
  const values = [];
  for (const series of seriesCollection) {
    for (const point of series) {
      values.push(point.x);
    }
  }

  const min = Math.min(...values);
  const max = Math.max(...values);
  return {
    min: Math.max(0, min - padding),
    max: max + padding,
  };
}

function figureBody(options) {
  const {
    baselineLabel,
    comparisonLabel,
    baselineOccupation,
    comparisonOccupation,
    baselineEmployer,
    comparisonEmployer,
    occRange,
    employerRange,
    figureLabel,
    baselineDir,
    comparisonDir,
    maxAsset,
  } = options;

  const lines = [];
  lines.push("% Auto-generated by generate_case147_no_unemployment_cutoff_figure.js");
  lines.push(`% Baseline source: ${baselineDir.replace(/\\\\/g, "/")}`);
  lines.push(`% Comparison source: ${comparisonDir.replace(/\\\\/g, "/")}`);
  lines.push("\\begin{figure}[H]");
  lines.push("\\centering");
  lines.push("\\begin{tikzpicture}");
  lines.push("\\begin{groupplot}[");
  lines.push("group style={group size=2 by 3, horizontal sep=1.5cm, vertical sep=1.15cm},");
  lines.push("width=0.42\\textwidth,");
  lines.push("height=0.24\\textwidth,");
  lines.push("xmin=0,");
  lines.push(`xmax=${formatNumber(maxAsset)},`);
  lines.push("xlabel={asset level $a$},");
  lines.push("xtick={0,10,20,30,40},");
  lines.push("grid=major,");
  lines.push("grid style={gray!20},");
  lines.push("axis line style={black!60},");
  lines.push("tick style={black!60},");
  lines.push("tick align=outside,");
  lines.push("legend cell align={left},");
  lines.push("]");

  for (let edu = 0; edu < EDU_COUNT; edu += 1) {
    const occLegend =
      edu === 0
        ? "legend style={draw=none, fill=none, at={(0.03,0.97)}, anchor=north west, font=\\scriptsize}"
        : "";
    const employerLegend =
      edu === 0
        ? "legend style={draw=none, fill=none, at={(0.03,0.97)}, anchor=north west, font=\\scriptsize}"
        : "";

    lines.push(
      `\\nextgroupplot[title={${EDU_LABELS[edu]}: entry cutoff}, ylabel={cutoff $x^*$}, ymin=${formatNumber(
        occRange.min
      )}, ymax=${formatNumber(occRange.max)}, ${occLegend}]`
    );
    lines.push(
      `\\addplot[black, thick, const plot, no marks] coordinates {${coordinates(
        baselineOccupation.employed[edu]
      )}};`
    );
    lines.push(
      `\\addplot[black, thick, dashed, const plot, no marks] coordinates {${coordinates(
        baselineOccupation.unemployed[edu]
      )}};`
    );
    lines.push(
      `\\addplot[red!75!black, thick, const plot, no marks] coordinates {${coordinates(
        comparisonOccupation.employed[edu]
      )}};`
    );
    lines.push(
      `\\addplot[red!75!black, thick, dashed, const plot, no marks] coordinates {${coordinates(
        comparisonOccupation.unemployed[edu]
      )}};`
    );
    if (edu === 0) {
      lines.push(
        `\\legend{${baselineLabel} emp,${baselineLabel} unemp,No-risk emp,No-risk unemp}`
      );
    }

    lines.push(
      `\\nextgroupplot[title={${EDU_LABELS[edu]}: employer cutoff}, ylabel={cutoff $x^*$}, ymin=${formatNumber(
        employerRange.min
      )}, ymax=${formatNumber(employerRange.max)}, ${employerLegend}]`
    );
    lines.push(
      `\\addplot[black, thick, const plot, no marks] coordinates {${coordinates(
        baselineEmployer[edu]
      )}};`
    );
    lines.push(
      `\\addplot[red!75!black, thick, const plot, no marks] coordinates {${coordinates(
        comparisonEmployer[edu]
      )}};`
    );
    if (edu === 0) {
      lines.push(`\\legend{${baselineLabel},No-risk}`);
    }
  }

  lines.push("\\end{groupplot}");
  lines.push("\\end{tikzpicture}");
  lines.push(
    `\\caption{Case 147 cutoff comparisons using the current saved ${baselineLabel.toLowerCase()} and ${comparisonLabel.toLowerCase()} policy outputs. Left panels plot the worker-to-entrepreneur occupational cutoff by prior labor-market status. Right panels plot the within-entrepreneur employer threshold implied by the static labor-demand policy; below that line entrepreneurship is self-employment, while above it entrepreneurship uses hired labor.}`
  );
  lines.push(`\\label{${figureLabel}}`);
  lines.push("\\end{figure}");
  lines.push("");
  return `${lines.join("\n")}`;
}

function main() {
  const cli = parseArgs(process.argv.slice(2));
  const maxAsset = cli["max-asset"] ? Number(cli["max-asset"]) : DEFAULTS.maxAsset;
  const baselineDir = pickScenarioDirectory(
    OUTPUT_ROOT,
    DEFAULTS.baselineStableDirName,
    DEFAULTS.baselineSnapshotPrefix,
    cli["baseline-dir"]
  );
  const comparisonDir = pickScenarioDirectory(
    OUTPUT_ROOT,
    DEFAULTS.comparisonStableDirName,
    DEFAULTS.comparisonSnapshotPrefix,
    cli["comparison-dir"]
  );

  const baselineOccupation = parseChooseStateNext(
    path.join(baselineDir, "choose_state_next.txt"),
    maxAsset
  );
  const comparisonOccupation = parseChooseStateNext(
    path.join(comparisonDir, "choose_state_next.txt"),
    maxAsset
  );
  const baselineEmployer = parseEmployerThresholds(
    path.join(baselineDir, "credit_const_v18.txt"),
    DEFAULTS.employerThreshold,
    maxAsset
  );
  const comparisonEmployer = parseEmployerThresholds(
    path.join(comparisonDir, "credit_const_v18.txt"),
    DEFAULTS.employerThreshold,
    maxAsset
  );

  const occRange = valueRange(
    [
      ...baselineOccupation.employed,
      ...baselineOccupation.unemployed,
      ...comparisonOccupation.employed,
      ...comparisonOccupation.unemployed,
    ],
    0.15
  );
  const employerRange = valueRange(
    [...baselineEmployer, ...comparisonEmployer],
    0.08
  );

  const figureText = figureBody({
    baselineLabel: "Baseline",
    comparisonLabel: cli["comparison-label"] || DEFAULTS.comparisonLabel,
    baselineOccupation,
    comparisonOccupation,
    baselineEmployer,
    comparisonEmployer,
    occRange,
    employerRange,
    figureLabel: cli["figure-label"] || DEFAULTS.figureLabel,
    baselineDir,
    comparisonDir,
    maxAsset,
  });

  const outputFile = path.resolve(
    __dirname,
    cli.output || DEFAULTS.outputFileName
  );
  fs.writeFileSync(outputFile, figureText, "utf8");
  process.stdout.write(`Wrote ${outputFile}\n`);
}

main();
