# Requirement Document Difference Evaluation System

Evaluates requirement documents using LLMs with a baseline document as ground truth.

> 📖 **Evaluation method**: See [EVALUATION_METHOD.md](./EVALUATION_METHOD.md) for principles, workflow, and scoring.

## Features

- Extract structured point lists from baseline documents automatically
- Evaluate target documents item-by-item and compute quantitative scores
- Support both vote-pass and average-pass metrics
- Reproducible results (fixed temperature, multiple runs, averaging)
- Output in JSON, CSV, and Markdown

## Installation

Use [uv](https://github.com/astral-sh/uv):

```bash
# Install uv (if needed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync
```

## Configuration

Create a `.env` file with your OpenAI API settings:

```bash
# Create .env
cat > .env << EOF
# OpenAI API key (required)
OPENAI_API_KEY=your_openai_api_key_here

# Model (default: gpt-4)
OPENAI_MODEL=gpt-4

# API base URL (default: https://api.openai.com/v1)
# Use for proxy or OpenAI-compatible endpoints
OPENAI_BASE_URL=https://api.openai.com/v1

# Temperature (default: 0 for reproducibility)
TEMPERATURE=0

# Default number of runs (default: 3 for averaging)
DEFAULT_RUNS=3
EOF
```

### Config reference

- **OPENAI_API_KEY**: Required.
- **OPENAI_MODEL**: Model name, default `gpt-4` (e.g. `gpt-3.5-turbo`).
- **OPENAI_BASE_URL**: For proxy or compatible APIs.
- **TEMPERATURE**: Keep 0 for reproducible evaluation.
- **DEFAULT_RUNS**: Number of runs for averaging.

## Usage

Run with `uv run main.py`.

### Evaluate a single document

```bash
uv run main.py --baseline baseline.md --target target1.md
```

### Batch evaluate

```bash
uv run main.py --baseline baseline.md --targets target1.md target2.md target3.md
```

### Multiple runs (reproducibility)

```bash
uv run main.py --baseline baseline.md --target target1.md --runs 3
```

Runs are executed in parallel when applicable.

### Output format

```bash
# JSON
uv run main.py --baseline baseline.md --target target1.md --output json

# CSV
uv run main.py --baseline baseline.md --target target1.md --output csv

# Markdown (default)
uv run main.py --baseline baseline.md --target target1.md --output markdown

# All formats
uv run main.py --baseline baseline.md --target target1.md --output all
```

### Output directory

```bash
uv run main.py --baseline baseline.md --target target1.md --output-dir results
```

### Point list cache

Point lists are cached so the same baseline always uses the same points and checkpoints:

```bash
# First run: extract and cache
uv run main.py --baseline baseline.md --target target1.md

# Later: use cached points
uv run main.py --baseline baseline.md --target target2.md

# Force re-extract
uv run main.py --baseline baseline.md --target target1.md --force-extract
```

### Multiple extractions (best of N)

To get a more complete point list, run extraction multiple times and keep the result with the most checkpoints:

```bash
# Run extraction 3 times, keep best
uv run main.py --baseline baseline.md --target target1.md --extract-runs 3

# With force re-extract
uv run main.py --baseline baseline.md --target target1.md --extract-runs 5 --force-extract
```

**Behavior**:
- Run extraction N times
- Choose the result with the most checkpoints
- Cache the chosen result for future runs
- Extractions run in parallel

Cache is under `.cache/points/`, keyed by document path and content hash.

### Parallel execution

```bash
# Batch (parallel)
uv run main.py --baseline baseline.md --targets target1.md target2.md target3.md

# Multiple extractions (parallel)
uv run main.py --baseline baseline.md --target target1.md --extract-runs 5

# Multiple runs (parallel)
uv run main.py --baseline baseline.md --target target1.md --runs 3

# Limit concurrency
uv run main.py --baseline baseline.md --targets target1.md target2.md --max-workers 5
```

Parallelism applies to: multiple extractions (`--extract-runs > 1`), multiple evaluation runs (`--runs > 1`), and batch targets. Use `--max-workers` to cap concurrency.

## Scoring

### Checkpoint-based evaluation

1. **Point extraction**: From the baseline, extract points; each point has 3–5 checkpoints (verifiable, objective criteria).
2. **Evaluation**: For each point and checkpoint, binary pass/fail based on whether the target document satisfies it. Missing points are failed.
3. **Scores**:
   - **Vote pass**: Majority vote per checkpoint (pass if >50% judges pass), then fraction of checkpoints that pass.
   - **Average pass**: Average over judges of the fraction of passed checkpoints.

### Benefits

- **Quantitative**: Based on checkpoint pass rates, not subjective scores
- **Reproducible**: Same point list and settings → consistent results
- **Inspectable**: Per-checkpoint pass/fail in reports
- **Transparent**: Reports include full checkpoint details

## Output formats

- **JSON**: Per-point results, checkpoint outcomes, total and sub-scores
- **CSV**: Document name, vote pass, average pass (batch summary)
- **Markdown**: Point list, per-item results, checkpoint details, summary

Outputs go to `output/` by default.

### Markdown report contents

- Overall scores (vote pass, average pass)
- Point list (from baseline)
- Per-item evaluation and per-checkpoint pass/fail

## Reproducibility

1. **Point list cache**: First extraction is cached under `.cache/points/`; same baseline reuses it. Use `--force-extract` to re-extract.
2. **Best-of-N extraction**: `--extract-runs` runs extraction N times and keeps the result with the most checkpoints; result is cached.
3. **Checkpoint-based scoring**: Binary checkpoints instead of subjective ratings.
4. **Fixed temperature**: temperature=0 for stable outputs.
5. **Structured prompts**: Standard templates to reduce variance.
6. **Multiple runs**: Default 3 runs; majority vote per checkpoint; average used for final score (configurable via `--runs`).
7. **Consistent checkpoints**: Same list yields consistent results across runs.

## Project structure

```
srs-eval/
├── main.py                 # Entry point
├── pyproject.toml          # Project config (uv)
├── src/
│   ├── __init__.py
│   ├── config.py          # Config
│   ├── document_parser.py # Document parsing
│   ├── point_extractor.py # Point extraction (with cache)
│   ├── evaluator.py       # Evaluation logic
│   └── output_formatter.py # Output formatting
├── prompts/
│   ├── extract_points.txt  # Extraction prompt
│   └── evaluate_points.txt # Evaluation prompt
├── .cache/                 # Cache (auto-created)
│   └── points/             # Point list cache
└── output/                 # Output (auto-created)
```
