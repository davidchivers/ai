# Markdown Images + Graphs Test

This file stress-tests image and graph rendering in your preview.

## 1. Local SVG Graph (Line)

![Demo line chart](./demo_line_chart.svg)

## 2. Local SVG Graph (Bars)

![Demo bar chart](./demo_bar_chart.svg)

## 3. Mermaid Graph

```mermaid
graph TD
A[Shock] --> B[Expectations]
A --> C[Costs]
B --> D[Inflation]
C --> D
D --> E[Policy Rate]
E --> F[Output]
```

## 4. Remote Image Test

![Economics image sample](https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Supply-demand-right-shift-demand.svg/640px-Supply-demand-right-shift-demand.svg.png)

## 5. Wide Table

| Year | GDP Growth | Inflation | Policy Rate | Note |
|---|---:|---:|---:|---|
| 2022 | 2.1 | 4.8 | 3.0 | Catch-up demand |
| 2023 | 1.6 | 3.9 | 4.5 | Tightening cycle |
| 2024 | 1.9 | 2.9 | 4.0 | Disinflation begins |
| 2025 | 2.0 | 2.4 | 3.5 | Near target |

If images render but Mermaid does not, we can enable Mermaid-specific settings next.
