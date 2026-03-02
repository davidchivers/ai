# uk procurement background

## purpose
This note provides institutional context for empirical design choices in the laptop-pricing project. It is intentionally source-aware but does not yet embed final citations; all citation anchors are marked as TODO.

## 1) uk portals and notice structure
In the UK procurement system, Contracts Finder is a central portal used to publish opportunities and award notices for many public buyers, with publication requirements tied to contract values and procedural rules. In practice, notice-level metadata typically include buyer identity, dates, route/procedure text, and total value, but often not reliable line-item unit pricing. This matters directly for our measurement strategy: per-unit laptop prices generally require downloading and parsing award attachments such as pricing schedules, clarifications, or award spreadsheets rather than relying on headline notice fields alone. TODO_CITE: Contracts Finder guidance, threshold publication rules, and notice field definitions.

Find a Tender is the portal for higher-value regulated procurement notices and related lifecycle records. For empirical work, this is relevant because larger and more formal competitions may appear there with richer procedure coding, while line-item financial detail still commonly sits in attached files or external documents. We should treat portal source as an informative data feature (metadata depth, route granularity, likely contract size), not as a direct quality ranking. TODO_CITE: Find a Tender legal/operational guidance and scope.

## 2) frameworks and call-offs in this context
Framework agreements are pre-arranged supplier lists and terms under which buyers later run mini-competitions or direct awards (depending on framework rules). Operationally, frameworks can lower search and transaction costs: pre-vetted suppliers, standard terms, and faster award execution. But they can also alter effective competition at call-off stage because the candidate supplier set is restricted to framework members, and some routes may allow direct award without a full mini-competition.

For this paper, frameworks are not presumed good or bad ex ante. Instead, they are a mechanism to test: do lower transaction costs and compliance support offset any reduction in competitive pressure when measured as SKU-level price gaps relative to external benchmarks? TODO_CITE: framework mechanics in UK procurement law/guidance.

## 3) ccs technology hardware procurement relevance
Crown Commercial Service (CCS) framework usage is central for UK commodity IT procurement. Technology Products & Associated Services 2 (RM6098) is a key example used for hardware purchasing in practice. Buyer guidance indicates that associated services can be procured alongside hardware, including support-type components that matter for total value and unit pricing interpretation. This institutional feature is critical for identification: a contract line that looks like "laptop" may embed non-hardware service value (imaging, warranty extension, deployment, security configuration, delivery commitments), so naive comparison to retail list prices can overstate true overpayment.

The empirical implication is immediate: we require explicit bundle tagging and, where possible, decomposition into hardware and non-hardware components. Non-separable lines should be analysed in separate specifications rather than mixed into the core hardware-only estimate. TODO_CITE: CCS RM6098 buyer guidance and lot/service scope documentation.

## 4) why this institutional framing supports causal design
Institutional rules imply measurable channels:
- Route/compliance channels: open procedure vs restricted/framework call-off/direct award.
- Competition channels: bidder count and supplier concentration under route constraints.
- Service-content channels: hardware-only versus bundled deliverables.
- Timing channels: award-date mismatch to market benchmark windows.

These channels map directly into identification and robustness design in `03_empirics/`.

## 5) concrete data consequences
- We should expect heavy missingness in notice-level unit pricing and rely on attachment parsing.
- We should encode portal source and route metadata as potential selection variables.
- We should preserve raw text from pricing schedules to audit extraction and matching errors.
- We should maintain a strict comparability flag so only aligned warranty/service terms enter the main estimand.

## 6) open institutional checks
- TODO_CITE: exact value thresholds and date-specific rule changes for publication/procedure requirements.
- TODO_CITE: legal basis for direct award conditions within relevant frameworks.
- TODO_CITE: procedural distinctions between central government and wider public-sector buyers where applicable.
- TODO_DATA: verify what bidder-count fields are systematically available by portal/notice type.

## takeaway
Institutional rules make this question empirically tractable but also easy to mis-measure. The paper should treat attachments, bundle content, and route-specific competition as first-order design elements rather than data-cleaning afterthoughts.
