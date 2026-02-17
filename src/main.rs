mod ai;

use colored::Colorize;
use rusqlite::Connection;
use rustyline::DefaultEditor;
use std::env;

fn introspect_schema(conn: &Connection) -> Result<String, Box<dyn std::error::Error>> {
    let mut stmt = conn.prepare(
        "SELECT sql FROM sqlite_master WHERE type IN ('table', 'view') AND sql IS NOT NULL",
    )?;
    let rows: Vec<String> = stmt
        .query_map([], |row| row.get::<_, String>(0))?
        .collect::<Result<Vec<_>, _>>()?;
    Ok(rows.join("\n\n"))
}

fn is_safe_sql(sql: &str) -> bool {
    let upper = sql.to_uppercase();
    !["DROP", "DELETE", "INSERT", "UPDATE", "ALTER"]
        .iter()
        .any(|kw| upper.contains(kw))
}

fn execute_query(
    conn: &Connection,
    sql: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let mut stmt = conn.prepare(sql)?;
    let col_count = stmt.column_count();
    let col_names: Vec<String> = (0..col_count)
        .map(|i| stmt.column_name(i).unwrap().to_string())
        .collect();

    let mut rows = Vec::new();
    let mut raw_rows = stmt.query([])?;
    while let Some(row) = raw_rows.next()? {
        let mut obj = serde_json::Map::new();
        for (i, name) in col_names.iter().enumerate() {
            let val: rusqlite::types::Value = row.get(i)?;
            let json_val = match val {
                rusqlite::types::Value::Null => serde_json::Value::Null,
                rusqlite::types::Value::Integer(n) => serde_json::json!(n),
                rusqlite::types::Value::Real(f) => serde_json::json!(f),
                rusqlite::types::Value::Text(s) => serde_json::Value::String(s),
                rusqlite::types::Value::Blob(b) => serde_json::json!(format!("<blob {} bytes>", b.len())),
            };
            obj.insert(name.clone(), json_val);
        }
        rows.push(serde_json::Value::Object(obj));
        if rows.len() >= 100 {
            break;
        }
    }

    Ok(serde_json::to_string(&rows)?)
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();

    let db_path = env::var("DB_PATH").unwrap_or_else(|_| "./data.db".to_string());
    let show_sql = env::var("SHOW_SQL")
        .map(|v| v == "true")
        .unwrap_or(true);

    let conn = Connection::open(&db_path).map_err(|e| {
        eprintln!("{} Could not open database at {}: {}", "Error:".red().bold(), db_path, e);
        e
    })?;

    let mut schema = introspect_schema(&conn)?;

    let table_count = schema.matches("CREATE").count();
    println!(
        "Connected to {}",
        db_path.green().bold()
    );
    println!(
        "Schema loaded: {} table(s)",
        table_count.to_string().cyan()
    );
    println!("Type a question or {} to exit\n", ".quit".yellow());

    let mut rl = DefaultEditor::new()?;

    loop {
        let readline = rl.readline(&format!("{} ", ">".green().bold()));
        match readline {
            Ok(line) => {
                let input = line.trim();
                if input.is_empty() {
                    continue;
                }
                let _ = rl.add_history_entry(input);

                match input {
                    ".quit" => {
                        println!("Bye!");
                        break;
                    }
                    ".schema" => {
                        println!("{}", schema);
                    }
                    ".refresh" => {
                        schema = introspect_schema(&conn)?;
                        let count = schema.matches("CREATE").count();
                        println!("Schema refreshed: {} table(s)", count.to_string().cyan());
                    }
                    question => {
                        let sql = match ai::nl_to_sql(&schema, question).await {
                            Ok(sql) => sql,
                            Err(e) => {
                                eprintln!(
                                    "{} {}",
                                    "AI error:".red().bold(),
                                    e
                                );
                                println!("Try rephrasing your question.\n");
                                continue;
                            }
                        };

                        if !is_safe_sql(&sql) {
                            eprintln!(
                                "{} The generated SQL contains disallowed statements. Skipping.",
                                "Safety:".red().bold()
                            );
                            continue;
                        }

                        if show_sql {
                            println!("{} {}", "SQL:".blue().bold(), sql);
                        }

                        let results = match execute_query(&conn, &sql) {
                            Ok(r) => r,
                            Err(e) => {
                                eprintln!(
                                    "{} {}",
                                    "SQL error:".red().bold(),
                                    e
                                );
                                println!("Try rephrasing your question.\n");
                                continue;
                            }
                        };

                        match ai::results_to_nl(&schema, question, &sql, &results).await {
                            Ok(answer) => {
                                println!(
                                    "{} {}\n",
                                    "→".green().bold(),
                                    answer
                                );
                            }
                            Err(e) => {
                                eprintln!(
                                    "{} {}",
                                    "AI error:".red().bold(),
                                    e
                                );
                                println!("Raw results: {}\n", results);
                            }
                        }
                    }
                }
            }
            Err(rustyline::error::ReadlineError::Interrupted | rustyline::error::ReadlineError::Eof) => {
                println!("Bye!");
                break;
            }
            Err(e) => {
                eprintln!("{} {}", "Input error:".red().bold(), e);
                break;
            }
        }
    }

    Ok(())
}
