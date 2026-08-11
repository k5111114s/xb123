///|
pub fn ci_budget() -> HarBudget {
  HarBudget::{
    max_entries: 150,
    max_total_bytes: 2_500_000,
    max_total_time: 18_000,
    max_average_time: 300,
    max_failed: 0,
    max_redirects: 4,
    max_slowest_time: 1200,
  }
}

///|
pub fn relaxed_budget() -> HarBudget {
  HarBudget::{
    max_entries: 400,
    max_total_bytes: 12_000_000,
    max_total_time: 60_000,
    max_average_time: 900,
    max_failed: 2,
    max_redirects: 15,
    max_slowest_time: 5000,
  }
}

///|
pub fn profile_budget_matrix() -> Array[(String, HarBudget)] {
  [
    ("default", HarBudget::default()),
    ("strict", HarBudget::strict()),
    ("mobile", mobile_budget()),
    ("desktop", desktop_budget()),
    ("api", api_budget()),
    ("docs", documentation_budget()),
    ("ci", ci_budget()),
    ("relaxed", relaxed_budget()),
  ]
}

///|
pub fn render_budget_matrix() -> String {
  let matrix = profile_budget_matrix()
  let mut out = "profile,entries,bytes,total_ms,avg_ms,failed,redirects,slowest_ms\n"
  for i = 0; i < matrix.length(); i = i + 1 {
    let item = matrix[i]
    let b = item.1
    out = out + item.0 + "," +
      b.max_entries.to_string() + "," +
      b.max_total_bytes.to_string() + "," +
      b.max_total_time.to_string() + "," +
      b.max_average_time.to_string() + "," +
      b.max_failed.to_string() + "," +
      b.max_redirects.to_string() + "," +
      b.max_slowest_time.to_string() + "\n"
  }
  out
}

///|
pub fn strictest_budget() -> HarBudget {
  api_budget()
}

///|
pub fn loosest_budget() -> HarBudget {
  relaxed_budget()
}
