///|
/// Redaction options for reports.
pub(all) struct RedactionPolicy {
  redact_query : Bool
  redact_tokens : Bool
  redact_cookies : Bool
  redact_domains : Bool
  replacement : String
} derive(Eq, Show)

///|
pub fn RedactionPolicy::default() -> RedactionPolicy {
  RedactionPolicy::{
    redact_query: true,
    redact_tokens: true,
    redact_cookies: true,
    redact_domains: false,
    replacement: "<redacted>",
  }
}

///|
pub fn redact_url(url : String, policy : RedactionPolicy) -> String {
  let mut result = url
  if policy.redact_query {
    result = strip_query(result)
  }
  if policy.redact_tokens {
    result = redact_token_segments(result, policy.replacement)
  }
  if policy.redact_domains {
    result = replace_domain(result, policy.replacement)
  }
  result
}

///|
pub fn strip_query(url : String) -> String {
  match url.split_once("?") {
    Some((left, _)) => left.to_owned()
    None => url
  }
}

///|
pub fn redact_token_segments(url : String, replacement : String) -> String {
  let parts = url.split("/").collect()
  let mut out = ""
  for i = 0; i < parts.length(); i = i + 1 {
    if i > 0 {
      out = out + "/"
    }
    let part = parts[i].to_owned()
    if looks_sensitive_segment(part) {
      out = out + replacement
    } else {
      out = out + part
    }
  }
  out
}

///|
fn looks_sensitive_segment(part : String) -> Bool {
  part.length() >= 16 ||
  part.to_lower().contains("token") ||
  part.to_lower().contains("secret") ||
  part.to_lower().contains("session")
}

///|
pub fn replace_domain(url : String, replacement : String) -> String {
  match url.split_once("://") {
    Some((scheme, rest)) =>
      match rest.to_string().split_once("/") {
        Some((_, path)) => scheme.to_owned() + "://" + replacement + "/" + path.to_owned()
        None => scheme.to_owned() + "://" + replacement
      }
    None => replacement
  }
}

///|
pub fn redact_pair(pair : HarPair, policy : RedactionPolicy) -> HarPair {
  let lower = pair.name.to_lower()
  if policy.redact_cookies && (lower == "cookie" || lower == "set-cookie") {
    HarPair::{ name: pair.name, value: policy.replacement }
  } else if policy.redact_tokens && (lower.contains("token") || lower.contains("authorization")) {
    HarPair::{ name: pair.name, value: policy.replacement }
  } else {
    pair
  }
}

///|
pub fn redact_pairs(pairs : Array[HarPair], policy : RedactionPolicy) -> Array[HarPair] {
  let out : Array[HarPair] = []
  for i = 0; i < pairs.length(); i = i + 1 {
    out.push(redact_pair(pairs[i], policy))
  }
  out
}

///|
pub fn render_redacted_slow_entries(summary : HarSummary, policy : RedactionPolicy) -> String {
  let mut out = ""
  for i = 0; i < summary.slow_entries.length(); i = i + 1 {
    let entry = summary.slow_entries[i]
    out = out + entry.time.to_string() + "ms "
    out = out + entry.method + " "
    out = out + redact_url(entry.url, policy) + "\n"
  }
  out
}
