# Math/model/notation QA audit, 2026-05-19

Scope: current canonical May-submission manuscript in `C:\Users\Dave_\Dropbox\Zac and David\2026_May_Submission`, mirrored at `C:\Users\Dave_\AI\research_projects\02_nimbyism_and_housing_supply`. The two TeX files have matching SHA256 hashes. I did not edit manuscript files.

Reference shorthand: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex` means `C:\Users\Dave_\Dropbox\Zac and David\2026_May_Submission\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex`.

## High-priority findings

### 1. Bellman notation drops the transition-time and perceived-path arguments

Refs: `C:\Users\Dave_\Dropbox\Zac and David\2026_May_Submission\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:552`, `:564`, `:591`, `:601`, `:611`, `:621`

The text defines the transition value function as `V^\lambda_{j,t}(s_t; \widehat{\mathbf p}_t(\lambda))`, but the three Bellman equations and the max operator revert to `V^\lambda_j(s_t; p_t)` and use `\widehat p_{t+1|t}` as the continuation argument. This is internally readable, but it is not notation-consistent with the preceding definition and blurs stationary price `p_t`, perceived continuation path `\widehat{\mathbf p}_t`, and the one-period forecast.

Suggested fix: write the Bellmans as `V^{rent,\lambda}_{j,t}(s_t; \widehat{\mathbf p}_t(\lambda))`, `V^{non-adjust,\lambda}_{j,t}(...)`, and `V^{adjust,\lambda}_{j,t}(...)`, with continuation `E_t V^\lambda_{j+1,t+1}(s_{t+1}; \widehat{\mathbf p}_{t+1|t}(\lambda))`. Add one sentence saying that the stationary case suppresses `t` and replaces the perceived path by a constant `p^h`.

### 2. `E_t` is not defined tightly enough for the forecast-rule setup

Refs: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:552`, `:591`, `:601`, `:611`, `:850`

The Bellmans use `E_t`, while the surrounding prose says expectations enter through a perceived price path. A reader can misread `E_t` as integrating over future aggregate/generated prices, even though the forecast rule appears to make the aggregate price path an input and the expectation should be over idiosyncratic income/retirement-state transitions conditional on that path.

Suggested fix: after the forecast-path definition or immediately before the Bellmans, add: `The operator E_t is taken over idiosyncratic income and retirement-income transitions, conditional on the household state and perceived continuation price path; aggregate demographic and price paths are fixed by the forecast rule in this recursion.`

### 3. Age indexing is mostly correct, but the retirement cutoff is easy to misread

Refs: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:445`, `:491`, `:499`, `:920`, `:946`

The paper uses `j=0,\ldots,J-1`, with age `25+j`, so `J=56` covers ages 25 through 80. `J^{retired}=41` is then a working-period cutoff: `j=0,\ldots,40` are ages 25 through 65. That matches line 921, but line 499 says workers "reach retirement age `J^{retired}`", which makes `J^{retired}` sound like a chronological age rather than an index cutoff/number of working periods.

Suggested fix: define `A_j=25+j` once. Rewrite the income-process sentence as `for j=0,\ldots,J^{retired}-1`; retirement income begins at `j=J^{retired}`. In Table 1, label `J^{retired}` as `Working-period cutoff / number of working periods`.

### 4. Transition voting condition needs one explicit equation or sentence

Refs: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:698`, `:751`, `:764`, `:771`, `:850`, `:1517`

The stationary accounting condition is clear: `S_t(p^h)=1/2`. The transition description says the same vote-share object is applied period by period, while the algorithm says voting determines permitted housing and then the market-clearing house price is computed conditional on that permitted stock. Those are compatible only if the transition mapping from votes to permits to price is stated explicitly.

Suggested fix: add one sentence in the transition subsection: either `At each transition date the generated price solves the period-specific median-voter condition, with the perceived path entering votes`, or, if the implementation first maps votes into permitted stock and then clears the market, state that explicitly and avoid implying that `S_t(p^h)=1/2` itself is the transition price equation.

### 5. Perceived-price and generated-price language is mostly clean, but Figure 7 prose slips back to generic "price path"

Refs: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:861`, `:870`, `:1101`, `:1111`, `:1129`, `:1255`

The model section distinguishes perceived paths `\widehat{\mathbf p}` from generated paths `\mathcal T(...)`. Figure 7 is correctly introduced as perceived house-price paths, but the following prose says "The price path then falls back" and Figure 8 says higher `\lambda` dampens the "house-price response." This is not fatal, but it weakens the perceived/generated distinction that the paper now relies on.

Suggested fix: in the Figure 7 and Figure 8 paragraphs, consistently say `perceived price path` or `perceived house-price response` when referring to the plotted object. Reserve `generated price path` for `\mathcal T(...)`.

### 6. LTV source is inconsistent between prose and parameter table

Refs: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:932`, `:955`

The prose says the maximum LTV `m=0.9` follows Greenwald (2018), while Table 1 attributes `m` to Guerrieri and Iacoviello (2017). This is a calibration provenance inconsistency.

Suggested fix: choose the intended source and align both the prose and table row. If Greenwald is intended, change the table source. If Guerrieri and Iacoviello is intended, change the prose sentence.

### 7. The voting perturbation `\epsilon^p` is central but not calibrated or tabulated

Refs: `...\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex:689`, `:707`, `:709`, `:946`, `:1487`

The vote condition depends on the finite price perturbation `\epsilon^p`, and line 709 says `\sigma` is calibrated in the same utility units as this finite-difference comparison. Table 1 reports `\sigma` but not `\epsilon^p`. That leaves the scale of the voting finite difference under-specified.

Suggested fix: add `\epsilon^p` to the parameter table or a note below the voting equation with the actual value used in the computations. If it is only a normalization that rescales `\sigma`, say so explicitly.

## Checks without high-priority findings

- The median-voter caveat at lines 739-746 is directionally adequate: it limits the claim to the one-dimensional, single-peaked theorem and then states the quantitative object as a marginal indifference condition.
- Current equation and figure references appear internally defined in the TeX source; the current log did not show unresolved reference warnings.
- The Dropbox and repo-mirror TeX files are byte-identical by SHA256 at the time of this audit.
