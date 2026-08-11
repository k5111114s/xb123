///|
/// Difference between two HAR summaries.
pub(all) struct SummaryDiff {
  entry_delta : Int
  failed_delta : Int
  bytes_delta : Int
  total_time_delta : Int
  average_time_delta : Int
  longest_time_delta : Int
} derive(Eq, Show)

///|
pub fn compare_archives(before : HarArchive, after : HarArchive) -> SummaryDiff {
  compare_summaries(analyze_archive(before), analyze_archive(after))
}

///|
pub fn compare_summaries(before : HarSummary, after : HarSummary) -> SummaryDiff {
  SummaryDiff::{
    entry_delta: after.entry_count - before.entry_count,
    failed_delta: after.failed_count - before.failed_count,
    bytes_delta: after.total_bytes - before.total_bytes,
    total_time_delta: after.total_time - before.total_time,
    average_time_delta: after.average_time - before.average_time,
    longest_time_delta: after.longest_time - before.longest_time,
  }
}

///|
pub fn diff_is_regression(diff : SummaryDiff) -> Bool {
  diff.failed_delta > 0 ||
  diff.bytes_delta > 100_000 ||
  diff.average_time_delta > 100 ||
  diff.longest_time_delta > 500
}

///|
pub fn render_diff(diff : SummaryDiff) -> String {
  let mut out = "MoonHAR diff\n"
  out = out + "entries: " + signed(diff.entry_delta) + "\n"
  out = out + "failed: " + signed(diff.failed_delta) + "\n"
  out = out + "bytes: " + signed(diff.bytes_delta) + "\n"
  out = out + "total_ms: " + signed(diff.total_time_delta) + "\n"
  out = out + "avg_ms: " + signed(diff.average_time_delta) + "\n"
  out = out + "longest_ms: " + signed(diff.longest_time_delta) + "\n"
  out
}

///|
fn signed(value : Int) -> String {
  if value >= 0 {
    "+" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
pub fn domain_delta(before : HarSummary, after : HarSummary, domain : String) -> Int {
  domain_count(after, domain) - domain_count(before, domain)
}

///|
pub fn domain_count(summary : HarSummary, domain : String) -> Int {
  for i = 0; i < summary.domains.length(); i = i + 1 {
    if summary.domains[i].domain == domain {
      return summary.domains[i].count
    }
  }
  0
}

///|
pub fn resource_delta(before : HarSummary, after : HarSummary, kind : String) -> Int {
  resource_count(after, kind) - resource_count(before, kind)
}

///|
pub fn resource_count(summary : HarSummary, kind : String) -> Int {
  for i = 0; i < summary.resources.length(); i = i + 1 {
    if summary.resources[i].kind == kind {
      return summary.resources[i].count
    }
  }
  0
}
