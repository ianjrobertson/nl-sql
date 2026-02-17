# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nl-sql is a Rust terminal app that lets users query a SQLite database using plain English. It uses the OpenAI API to convert natural language to SQL and summarize results back to natural language. The project is in early development (scaffolded but not yet implemented).

## Build & Run Commands

- `cargo build` — compile the project
- `cargo run` — run the REPL
- `cargo test` — run all tests
- `cargo test <test_name>` — run a single test
- `cargo clippy` — lint
- `cargo fmt` — format code

## Architecture

Two source files:

- **`src/main.rs`** — Entry point. Loads `.env` config, opens SQLite connection, introspects schema from `sqlite_master`, runs REPL loop (using `rustyline`). Handles dot-commands (`.quit`, `.schema`, `.refresh`). Executes SQL returned from `ai::nl_to_sql`, serializes results to JSON, passes to `ai::results_to_nl`, displays answer with color.
- **`src/ai.rs`** — Two public async functions: `nl_to_sql(schema, question)` and `results_to_nl(question, sql, results)`. Both POST to the OpenAI chat completions API via `reqwest`.

## Configuration

Requires a `.env` file with: `OPENAI_API_KEY`, `OPENAI_MODEL`, `DB_PATH`, `SHOW_SQL`.

## Key Constraints

- Uses Rust edition 2024
- Only SELECT queries are executed — any response containing DROP/DELETE/INSERT/UPDATE/ALTER must be rejected before execution
- Results are capped at 100 rows before sending to the NL summarizer (token cost control)
- Errors use `Box<dyn std::error::Error>` — no custom error types
