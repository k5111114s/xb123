///|
/// Render validation diagnostics as newline separated text.
pub fn render_diagnostics(diags : Array[Diagnostic]) -> String {
  if diags.is_empty() {
    return "No validation findings.\n"
  }
  let mut out = ""
  for i = 0; i < diags.length(); i = i + 1 {
    let d = diags[i]
    out = out + severity_text(d.severity) + " " + d.code + " " + d.path + " - " + d.message + "\n"
  }
  out
}

///|
pub fn severity_text(severity : Severity) -> String {
  match severity {
    Info => "INFO"
    Warning => "WARN"
    Error => "ERROR"
  }
}

///|
/// Render a compact human readable summary.
pub fn render_summary(summary : HarSummary) -> String {
  let mut out = ""
  out = out + "MoonHAR summary\n"
  out = out + "entries: " + summary.entry_count.to_string() + "\n"
  out = out + "pages: " + summary.page_count.to_string() + "\n"
  out = out + "failed: " + summary.failed_count.to_string() + "\n"
  out = out + "redirected: " + summary.redirected_count.to_string() + "\n"
  out = out + "cached: " + summary.cached_count.to_string() + "\n"
  out = out + "bytes: " + summary.total_bytes.to_string() + "\n"
  out = out + "total_ms: " + summary.total_time.to_string() + "\n"
  out = out + "avg_ms: " + summary.average_time.to_string() + "\n"
  out = out + "longest_ms: " + summary.longest_time.to_string() + "\n"
  out = out + "\nDomains\n"
  for i = 0; i < summary.domains.length(); i = i + 1 {
    let d = summary.domains[i]
    out = out + "- " + d.domain + ": count=" + d.count.to_string() + " bytes=" + d.bytes.to_string() + " failures=" + d.failures.to_string() + "\n"
  }
  out = out + "\nStatus groups\n"
  for i = 0; i < summary.statuses.length(); i = i + 1 {
    let s = summary.statuses[i]
    out = out + "- " + s.group + ": " + s.count.to_string() + "\n"
  }
  out = out + "\nResources\n"
  for i = 0; i < summary.resources.length(); i = i + 1 {
    let r = summary.resources[i]
    out = out + "- " + r.kind + ": count=" + r.count.to_string() + " bytes=" + r.bytes.to_string() + "\n"
  }
  out = out + "\nSlow entries\n"
  for i = 0; i < summary.slow_entries.length(); i = i + 1 {
    let e = summary.slow_entries[i]
    out = out + "- " + e.time.to_string() + "ms " + e.method + " " + e.url + " status=" + e.status.to_string() + "\n"
  }
  out
}

///|
/// Render a compact JSON-like report without depending on a JSON encoder.
pub fn render_summary_json(summary : HarSummary) -> String {
  let mut out = "{"
  out = out + "\"entryCount\":" + summary.entry_count.to_string() + ","
  out = out + "\"pageCount\":" + summary.page_count.to_string() + ","
  out = out + "\"failedCount\":" + summary.failed_count.to_string() + ","
  out = out + "\"redirectedCount\":" + summary.redirected_count.to_string() + ","
  out = out + "\"cachedCount\":" + summary.cached_count.to_string() + ","
  out = out + "\"totalBytes\":" + summary.total_bytes.to_string() + ","
  out = out + "\"averageTime\":" + summary.average_time.to_string() + ","
  out = out + "\"domains\":["
  for i = 0; i < summary.domains.length(); i = i + 1 {
    if i > 0 { out = out + "," }
    let d = summary.domains[i]
    out = out + "{\"domain\":\"" + escape_json(d.domain) + "\",\"count\":" + d.count.to_string() + ",\"bytes\":" + d.bytes.to_string() + ",\"failures\":" + d.failures.to_string() + "}"
  }
  out = out + "],\"resources\":["
  for i = 0; i < summary.resources.length(); i = i + 1 {
    if i > 0 { out = out + "," }
    let r = summary.resources[i]
    out = out + "{\"kind\":\"" + escape_json(r.kind) + "\",\"count\":" + r.count.to_string() + ",\"bytes\":" + r.bytes.to_string() + "}"
  }
  out = out + "]}"
  out
}

///|
pub fn escape_json(text : String) -> String {
  let mut out = ""
  for i = 0; i < text.length(); i = i + 1 {
    match text.get_char(i) {
      Some('"') => out = out + "\\\""
      Some('\\') => out = out + "\\\\"
      Some('\n') => out = out + "\\n"
      Some('\r') => out = out + "\\r"
      Some('\t') => out = out + "\\t"
      Some(ch) => out = out + ch.to_string()
      None => ()
    }
  }
  out
}
