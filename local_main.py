"""Low-memory local entrypoint for the M1 (chatbot) lab.

Same halcyon.web.create_app the shipped app uses, same routes, same validators.
Differences from halcyon/main.py, both to avoid needing Docker:

  * InMemoryStore instead of PostgresStore  -> no Postgres container.
  * MCP hosts stubbed                       -> no mcp-core-banking / mcp-crm containers.
  * EIGER_KB=memory falls back to InMemoryKB -> no ONNX embedding download.

Everything M1 touches -- /api/chat, /validate/m1, /reset/m1, /api/level,
halcyon.guards.assemble, halcyon.canary.scan_and_record -- is the unmodified upstream code.

Run:  OLLAMA_URL=http://127.0.0.1:11434 OLLAMA_MODEL=llama3.2:1b \
      uvicorn local_main:app --host 127.0.0.1 --port 8000
"""
import os

from halcyon import bank_fixtures, kb_fixtures
from halcyon.config import load_settings
from halcyon.kb import InMemoryKB
from halcyon.llm import build_llm
from halcyon.session_resources import BankProvider, KBProvider, slug
from halcyon.store import InMemoryStore
from halcyon.web import create_app

_settings = load_settings(os.environ)
_store = InMemoryStore()

if os.environ.get("EIGER_KB", "chroma").lower() == "memory":
    _kb_for = KBProvider(lambda sid: InMemoryKB(), kb_fixtures.SEED)
else:
    from halcyon.chroma_kb import ChromaKB
    _kb_for = KBProvider(lambda sid: ChromaKB(collection=slug(sid)), kb_fixtures.SEED)

_bank_for = BankProvider(bank_fixtures.seed_for)


def _factory(provider=None, model=None, api_key=None):
    return build_llm(_settings, provider, model, api_key)


def _unavailable(*_args, **_kwargs):
    raise RuntimeError("agent/MCP layers are not wired in the M1-only local entrypoint")


app = create_app(
    _store, _settings, _factory, _kb_for, _bank_for, _unavailable, _unavailable,
)
