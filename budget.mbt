///|
/// Performance budget configuration.
pub(all) struct HarBudget {
  max_entries : Int
  max_total_bytes : Int
  max_total_time : Int
  max_average_time : Int
  max_failed : Int
  max_redirects : Int
  max_slowest_time : Int
} derive(Eq, Show)

///|
pub(all) struct BudgetResult {
  passed : Bool
  diagnostics : Array[Diagnostic]
} derive(Eq, Show)

///|
pub fn HarBudget::default() -> HarBudget {
  HarBudget::{
    max_entries: 200,
    max_total_bytes: 5_000_000,
    max_total_time: 30_000,
    max_average_time: 500,
    max_failed: 0,
    max_redirects: 10,
    max_slowest_time: 2000,
  }
}

///|
pub fn HarBudget::strict() -> HarBudget {
  HarBudget::{
    max_entries: 80,
    max_total_bytes: 1_000_000,
    max_total_time: 10_000,
    max_average_time: 250,
    max_failed: 0,
    max_redirects: 2,
    max_slowest_time: 1000,
  }
}

///|
pub fn check_budget(archive : HarArchive, budget : HarBudget) -> BudgetResult {
  let summary = analyze_archive(archive)
  let diagnostics : Array[Diagnostic] = []
  budget_check(summary.entry_count, budget.max_entries, "$.log.entries", "budget.entries", "entry count exceeds budget", diagnostics)
  budget_check(summary.total_bytes, budget.max_total_bytes, "$.log.entries", "budget.bytes", "total bytes exceed budget", diagnostics)
  budget_check(summary.total_time, budget.max_total_time, "$.log.entries", "budget.totalTime", "total time exceeds budget", diagnostics)
  budget_check(summary.average_time, budget.max_average_time, "$.log.entries", "budget.averageTime", "average request time exceeds budget", diagnostics)
  budget_check(summary.failed_count, budget.max_failed, "$.log.entries", "budget.failed", "failed request count exceeds budget", diagnostics)
  budget_check(summary.redirected_count, budget.max_redirects, "$.log.entries", "budget.redirects", "redirect count exceeds budget", diagnostics)
  budget_check(summary.longest_time, budget.max_slowest_time, "$.log.entries", "budget.slowest", "slowest request exceeds budget", diagnostics)
  BudgetResult::{ passed: diagnostics.is_empty(), diagnostics }
}

///|
fn budget_check(value : Int, limit : Int, path : String, code : String, message : String, out : Array[Diagnostic]) -> Unit {
  if value > limit {
    out.push(Diagnostic::{
      severity: Error,
      code,
      path,
      message: message + ": " + value.to_string() + " > " + limit.to_string(),
    })
  }
}

///|
pub fn render_budget_result(result : BudgetResult) -> String {
  if result.passed {
    "Performance budget passed.\n"
  } else {
    "Performance budget failed.\n" + render_diagnostics(result.diagnostics)
  }
}

///|
pub fn budget_score(archive : HarArchive, budget : HarBudget) -> Int {
  let summary = analyze_archive(archive)
  let mut score = 100
  score = score - penalty(summary.entry_count, budget.max_entries, 10)
  score = score - penalty(summary.total_bytes, budget.max_total_bytes, 20)
  score = score - penalty(summary.average_time, budget.max_average_time, 20)
  score = score - penalty(summary.failed_count, budget.max_failed, 30)
  score = score - penalty(summary.redirected_count, budget.max_redirects, 5)
  score = score - penalty(summary.longest_time, budget.max_slowest_time, 15)
  if score < 0 { 0 } else { score }
}

///|
fn penalty(value : Int, limit : Int, weight : Int) -> Int {
  if value <= limit {
    0
  } else if limit <= 0 {
    weight
  } else {
    let over = value - limit
    let scaled = over * weight / limit
    if scaled > weight { weight } else { scaled }
  }
}
