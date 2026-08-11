///|
pub(all) struct ReadinessItem {
  name : String
  passed : Bool
  detail : String
} derive(Eq, Show)

///|
pub fn readiness_check(archive : HarArchive) -> Array[ReadinessItem] {
  let summary = analyze_archive(archive)
  let diagnostics = validate_archive(archive)
  [
    ReadinessItem::{
      name: "has entries",
      passed: summary.entry_count > 0,
      detail: summary.entry_count.to_string() + " entries",
    },
    ReadinessItem::{
      name: "has creator",
      passed: archive.log.creator_name != "",
      detail: archive.log.creator_name,
    },
    ReadinessItem::{
      name: "no validation errors",
      passed: diagnostics.count_if(d => d.severity == Error) == 0,
      detail: diagnostics.length().to_string() + " findings",
    },
    ReadinessItem::{
      name: "no failed requests",
      passed: summary.failed_count == 0,
      detail: summary.failed_count.to_string() + " failed",
    },
    ReadinessItem::{
      name: "has resource classification",
      passed: summary.resources.length() > 0,
      detail: summary.resources.length().to_string() + " groups",
    },
  ]
}

///|
pub fn readiness_passed(items : Array[ReadinessItem]) -> Bool {
  items.all(item => item.passed)
}

///|
pub fn render_readiness(items : Array[ReadinessItem]) -> String {
  let mut out = ""
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    let mark = if item.passed { "[x] " } else { "[ ] " }
    out = out + mark + item.name + " - " + item.detail + "\n"
  }
  out
}

///|
pub fn failed_readiness_items(items : Array[ReadinessItem]) -> Array[ReadinessItem] {
  let out : Array[ReadinessItem] = []
  for i = 0; i < items.length(); i = i + 1 {
    if !items[i].passed {
      out.push(items[i])
    }
  }
  out
}

///|
pub fn readiness_summary(archive : HarArchive) -> String {
  let items = readiness_check(archive)
  if readiness_passed(items) {
    "ready\n" + render_readiness(items)
  } else {
    "not ready\n" + render_readiness(items)
  }
}
