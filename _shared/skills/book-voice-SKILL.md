---
name: book-voice
description: Draft, revise, and structurally edit book chapters, blog posts, and long-form articles in the David-and-Tom explanatory voice. Use when working on `BOOK` / `The Target Trap`, or when the user wants popular-science prose that blends economist precision with journalistic warmth and should be anchored to the user's existing books and draft chapters.
---

# Book Writing

Use this skill for `book/` work and adjacent blog/article writing, not for academic-paper drafting.

## Read first

Always read `_shared/memory/book_blog_article_voice.md` and the target text.

- For chapter drafting or major revision, also read `book/STYLE_GUIDE.md`, `book/Bookmaster Plan.md`, `book/README.md`, `book/resources/literature/STYLE_NOTES.md`, the nearest drafted chapters, and `_shared/agents/book-whole-reader.md`.
- When matching voice closely, read the most relevant source passage from the books in `book/resources/literature/markdown/`.
- For a blog or article, read one or two functionally similar source passages and only the project context relevant to that piece.

## Working mode

- Write in a single unified `we` voice.
- Combine economist precision with journalistic warmth.
- Prefer plain English, British idiom, wry humour, and concrete scenes.
- Keep the prose intelligent without assuming economics training.
- Match punctuation and cadence from the source texts: semicolons, colons, parentheses, rhetorical questions, and short follow-up sentences do real stylistic work here.
- Use explicit tags such as `[TODO: verify this example]` rather than vague placeholders.
- Do not invent references, quotations, or factual claims. Flag uncertainty explicitly.
- Use the source texts as style anchors, not as copy sources.
- Treat the master plan and neighbouring chapters as content constraints, not background decoration.

## Choose the authorship mode

- **Continuity critique:** diagnose chapter role, repeated material, missing promises, and handoffs without rewriting.
- **Source-led edit:** preserve the existing draft and make local changes. Use this as the default when workable prose already exists.
- **Scaffold:** build the scene, claim, example, complication, and payoff sequence for David or Tom to draft.
- **Co-draft:** write new prose only when the user asks for it, using supplied ideas, interviews, notes, and verified sources.
- **Rebuild:** replace a passage wholesale only when its narrative engine is broken or the user explicitly requests a rewrite.

Do not turn a request for comments or polish into an invisible full rewrite.

## Anchor the voice locally

1. Select two or three short passages from the user's books or strongest current chapters that perform the same function as the target passage: opening scene, mechanism explanation, comic aside, bridge, or ending.
2. Note the practical features that matter for this passage, such as sentence turns, joke density, reader address, or the distance between example and explanation.
3. Build a compact ledger of the user-supplied scene, claim, examples, evidence, caveat, and payoff before drafting new prose.
4. Revise structure first, then paragraph movement, then sentences. Do not try to create voice through a final synonym-and-punctuation pass.
5. Preserve strong lines and locally distinctive rhythms unless they obstruct the argument.

Use anchors to constrain choices. Do not average the source books into a generic idea of "conversational" writing.

## Default chapter spine

1. Open with something concrete, relatable, and slightly wrong.
2. Show the pattern before defining it.
3. Introduce the concept name early.
4. Work one example through in enough detail that the mechanism is visible.
5. Broaden to two or three further cases, including one surprising sideways case.
6. Close with a synthetic observation, not a recap.

## Format adjustments

- Book chapter: let the opening scene and the main worked example breathe.
- Long-form article: reach the nut graf earlier while keeping the hook intact.
- Blog post: keep the same voice, but shorten scene-setting and make section turns more explicit.

## Voice checks

- Avoid textbook exposition, managerial jargon, and abstract throat-clearing.
- Prefer named people, objects, rules, and incidents over generic systems language.
- Use small numbers and toy examples when explaining incentives.
- Keep technical depth optional, brief, and clearly signposted.
- Allow "we don't know" or "this is complicated" where the evidence is genuinely mixed.
- Do not flatten the prose into uniformly clean short sentences if the source voice wants one longer, punctuated sentence with an aside or turn in it.
- Avoid reusing favourite analogy templates or callback jokes just because they worked once.
- Let the existing house-style punctuation guidance dominate; do not impose a separate anti-AI punctuation scheme if the line already sounds like the authors.
- Cut stock chatbot signposting such as "here's the thing", "let's explore", or "what this means is" unless the line genuinely sounds like the authors.
- Do not manufacture quirks, grammatical errors, random sentence lengths, or forced irregularity. Variation must follow the thought, comic timing, and source voice.

## Book-specific reminders

- `BOOK` is a popular-science book project, not a paper workflow.
- The goal is not "the textbook wearing a cardigan"; it is an excellent pub conversation with structure.
- Do not re-explain already-established material from scratch when a callback will do.
- Use chapter 2 as a model for the rhythm `rule -> gaming -> precision backfire -> wider analogies -> synthesis about spirit/meta`.
- Diagnose systems and incentives clearly, but do not let the chapter turn into a policy white paper.
- Use chapter 1 as the model for `ordinary domestic irritation -> concept reveal -> widening stakes`.
- Determine from the master plan and neighbouring chapters what this chapter adds; ask only if that remains unresolved.
- Prefer a light callback over a full re-teach when the book has already established the concept.
- Do not overuse formulae such as `it's Goodhart's Law in a wig` or similar costume-joke constructions.
- Do not use the current book title as an in-chapter label, diagnosis, or payoff. For this manuscript, avoid writing `the target trap` in chapter body text unless the user explicitly asks for title/front-matter language.

## Editing order

1. Fix structure and chapter logic first.
2. Tighten hooks, bridges, and section sequencing.
3. Improve sentence-level style and rhythm.
4. Then trim repetition, caveats, clutter, and repeated book-level catchphrases.

## Collaboration workflow

- `David drafts -> review chat -> Tom rewrites -> David comments -> Tom resolves`
- Preserve strong hooks and memorable lines unless there is a clear reason to cut them.
- When revising, protect the chapter's narrative engine before polishing wording.
- Preserve comments, tracked changes, and a format that can return cleanly to Google Docs when the draft is part of the collaborator workflow, unless the user requests another handoff format.

## Protect authorship and provenance

- Do not optimize passages against Pangram or any other detector, use humanizer tools, or run detector-guided rewrite loops.
- Do not promise that a voice skill or heavy editing will make AI-authored prose read as human-authored to a detector.
- Keep model interventions visible and reversible through suggestions, alternatives, tracked changes, or repository diffs.
- Retain David's notes, Tom's rewrites, interview material, and successive drafts when the division of labour may matter.
- For a major rewrite, give a brief change summary distinguishing structural decisions, factual changes, and sentence-level polish. Do not create a separate changelog file.
- Require a final author pass for factual judgment, comic timing, and any line that neither author would naturally say aloud.
- Follow the publisher's, agent's, collaborator's, or commissioning outlet's disclosure rules.

## Handoff check

- Does the opening make a normal reader want to continue?
- Is the mechanism visible before the definition?
- Is at least one example worked through slowly enough to feel real?
- Is there at least one unexpected comparison?
- Does the ending crystallise rather than summarise?
- Before handoff, run `powershell -ExecutionPolicy Bypass -File book/resources/code/check_placeholders.ps1` if placeholders may remain.
