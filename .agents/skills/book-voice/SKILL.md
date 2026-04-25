---
name: book-voice
description: Draft, revise, and structurally edit book chapters, blog posts, and long-form articles in the David-and-Tom explanatory voice. Use when working on `BOOK` / `The Target Trap`, or when the user wants popular-science prose that blends economist precision with journalistic warmth and should be anchored to the user's existing books and draft chapters.
---

# Book Writing

Use this skill for `book/` work and adjacent blog/article writing, not for academic-paper drafting.

## Read first

1. `_shared/memory/book_blog_article_voice.md`
2. `book/STYLE_GUIDE.md`
3. `book/Bookmaster Plan.md`
4. `book/README.md`
5. `book/resources/literature/STYLE_NOTES.md`
6. If matching voice closely, read the most relevant source text in:
   - `book/resources/literature/markdown/How To Read Numbers V4.md`
   - `book/resources/literature/markdown/Everything is Predictable V4.md`
   - `book/resources/literature/markdown/The AI Does Not Hate You V3.md`
7. If revising a chapter, read the relevant draft in `book/draft_chapters/` and `book/draft_chapters/README.md`
8. For chapter drafting or major revision, also use `_shared/agents/book-whole-reader.md` and read the nearest drafted chapters by number so the chapter works as part of the book rather than as a standalone article.

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

## Book-specific reminders

- `BOOK` is a popular-science book project, not a paper workflow.
- The goal is not "the textbook wearing a cardigan"; it is an excellent pub conversation with structure.
- Do not re-explain already-established material from scratch when a callback will do.
- Use chapter 2 as a model for the rhythm `rule -> gaming -> precision backfire -> wider analogies -> synthesis about spirit/meta`.
- Diagnose systems and incentives clearly, but do not let the chapter turn into a policy white paper.
- Use chapter 1 as the model for `ordinary domestic irritation -> concept reveal -> widening stakes`.
- Before drafting, ask what this chapter adds that earlier chapters have not already earned.
- Prefer a light callback over a full re-teach when the book has already established the concept.
- Do not overuse formulae such as `it's Goodhart's Law in a wig` or similar costume-joke constructions.

## Editing order

1. Fix structure and chapter logic first.
2. Tighten hooks, bridges, and section sequencing.
3. Improve sentence-level style and rhythm.
4. Then trim repetition, caveats, clutter, and repeated book-level catchphrases.

## Collaboration workflow

- `David drafts -> review chat -> Tom rewrites -> David comments -> Tom resolves`
- Preserve strong hooks and memorable lines unless there is a clear reason to cut them.
- When revising, protect the chapter's narrative engine before polishing wording.

## Handoff check

- Does the opening make a normal reader want to continue?
- Is the mechanism visible before the definition?
- Is at least one example worked through slowly enough to feel real?
- Is there at least one unexpected comparison?
- Does the ending crystallise rather than summarise?
- Before handoff, run `powershell -ExecutionPolicy Bypass -File book/resources/code/check_placeholders.ps1` if placeholders may remain.
