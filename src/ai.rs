use serde::{Deserialize, Serialize};
use std::env;

const NL_TO_SQL_SYSTEM: &str = r#"You are an expert SQLite query generator. You are given the full database schema and a user's natural language question. Your job is to produce a single valid SQLite SELECT query that answers the question.

Schema:
{schema}

Rules:
- Return ONLY the raw SQL query — no explanation, no markdown fences, no commentary
- Use only tables and columns that exist in the schema above
- Use proper JOIN syntax when combining tables
- Default to LIMIT 100 unless the user explicitly asks for all results
- Never generate DROP, DELETE, UPDATE, INSERT, ALTER, or any DDL/DML besides SELECT
- Use double-quoted identifiers for table/column names that are reserved words (e.g. "user")
- When the question is ambiguous, prefer the most common-sense interpretation"#;

const RESULTS_TO_NL_SYSTEM: &str = r#"You are a helpful assistant that summarizes database query results in plain English.

You will be given:
1. The database schema for context on what the data represents
2. The user's original question
3. The SQL query that was generated
4. The query results as JSON

Your job is to answer the user's question in one or two concise, natural sentences based on the results. Be direct and specific — include relevant numbers, names, and details from the results. If the results are empty, say so clearly."#;

#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<Message>,
    temperature: f32,
}

#[derive(Serialize, Deserialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    message: Message,
}

async fn chat(system: &str, user_msg: &str) -> Result<String, Box<dyn std::error::Error>> {
    let api_key = env::var("OPENAI_API_KEY")?;
    let model = env::var("OPENAI_MODEL").unwrap_or_else(|_| "gpt-4o".to_string());

    let body = ChatRequest {
        model,
        messages: vec![
            Message {
                role: "system".to_string(),
                content: system.to_string(),
            },
            Message {
                role: "user".to_string(),
                content: user_msg.to_string(),
            },
        ],
        temperature: 0.0,
    };

    let client = reqwest::Client::new();
    let resp = client
        .post("https://api.openai.com/v1/chat/completions")
        .header("Authorization", format!("Bearer {api_key}"))
        .json(&body)
        .send()
        .await?;

    if !resp.status().is_success() {
        let status = resp.status();
        let text = resp.text().await.unwrap_or_default();
        return Err(format!("OpenAI API error ({status}): {text}").into());
    }

    let chat_resp: ChatResponse = resp.json().await?;
    let content = chat_resp
        .choices
        .into_iter()
        .next()
        .map(|c| c.message.content)
        .unwrap_or_default()
        .trim()
        .to_string();

    Ok(content)
}

pub async fn nl_to_sql(schema: &str, question: &str) -> Result<String, Box<dyn std::error::Error>> {
    let system = NL_TO_SQL_SYSTEM.replace("{schema}", schema);
    let sql = chat(&system, question).await?;

    // Strip markdown fences if the model wraps its response
    let sql = sql
        .strip_prefix("```sql")
        .or_else(|| sql.strip_prefix("```"))
        .unwrap_or(&sql);
    let sql = sql.strip_suffix("```").unwrap_or(sql);

    Ok(sql.trim().to_string())
}

pub async fn results_to_nl(
    schema: &str,
    question: &str,
    sql: &str,
    results: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let user_msg = format!(
        "Schema:\n{schema}\n\nQuestion: {question}\n\nSQL executed:\n{sql}\n\nResults:\n{results}"
    );
    chat(RESULTS_TO_NL_SYSTEM, &user_msg).await
}
