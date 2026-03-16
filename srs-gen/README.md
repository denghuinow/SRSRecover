# Multi-Version SRS Generator

A multi-version Software Requirements Specification (SRS) generation system based on OpenAI LLMs and vector embeddings.

## Overview

The system iteratively runs "requirement exploration → clarification scoring → update requirement pool → generate SRS". Each outer loop produces one SRS document version.

## Project Structure

```
srs-gen2/
├── main.py                    # Main entry
├── srs_pipeline.py            # Core pipeline logic
├── models.py                  # Data models (SemanticUnit)
├── openai_utils.py            # OpenAI API wrapper
├── config.py                  # Config loader
├── config.yaml                # Configuration (YAML)
├── pyproject.toml             # Project config (uv)
├── prompts/                   # Prompt templates
│   ├── split_to_semantic_units.md
│   ├── requirement_explorer.md
│   ├── requirement_clarifier.md
│   └── srs_generator.md
└── README.md
```

## Installation

Use [uv](https://github.com/astral-sh/uv) to manage the environment:

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync
```

## Configuration

### Config file (recommended)

The project uses `config.yaml` for all parameters.

1. **Edit** `config.yaml`:

```yaml
# OpenAI API
openai:
  api_key: "your-api-key-here"  # Or leave empty and use env vars
  base_url: null  # Optional, for proxy or compatible APIs

  chat:
    model: "gpt-4o-mini"
    temperature: 0.2

  embedding:
    model: "text-embedding-3-small"

  # Per-component model/temperature (optional)
  components:
    split_to_semantic_units:
      model: null   # null = use chat.model
      temperature: null
    requirement_explorer:
      model: null
      temperature: null
    requirement_clarifier:
      model: null
      temperature: null
    srs_generator:
      model: null
      temperature: null

# Iteration
iteration:
  rho: 0.5
  max_outer_iter: 5
  max_inner_iter: 3

# Similarity filter
similarity:
  threshold: 0.8

# Logging
logging:
  level: "INFO"
  format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
```

2. **Or use environment variables** (higher priority):

```bash
export OPENAI_API_KEY="your-api-key-here"
export OPENAI_BASE_URL="https://api.openai.com/v1"  # optional
```

### Configuration reference

#### OpenAI

- **openai.api_key**: API key (or set via `OPENAI_API_KEY`)
- **openai.base_url**: API base URL (optional, or `OPENAI_BASE_URL`)
- **openai.chat.model**: Default chat model, default `gpt-4o-mini`
- **openai.chat.temperature**: Default chat temperature, default `0.2`
- **openai.embedding.model**: Embedding model, default `text-embedding-3-small`

#### Per-component config

You can set a different model and temperature per component:

- **openai.components.split_to_semantic_units**: Semantic unit splitting
- **openai.components.requirement_explorer**: Requirement exploration
- **openai.components.requirement_clarifier**: Clarification scoring
- **openai.components.srs_generator**: SRS generation

Each component supports:
- `model`: model name; `null` = use `openai.chat.model`
- `temperature`: temperature; `null` = use `openai.chat.temperature`

**Example**:

```yaml
openai:
  components:
    split_to_semantic_units:
      model: "gpt-4o"   # Stronger model for splitting
      temperature: 0.1  # Lower temp for stability
    requirement_explorer:
      model: "gpt-4o-mini"
      temperature: 0.7  # Higher temp for creativity
    requirement_clarifier:
      model: null
      temperature: null
    srs_generator:
      model: "gpt-4o"
      temperature: 0.3
```

#### Other options

- **iteration.rho**: Fraction of baseline units to explore per round, default `0.5`
- **iteration.max_outer_iter**: Max outer iterations (one SRS per round), default `5`
- **iteration.max_inner_iter**: Max inner iterations per round, default `3`
- **similarity.threshold**: Similarity threshold (0–1), default `0.8`
- **logging.level**: Log level, default `INFO`
- **logging.format**: Log format

#### Retry (robustness)

All LLM-dependent components support retries:

```yaml
robustness:
  split_to_semantic_units:
    max_attempts: 3
    delay_seconds: 2.0
  requirement_explorer:
    max_attempts: 3
    delay_seconds: 2.0
  requirement_clarifier:
    max_attempts: 3
    delay_seconds: 2.0
  srs_generator:
    max_attempts: 3
    delay_seconds: 2.0
```

Defaults: 3 attempts, 2s delay. Retries on JSON parse errors, missing fields, network errors, etc.

## Usage

### Basic

Run with `uv run`:

```python
from main import run_srs_iteration

d_orig = "..."  # Original SRS content (string)
r_base = "..."  # Requirement base content (string)
d_base = "..."  # Baseline SRS content (string)

run_srs_iteration(
    d_orig=d_orig,
    r_base=r_base,
    d_base=d_base,
    output_dir="./output",
    # Optional overrides: rho=0.5, max_outer_iter=5, max_inner_iter=3
)
```

### Command line

```bash
uv run python main.py
# or
uv run -m main
```

## Output

The system writes multiple SRS files under `output_dir`:

- `srs_iter_1.md` — Version 1
- `srs_iter_2.md` — Version 2
- ...

## Core components

### 1. split_to_semantic_units

Splits the baseline SRS into independent semantic units.

**Config**: `openai.components.split_to_semantic_units` (model, temperature).

### 2. requirement_explorer

Explores new requirements from the requirement base and avoids duplicates.

**Config**: `openai.components.requirement_explorer`.

### 3. requirement_clarifier

Scores semantic units (-2 to +2) by alignment with the original SRS.

**Config**: `openai.components.requirement_clarifier`.

### 4. srs_generator

Generates SRS from scored semantic units. **Note**: Units with grade=1 are refined and expanded.

**Config**: `openai.components.srs_generator`.

### 5. filter_low_similarity

Uses OpenAI embeddings and cosine similarity to filter units too similar to existing requirements.

## Notes

1. All LLM calls use prompt templates under `prompts/`.
2. `SemanticUnit` uses `text + grade + vector`; `vector` caches embeddings to avoid repeated API calls.
3. `srs_generator` refines grade=1 units (e.g. sub-requirements, inputs/outputs).
4. Key steps are logged for debugging and monitoring.
5. **Per-component config**: You can set different models and temperatures per component; `null` falls back to `openai.chat` defaults.

## Config priority

1. Function arguments (if passed)
2. Environment variables (`OPENAI_API_KEY`, `OPENAI_BASE_URL`)
3. `config.yaml`
4. Code defaults

## Custom config

1. **Edit `config.yaml`** (recommended)
2. **Set env vars** (e.g. for API key)
3. **Pass function arguments** (for one-off overrides)

Custom config file:

```bash
export SRS_GEN2_CONFIG="/path/to/custom-config.yaml"
```

### Component config tips

- **split_to_semantic_units**: Prefer low temperature (0.1–0.3), stronger model.
- **requirement_explorer**: Higher temperature (0.6–0.8), cheaper model.
- **requirement_clarifier**: Low temperature (0.1–0.3).
- **srs_generator**: Medium temperature (0.2–0.4), stronger model.

## Parameters

- **rho**: New requirements per round = `ceil(rho * number of baseline units)`
- **max_outer_iter**: Max outer iterations (one SRS per round).
- **max_inner_iter**: Max inner iterations per round.
- **threshold**: Similarity threshold (default 0.8) for filtering similar requirements.
