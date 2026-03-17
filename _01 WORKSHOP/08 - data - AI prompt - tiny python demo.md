# Tiny Python data demo

Read this file and do the task for me. Do not just explain it.

Assume you have no context other than this folder.

## Goal

Run a very small end-to-end Python demo that is fast enough for a live workshop:

1. create a tiny fake dataset inside Python
2. save the Python script
3. run the script
4. make one graph
5. run one tiny regression
6. keep the graph visible at the end

## What to use

- Preferred Python executable:
  - `C:\Users\Dave_\AppData\Local\Programs\Python\Python312\python.exe`
- Working folder:
  - `C:\Users\Dave_\AI\_01 WORKSHOP`
- Preferred script path:
  - `C:\Users\Dave_\AI\_01 WORKSHOP\08 - data - tiny_python_demo.py`

## What you should do

1. Check that `C:\Users\Dave_\AppData\Local\Programs\Python\Python312\python.exe` exists.
2. Save the exact Python script below to:
   - `C:\Users\Dave_\AI\_01 WORKSHOP\08 - data - tiny_python_demo.py`
3. Run that script with the Python executable above.
4. Do not close the graph window at the end.
5. If something fails, fix it and retry rather than stopping at explanation.

## Exact Python script to run

```python
import matplotlib.pyplot as plt
import numpy as np


rng = np.random.default_rng(12345)
n = 40

ai = rng.uniform(0, 1, n)
productivity = 50 + 30 * ai + rng.normal(0, 5, n)

X = np.column_stack([np.ones(n), ai])
beta = np.linalg.lstsq(X, productivity, rcond=None)[0]
intercept, slope = beta
fitted = intercept + slope * ai

print("Tiny Python demo")
print()
for i in range(5):
    print(f"row {i + 1}: AI={ai[i]:.3f}, productivity={productivity[i]:.3f}")
print()
print(f"Regression: productivity = {intercept:.3f} + {slope:.3f} * AI")

plt.figure(figsize=(7, 4))
plt.scatter(ai, productivity, facecolors="none", edgecolors="navy", alpha=0.8)
order = np.argsort(ai)
plt.plot(ai[order], fitted[order], color="maroon", linewidth=2)
plt.title("Tiny Python demo")
plt.xlabel("AI adoption")
plt.ylabel("Productivity")
plt.tight_layout()
plt.show()
```

## Expected dataset

Create a very small fake dataset with:

- `AI`
- `productivity`

The fake data should show a clear positive correlation between `AI` and `productivity`.

## Expected output

- A scatter plot of `productivity` against `AI` with a fitted line
- A printed regression line for `productivity` on `AI`

## Important

- This is a live demo task, so keep it small and quick.
- Prefer doing the task over describing the task.
- Do not rely on any other Markdown file outside this folder.
