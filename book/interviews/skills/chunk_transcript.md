# Skill: Chunk Transcript

## Input
- Cleaned transcript from `transcript/cleaned/`.

## Output
- Chunk files in `transcript/chunks/` named sequentially (`chunk_001.md`, `chunk_002.md`, ...).

## Rules
- Each chunk should be coherent around one theme/question.
- Target chunk size: roughly 400-900 words unless timestamp boundaries suggest otherwise.
- Keep start/end timestamps in every chunk header.
- Do not split a key anecdote across chunks unless unavoidable.

## Procedure
1. Identify natural boundaries: question shifts, topic transitions, story endings.
2. Create chunk headers with:
   - chunk id
   - start timestamp
   - end timestamp
   - one-line topic summary
3. Preserve original wording inside chunks.
4. Add a final `chunks_index.md` listing chunk id and theme.

