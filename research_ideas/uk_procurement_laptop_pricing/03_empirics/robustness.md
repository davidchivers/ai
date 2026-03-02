# robustness checks

1. High-confidence matching only
- Restrict to confidence `>=0.90` and compare with broader tiers.

2. Warranty-aligned sample
- Keep only observations with explicitly matched warranty terms.

3. Alternative benchmark source tiers
- Re-estimate using source A only, A+B, and A+B+C hierarchies.

4. Timing windows
- Use +/- 7, +/- 14, and +/- 30 day benchmark windows.

5. Outlier sensitivity
- Exclude top/bottom 1% price gaps; compare to full-sample estimates.

6. Goods-only vs bundled
- Separate hardware-only from bundled/non-separable lines.

7. FE and clustering sensitivity
- Buyer FE vs buyer-type FE.
- Buyer-clustered vs contract-clustered SE.

8. Missingness diagnostics
- Show how missing bidder counts or missing warranty fields affect sample composition.

## reporting rule
Each robustness table should restate sample definition to prevent silent composition shifts.
