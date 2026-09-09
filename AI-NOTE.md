# How I used AI

I used Claude (Cowork) as the whole working environment for this, not as a lookup. The
method mattered more than the prompting, so that's what I'll describe.

**1. Read the code before touching the app.** I had Claude clone the repo and read the
module map first — `config.py` for the `SEC_*` flags, `validators/m3.py` for what the
grader actually asserts, `guards.py` and `rag.py` for the mechanism. That decided the
layer choice: M3's pass condition is two audit events, both reachable keyless on local
Ollama, so the exercise wouldn't hinge on a frontier model chaining tool calls or on a
BYOK key.

**2. Simulated the attack before running it.** The lab ships `InMemoryKB`,
`InMemoryStore` and `StubLLM`. Rather than guess at payloads against a slow local model,
I drove the real `rag.answer` code path with those primitives and a stubbed reply, and
watched which audit events fired. That told me before I'd spent a single model call that
`poisoned_chunk_in_context` requires the literal marker in the chunk *and* that the
hardened path returns an empty instruction-chunk list — so the fix is deterministic and
the graded attack cannot pass with the flag on. Roughly ten minutes of simulation
replaced an hour of trial and error against a 1B model.

**3. Used the model's weakness to design the payload.** The keyless model is small, so I
built the poison as few-shot rather than instruction — a worked "correctly formatted
answer" containing the marker — because a 1B model copies a demonstrated format far more
reliably than it obeys a directive. That was a deliberate choice about the target, not a
generic jailbreak.

**4. Made Claude argue against its own fix.** The section they weight most is what the
fix misses, so I spent most of the AI budget there: asked for concrete payloads that
would defeat the control, then ran each one and kept the ones that actually worked. Two
survived — the semantic-injection document and the retrieval-starvation flood. Both are
in the write-up with measured results, not asserted ones. A third idea (patching the
retrieval budget as well) I dropped, because I couldn't demonstrate it cleanly inside the
timebox and an undemonstrated fix is worth less than a described gap.

**5. Verified rather than trusted.** Every claim in the write-up is a command I ran. The
canonicalisation gap was found by reading `guards.py` and noticing `canonicalize()` was
defined in the same file but only called from the M8 path — then confirmed by running the
pre-patch and post-patch predicates against the same string. The patch is checked against
the repo's existing suite.

**Where it needed steering.** Left alone it wanted to write more code than the problem
justified. The useful instinct was the opposite one: the smallest diff that closes a real
gap, and put the remaining effort into being precise about what's still open.
