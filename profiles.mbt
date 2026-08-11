///|
pub fn mobile_budget() -> HarBudget {
  HarBudget::{
    max_entries: 120,
    max_total_bytes: 1_500_000,
    max_total_time: 15_000,
    max_average_time: 400,
    max_failed: 0,
    max_redirects: 3,
    max_slowest_time: 1500,
  }
}

///|
pub fn desktop_budget() -> HarBudget {
  HarBudget::{
    max_entries: 180,
    max_total_bytes: 3_000_000,
    max_total_time: 20_000,
    max_average_time: 350,
    max_failed: 0,
    max_redirects: 5,
    max_slowest_time: 1500,
  }
}

///|
pub fn api_budget() -> HarBudget {
  HarBudget::{
    max_entries: 60,
    max_total_bytes: 500_000,
    max_total_time: 8_000,
    max_average_time: 200,
    max_failed: 0,
    max_redirects: 0,
    max_slowest_time: 800,
  }
}

///|
pub fn documentation_budget() -> HarBudget {
  HarBudget::{
    max_entries: 250,
    max_total_bytes: 8_000_000,
    max_total_time: 45_000,
    max_average_time: 700,
    max_failed: 0,
    max_redirects: 8,
    max_slowest_time: 3000,
  }
}

///|
pub fn budget_by_profile(name : String) -> HarBudget {
  match name {
    "mobile" => mobile_budget()
    "desktop" => desktop_budget()
    "api" => api_budget()
    "docs" => documentation_budget()
    "strict" => HarBudget::strict()
    _ => HarBudget::default()
  }
}

///|
pub fn profile_names() -> Array[String] {
  ["default", "strict", "mobile", "desktop", "api", "docs"]
}

///|
pub fn describe_profile(name : String) -> String {
  let b = budget_by_profile(name)
  name + ": entries<=" + b.max_entries.to_string() +
  " bytes<=" + b.max_total_bytes.to_string() +
  " avg_ms<=" + b.max_average_time.to_string() +
  " failed<=" + b.max_failed.to_string()
}

///|
pub fn render_profiles() -> String {
  let names = profile_names()
  let mut out = ""
  for i = 0; i < names.length(); i = i + 1 {
    out = out + describe_profile(names[i]) + "\n"
  }
  out
}

///|
pub fn best_profile_for_archive(archive : HarArchive) -> String {
  let names = profile_names()
  for i = 0; i < names.length(); i = i + 1 {
    if check_budget(archive, budget_by_profile(names[i])).passed {
      return names[i]
    }
  }
  "none"
}
