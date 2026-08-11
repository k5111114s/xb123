///|
pub(all) struct Insight {
  title : String
  severity : Severity
  detail : String
} derive(Eq, Show)

///|
pub fn generate_insights(archive : HarArchive) -> Array[Insight] {
  let summary = analyze_archive(archive)
  let out : Array[Insight] = []
  add_failure_insight(summary, out)
  add_redirect_insight(summary, out)
  add_size_insight(summary, out)
  add_latency_insight(summary, out)
  add_domain_insight(summary, out)
  add_resource_insight(summary, out)
  if out.is_empty() {
    out.push(Insight::{
      title: "No major issues detected",
      severity: Info,
      detail: "The archive is small, successful, and within default latency thresholds.",
    })
  }
  out
}

///|
fn add_failure_insight(summary : HarSummary, out : Array[Insight]) -> Unit {
  if summary.failed_count > 0 {
    out.push(Insight::{
      title: "Failed requests detected",
      severity: Error,
      detail: summary.failed_count.to_string() + " requests returned 4xx or 5xx responses.",
    })
  }
}

///|
fn add_redirect_insight(summary : HarSummary, out : Array[Insight]) -> Unit {
  if summary.redirected_count > 3 {
    out.push(Insight::{
      title: "Redirect count is high",
      severity: Warning,
      detail: summary.redirected_count.to_string() + " redirects may add avoidable latency.",
    })
  }
}

///|
fn add_size_insight(summary : HarSummary, out : Array[Insight]) -> Unit {
  if summary.total_bytes > 5_000_000 {
    out.push(Insight::{
      title: "Transfer size is large",
      severity: Warning,
      detail: "Total transferred bytes are " + summary.total_bytes.to_string() + ".",
    })
  }
}

///|
fn add_latency_insight(summary : HarSummary, out : Array[Insight]) -> Unit {
  if summary.average_time > 500 {
    out.push(Insight::{
      title: "Average latency is high",
      severity: Warning,
      detail: "Average request time is " + summary.average_time.to_string() + "ms.",
    })
  }
  if summary.longest_time > 2000 {
    out.push(Insight::{
      title: "Slow outlier request",
      severity: Warning,
      detail: "The slowest request took " + summary.longest_time.to_string() + "ms.",
    })
  }
}

///|
fn add_domain_insight(summary : HarSummary, out : Array[Insight]) -> Unit {
  if summary.domains.length() > 8 {
    out.push(Insight::{
      title: "Many network domains",
      severity: Info,
      detail: summary.domains.length().to_string() + " domains were contacted.",
    })
  }
}

///|
fn add_resource_insight(summary : HarSummary, out : Array[Insight]) -> Unit {
  for i = 0; i < summary.resources.length(); i = i + 1 {
    let r = summary.resources[i]
    if r.kind == "image" && r.bytes > 2_000_000 {
      out.push(Insight::{
        title: "Large image payload",
        severity: Warning,
        detail: "Images transferred " + r.bytes.to_string() + " bytes.",
      })
    }
  }
}

///|
pub fn render_insights(insights : Array[Insight]) -> String {
  let mut out = ""
  for i = 0; i < insights.length(); i = i + 1 {
    let item = insights[i]
    out = out + severity_text(item.severity) + " " + item.title + " - " + item.detail + "\n"
  }
  out
}

///|
pub fn insight_count_by_severity(insights : Array[Insight], severity : Severity) -> Int {
  insights.count_if(i => i.severity == severity)
}
