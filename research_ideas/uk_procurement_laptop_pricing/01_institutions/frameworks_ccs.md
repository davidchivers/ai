# frameworks and ccs summary

A framework agreement sets pre-qualified suppliers and terms for a period, and buyers procure via call-offs (mini-competition or direct award where allowed). The framework does not itself guarantee final transaction price for each purchase; call-off design and competition at that stage still matter. TODO_CITE: UK guidance on framework and call-off mechanics.

Framework prices can differ from spot retail because public contracts may include service-level requirements and compliance content not embedded in consumer prices, such as imaging, asset tagging, security configuration, support windows, delivery constraints, and enhanced warranty terms. Therefore, observed unit-price gaps are interpretable only after explicit comparability checks and bundle decomposition. TODO_CITE: CCS technology framework buyer guidance.

## empirical predictions
- Prediction 1: framework call-offs show lower effective bidder counts than open procedures, on average.
- Prediction 2: direct award within framework is associated with higher conditional price gaps than mini-competition.
- Prediction 3: in hardware-only lines with matched warranty terms, framework effects should attenuate if bundles were the main explanation.

## implementation notes
- Always store `framework_id` (example: `RM6098`) and `lot` where available.
- Distinguish `framework_flag` from `direct_award_flag`; they are related but not equivalent.
- Keep non-separable bundled lines out of the main hardware-only benchmark sample.
