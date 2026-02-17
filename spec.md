# nl-sql — Natural Language SQLite Terminal App

A minimal Rust terminal app that lets you query a SQLite database using plain English.
Powered by the OpenAI API for NL→SQL and results→NL conversion.

---

## Goal

Type a question like _"how many users signed up last month?"_ into a terminal, and get a plain English answer back — with the generated SQL shown for transparency.

---

## File Structure

```
nl-sql/
├── Cargo.toml
├── .env
└── src/
    ├── main.rs    # REPL loop, schema introspection, query execution, display
    └── ai.rs      # OpenAI calls: nl→sql and results→nl
```

---

## Dependencies (`Cargo.toml`)

| Crate | Purpose |
|---|---|
| `rusqlite` | SQLite driver |
| `reqwest` | HTTP client for OpenAI API |
| `tokio` | Async runtime |
| `serde` / `serde_json` | Serialization |
| `dotenvy` | `.env` config loading |
| `colored` | Terminal color output |
| `rustyline` | Readline input with history |
| `thiserror` | Typed error handling |

---

## Configuration (`.env`)

```env
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o
DB_PATH=./data.db
SHOW_SQL=true
```

---

## User Flow

```
startup
  └── load .env
  └── open SQLite connection
  └── introspect schema from sqlite_master → cache as string

REPL loop
  └── print prompt: "> "
  └── read user input
      ├── ".quit"    → exit
      ├── ".schema"  → print cached schema
      ├── ".refresh" → re-introspect schema
      └── [anything else]
            └── ai::nl_to_sql(schema, question) → SQL string
            └── print generated SQL (if SHOW_SQL=true)
            └── execute SQL on SQLite
            └── ai::results_to_nl(question, sql, results) → answer string
            └── print answer
```

---

## Module Responsibilities

### `main.rs`
- Load config from `.env`
- Open SQLite DB connection
- Introspect schema at startup: query `sqlite_master`, format as plain text, cache in a `String`
- REPL loop using `rustyline` for input history
- Execute SQL returned from `ai::nl_to_sql`
- Serialize results to JSON for the NL summarizer
- Display generated SQL and final answer in terminal with color

### `ai.rs`

Two public async functions:

```rust
pub async fn nl_to_sql(schema: &str, question: &str) -> Result<String, Error>
pub async fn results_to_nl(question: &str, sql: &str, results: &str) -> Result<String, Error>
```

Both make a `POST` to `https://api.openai.com/v1/chat/completions` using `reqwest`.

---

## Prompt Design

### NL → SQL system prompt

```
You are a SQL expert. Given a SQLite database with the following schema:

{schema}

Convert the user's question into a single valid SQLite SELECT query.
Rules:
- Return ONLY the raw SQL query, no explanation, no markdown
- Use only tables and columns from the schema above
- Default to LIMIT 100 unless the user asks for all results
- Never use DROP, DELETE, UPDATE, INSERT, or ALTER
```

### Results → NL system prompt

```
The user asked: "{question}"
The following SQL was run: "{sql}"
The results were: {results_as_json}

Answer the user's question in one or two plain English sentences based on the results.
Be concise and direct.
```

---

## Error Handling

- All errors use `Box<dyn std::error::Error>` for simplicity
- If OpenAI returns invalid SQL → print the error and the raw response, prompt user to rephrase
- If SQL execution fails → print the SQLite error, do not crash
- If DB file not found → exit with a clear message on startup

---

## Safety

- Only `SELECT` statements are executed. Strip and reject any response containing `DROP`, `DELETE`, `INSERT`, `UPDATE`, or `ALTER` before running.
- Results are capped at 100 rows before being sent to the NL summarizer to control token usage and cost.

---

## Example Session

```
$ cargo run

Connected to data.db
Schema loaded: 3 tables (users, orders, products)
Type a question or .quit to exit

> how many users do we have?
SQL: SELECT COUNT(*) FROM users;
→ You have 1,042 users in the database.

> what were the top 5 products by revenue last month?
SQL: SELECT p.name, SUM(o.total) as revenue FROM orders o
     JOIN products p ON o.product_id = p.id
     WHERE o.created_at >= date('now', '-1 month')
     GROUP BY p.name ORDER BY revenue DESC LIMIT 5;
→ The top 5 products by revenue last month were: Widget A ($12,400),
  Gadget B ($9,800), Doohickey C ($7,200), Thingamajig D ($5,100),
  and Whatsit E ($4,300).

> .quit
Bye!
```

---

## Out of Scope (for now)

- Write operations (INSERT, UPDATE, DELETE)
- Multi-database support
- Query history persistence
- Streaming OpenAI responses
- TUI beyond basic color output