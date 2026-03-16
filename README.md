# SRSRecover

**Recover and evaluate Software Requirements Specifications (SRS) from limited descriptions using multi-agent LLM pipelines.**

This project implements a pipeline based on large language models for exploring and generating complete Software Requirements Specifications from limited descriptions, and provides evaluation tools to quantitatively assess the quality of generated documents.

## 📋 Project Overview

The project has two core components:

1. **srs-gen** — Multi-version SRS Generator: Explores new requirements and generates multiple versions of SRS documents through an iterative process, using original requirement documents and a baseline SRS.
2. **srs-eval** — Requirement Document Difference Evaluation System: Evaluates requirement documents using large models, with baseline documents as ground truth, to produce quantifiable evaluation scores.

## 🏗️ Project Structure

```
SRSRecover/
├── README.md                 # This file
├── srs-gen/                  # SRS Generator
│   ├── main.py               # Main entry
│   ├── srs_pipeline.py       # Core pipeline logic
│   ├── models.py             # Data models
│   ├── config.yaml           # Configuration (create from config.yaml.example)
│   ├── prompts/              # Prompt templates (zh/, en/)
│   └── README.md             # Detailed usage
└── srs-eval/                 # SRS Evaluation System
    ├── main.py               # Main entry
    ├── src/                  # Source code
    │   ├── evaluator.py      # Evaluation logic
    │   ├── point_extractor.py
    │   └── ...
    ├── prompts/              # Prompt templates (v1, v2, v2_en)
    └── README.md             # Detailed usage
```

## 🚀 Quick Start

### Requirements

- Python >= 3.10
- [uv](https://github.com/astral-sh/uv) (recommended) or pip

### Install Dependencies

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# srs-gen
cd srs-gen
uv sync

# srs-eval
cd ../srs-eval
uv sync
```

### Configure API Keys

Both sub-projects need OpenAI-compatible API configuration.

#### srs-gen

Create `srs-gen/config.yaml` from `config.yaml.example`:

```yaml
openai:
  api_key: "your-api-key-here"   # Or set OPENAI_API_KEY
  base_url: null                 # Optional, for proxy or compatible APIs
  chat:
    model: "gpt-4o-mini"
    temperature: 0.2
  embedding:
    model: "text-embedding-3-small"
```

Or use environment variables:

```bash
export OPENAI_API_KEY="your-api-key-here"
export OPENAI_BASE_URL="https://api.openai.com/v1"  # optional
```

#### srs-eval

Create `srs-eval/.env`:

```bash
OPENAI_API_KEY=your-api-key-here
OPENAI_MODEL=gpt-4
OPENAI_BASE_URL=https://api.openai.com/v1
TEMPERATURE=0
DEFAULT_RUNS=3
```

## 📖 Usage Guide

### 1. SRS Generator (srs-gen)

Iteratively generate multiple SRS versions from limited descriptions.

#### Basic usage

```bash
cd srs-gen

uv run main.py \
  --d-orig path/to/original_srs.md \
  --r-base path/to/requirement_base.md \
  --d-base path/to/baseline_srs.md \
  --output-dir ./output
```

#### Workflow

1. **Semantic unit splitting**: Split baseline SRS into independent semantic units.
2. **Requirement exploration**: Explore new requirements from the requirement base, avoiding duplicates.
3. **Requirement clarification scoring**: Score semantic units (-2 to +2) against the original SRS.
4. **Requirement improvement**: Generate new requirements and extensions from adopted positive requirements.
5. **SRS generation**: Produce SRS documents from scored semantic units.

See **srs-gen/README.md** for full configuration and options.

### 2. SRS Evaluation (srs-eval)

Evaluate generated SRS documents using a baseline as ground truth.

#### Basic usage

```bash
cd srs-eval

# Single document
uv run main.py --baseline path/to/baseline.md --target path/to/target.md

# Multiple documents
uv run main.py --baseline path/to/baseline.md --targets target1.md target2.md target3.md

# Directory
uv run main.py --baseline path/to/baseline.md --target-dir path/to/targets/

# SRS collection (stage grouping)
uv run main.py --baseline path/to/baseline.md --srs-collection-dir path/to/srs_collection/
```

#### Evaluation method

The system uses a **checkpoint-based quantitative method**:

1. **Point extraction**: Extract structured point lists from the baseline (each point has 3–5 checkpoints).
2. **Item-wise evaluation**: Binary pass/fail for each checkpoint.
3. **Scoring**:
   - **Vote pass**: Majority vote per checkpoint, then proportion of checkpoints that pass.
   - **Average pass**: Average of per-run pass counts across judges.

#### Output formats

- **JSON**: Full results per point, checkpoint outcomes, total and sub-scores.
- **CSV**: Document name, vote pass, average pass (batch summary).
- **Markdown**: Point list, per-item results, checkpoint details, summary.
- **TSV**: Raw results from all judges.

#### Reproducibility

- Point list caching: Same baseline → same point list.
- Fixed temperature (e.g. 0) for stable outputs.
- Multiple runs (default 3) with voting on checkpoint results.

See **srs-eval/EVALUATION_METHOD.md** for the full evaluation method.

## 🔄 End-to-end workflow

### Step 1: Generate SRS

```bash
cd srs-gen
uv run main.py \
  --d-orig original_srs.md \
  --r-base requirement_base.md \
  --d-base baseline_srs.md \
  --output-dir ./output
```

Outputs include e.g. `srs_iter_1.md`, `srs_iter_2.md`, …

### Step 2: Evaluate

```bash
cd srs-eval
uv run main.py \
  --baseline original_srs.md \
  --srs-collection-dir ../srs-gen/output/
```

You get per-stage reports (JSON, Markdown, TSV), stage summaries (CSV, Markdown), and cross-stage comparisons.

## 📚 Documentation

- **srs-gen**: [srs-gen/README.md](srs-gen/README.md) — Configuration and usage.
- **srs-eval**: [srs-eval/README.md](srs-eval/README.md) — Usage and options.
- **Evaluation method**: [srs-eval/EVALUATION_METHOD.md](srs-eval/EVALUATION_METHOD.md) — Principles, workflow, and scoring.

## ⚙️ Configuration summary

### srs-gen (`config.yaml`)

- **OpenAI**: API key, model, temperature, embedding model.
- **Iteration**: `rho`, `max_outer_iter`, `max_inner_iter`.
- **Similarity**: Threshold for filtering duplicate requirements.
- **Components**: Per-component model and temperature (split, explorer, clarifier, generator).
- **Robustness**: Retry and delay for each component.

### srs-eval (`.env`)

- **OpenAI**: API key, model, base URL.
- **Evaluation**: Temperature, default number of runs.
- **Prompts**: Versions (v1, v2, v2_en, etc.).

## 🔧 Advanced features

### srs-gen

- Per-component model and temperature.
- Retries for all LLM calls.
- Similarity filtering with embeddings.
- Requirement improvement from adopted requirements.

### srs-eval

- Parallel batch evaluation.
- Point list caching.
- Multiple extractions to maximize checkpoint coverage.
- Matching mode for baseline/target pairs.
- Skip existing results for incremental runs.

## 📝 Notes

1. **API usage**: Both tools call OpenAI-compatible APIs; be aware of cost and quotas.
2. **Models**: Choose models by task (quality vs. cost).
3. **Caching**: Use caches to avoid redundant API calls.
4. **Parallelism**: Batch evaluation runs in parallel; respect rate limits.

## 🤝 Contributing

Issues and pull requests are welcome.

## 📄 License

[To be added]

## 🙏 Acknowledgments

This project relies on large language model APIs. Thanks to OpenAI, DeepSeek, and other providers for model and API support.
