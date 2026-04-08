# Tiny Stata data demo

Read this file and do the task for me. Do not just explain it.

Assume you have no context other than this folder.

## Goal

Run a very small Stata demo that is fast enough for a live workshop:

1. create a tiny fake dataset inside Stata
2. open Stata
3. relabel a few variables
4. make one graph
5. run one regression
6. keep the graph visible at the end

## What to use

- Preferred Stata executable:
  - `C:\Program Files\StataNow19\StataSE-64.exe`
- Working folder:
  - `C:\Users\Dave_\AI\_01 WORKSHOP`
- Preferred do-file path:
  - `C:\Users\Dave_\AI\_01 WORKSHOP\08 - data - tiny_stata_demo.do`

## What you should do

1. Check that `C:\Program Files\StataNow19\StataSE-64.exe` exists.
2. Save the exact Stata script below to:
   - `C:\Users\Dave_\AI\_01 WORKSHOP\08 - data - tiny_stata_demo.do`
3. Open Stata using the GUI executable above.
4. Run that do-file.
5. Do not close Stata after the do-file finishes.
6. Make sure the graph window remains visible at the end.
7. If something fails, fix it and retry rather than stopping at explanation.

## Exact Stata script to run

```stata
clear all
set more off

display "Creating tiny fake AI-productivity dataset..."
set obs 40
set seed 12345

gen AI = runiform()
gen productivity = 50 + 30*AI + rnormal(0,5)

label variable AI "AI adoption"
label variable productivity "Productivity"

display "Making graph..."
twoway ///
    (scatter productivity AI, mcolor(navy%60) msymbol(circle_hollow)) ///
    (lfit productivity AI, lcolor(maroon)), ///
    title("Tiny Stata demo") ///
    subtitle("Fake AI and productivity data") ///
    name(tiny_stata_demo, replace)

display "Running regression..."
reg productivity AI

display "Keeping graph visible..."
graph display tiny_stata_demo

display "Done."
```

## Expected dataset

Create a very small fake dataset with:

- `AI`
- `productivity`

The fake data should show a clear positive correlation between `AI` and `productivity`.

## Expected output

- A scatter plot of `productivity` against `AI` with a fitted line
- A regression of `productivity` on `AI`

## Important

- This is a live demo task, so keep it small and quick.
- Prefer doing the task over describing the task.
- Do not rely on any other Markdown file outside this folder.
