"""Generate a submission-style flow diagram for 'Enter Period Employed'."""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

plt.rcParams.update(
    {
        "font.family": "serif",
        "mathtext.fontset": "cm",
        "font.size": 12,
    }
)

fig, ax = plt.subplots(figsize=(12.5, 4.8))
fig.subplots_adjust(left=0.03, right=0.995, top=0.97, bottom=0.12)

# Manual column geometry tuned for visual balance.
x_s, x_a, x_b, x_c = 0.0, 3.6, 7.2, 10.6
w_s, w_a, w_b, w_c = 2.1, 2.7, 1.8, 3.2

x_left, x_right = -0.8, 14.6

ax.set_xlim(x_left, x_right + 0.4)
ax.set_ylim(-3.8, 2.8)
ax.axis("off")

y_h, y1, y2, y3, y_tl = 2.2, 1.0, -0.4, -1.8, -3.1

# Headers centered over their column widths.
x_hs = x_s + 0.5 * w_s
x_ha = x_a + 0.5 * w_a
x_hb = x_b + 0.5 * w_b
x_hc = x_c + 0.5 * w_c
header_shift = -0.35

for x, label in [
    (x_hs, "Enter Period"),
    (x_ha, "Occupational Choice"),
    (x_hb, "Matching"),
    (x_hc, "Production"),
]:
    ax.text(
        x + header_shift, y_h, label, ha="center", va="center", fontsize=12, fontstyle="italic"
    )
ax.plot([x_left + 0.1, x_right - 0.1], [1.6, 1.6], color="#8f8f8f", lw=0.7)

txt = dict(ha="left", va="center", fontsize=12)

# Body text (same row => same y, Excel-like structure).
ax.text(x_s, y2, "Employed", **txt)

ax.text(x_a, y1, "Worker", **txt)
ax.text(x_a, y3, "Entrepreneur", **txt)

ax.text(x_b, y1, "Not fired", **txt)
ax.text(x_b, y2, "Fired", **txt)

ax.text(x_c, y1, "Employed\n(earn wages)", multialignment="left", **txt)
ax.text(x_c, y2, "Unemployed\n(claim benefits)", multialignment="left", **txt)
ax.text(x_c, y3, "Entrepreneur\n(earn profits)", multialignment="left", **txt)

arrow = dict(arrowstyle="->", color="black", lw=1.15, mutation_scale=10)

# Flows
split_x = x_s + 1.9
ax.annotate("", xy=(x_a - 0.25, y1), xytext=(split_x, y2), arrowprops=arrow)
ax.annotate("", xy=(x_a - 0.25, y3), xytext=(split_x, y2), arrowprops=arrow)

ax.annotate("", xy=(x_b - 0.25, y1), xytext=(x_a + 1.75, y1), arrowprops=arrow)
ax.annotate("", xy=(x_b - 0.25, y2), xytext=(x_a + 1.75, y1), arrowprops=arrow)

ax.annotate("", xy=(x_c - 0.25, y1), xytext=(x_b + 1.45, y1), arrowprops=arrow)
ax.annotate("", xy=(x_c - 0.25, y2), xytext=(x_b + 0.95, y2), arrowprops=arrow)
ax.annotate("", xy=(x_c - 0.25, y3), xytext=(x_a + 2.1, y3), arrowprops=arrow)

# Timeline
ax.annotate(
    "",
    xy=(x_right - 0.40, y_tl),
    xytext=(x_left + 0.1, y_tl),
    arrowprops=dict(arrowstyle="->", color="black", lw=0.9, linestyle="dashed"),
)
ax.text(x_left - 0.15, y_tl, r"$t$", ha="center", va="center", fontsize=13)
ax.text(x_right + 0.10, y_tl, r"$t+1$", ha="center", va="center", fontsize=13)

out_png = Path(__file__).with_name("Enter Period Employed_submission.png")
out_pdf = Path(__file__).with_name("Enter Period Employed_submission.pdf")
fig.savefig(out_png, dpi=400, facecolor="white")
fig.savefig(out_pdf, facecolor="white")
plt.close(fig)

print(f"Wrote: {out_png}")
print(f"Wrote: {out_pdf}")
