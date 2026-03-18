import matplotlib.pyplot as plt
import numpy as np


rng = np.random.default_rng(12345)
n = 40

ai = rng.uniform(0, 1, n)
productivity = 50 + 30 * ai + rng.normal(0, 5, n)

# Tiny OLS by hand using numpy so the demo stays lightweight.
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
