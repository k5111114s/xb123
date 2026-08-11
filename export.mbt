///|
pub fn export_entries_csv(archive : HarArchive) -> String {
  let mut out = "index,method,status,time,bytes,domain,kind,url\n"
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    out = out + export_entry_csv_row(archive.log.entries[i], i)
  }
  out
}

///|
pub fn export_entry_csv_row(entry : HarEntry, index : Int) -> String {
  index.to_string() + "," +
  csv_cell(entry.request.method) + "," +
  entry.response.status.to_string() + "," +
  entry.time.to_string() + "," +
  entry_bytes(entry).to_string() + "," +
  csv_cell(extract_domain(entry.request.url)) + "," +
  csv_cell(resource_kind(entry.response.content.mime_type, entry.request.url)) + "," +
  csv_cell(entry.request.url) + "\n"
}

///|
pub fn csv_cell(value : String) -> String {
  if value.contains(",") || value.contains("\"") || value.contains("\n") {
    "\"" + value.replace_all(old="\"", new="\"\"") + "\""
  } else {
    value
  }
}

///|
pub fn export_domains_csv(summary : HarSummary) -> String {
  let mut out = "domain,count,bytes,failures\n"
  for i = 0; i < summary.domains.length(); i = i + 1 {
    let d = summary.domains[i]
    out = out + csv_cell(d.domain) + "," + d.count.to_string() + "," + d.bytes.to_string() + "," + d.failures.to_string() + "\n"
  }
  out
}

///|
pub fn export_resources_csv(summary : HarSummary) -> String {
  let mut out = "kind,count,bytes\n"
  for i = 0; i < summary.resources.length(); i = i + 1 {
    let r = summary.resources[i]
    out = out + csv_cell(r.kind) + "," + r.count.to_string() + "," + r.bytes.to_string() + "\n"
  }
  out
}

///|
pub fn export_statuses_csv(summary : HarSummary) -> String {
  let mut out = "group,count\n"
  for i = 0; i < summary.statuses.length(); i = i + 1 {
    let s = summary.statuses[i]
    out = out + csv_cell(s.group) + "," + s.count.to_string() + "\n"
  }
  out
}

///|
pub fn export_slow_csv(summary : HarSummary) -> String {
  let mut out = "method,status,time,wait,receive,url\n"
  for i = 0; i < summary.slow_entries.length(); i = i + 1 {
    let s = summary.slow_entries[i]
    out = out + csv_cell(s.method) + "," + s.status.to_string() + "," + s.time.to_string() + "," + s.wait.to_string() + "," + s.receive.to_string() + "," + csv_cell(s.url) + "\n"
  }
  out
}

///|
pub fn export_waterfall_json(rows : Array[WaterfallRow]) -> String {
  let mut out = "["
  for i = 0; i < rows.length(); i = i + 1 {
    if i > 0 {
      out = out + ","
    }
    out = out + export_waterfall_row_json(rows[i])
  }
  out + "]"
}

///|
pub fn export_waterfall_row_json(row : WaterfallRow) -> String {
  "{" +
  "\"index\":" + row.index.to_string() + "," +
  "\"method\":\"" + escape_json(row.method) + "\"," +
  "\"status\":" + row.status.to_string() + "," +
  "\"duration\":" + row.duration.to_string() + "," +
  "\"startOffset\":" + row.start_offset.to_string() + "," +
  "\"domain\":\"" + escape_json(row.domain) + "\"," +
  "\"kind\":\"" + escape_json(row.kind) + "\"," +
  "\"url\":\"" + escape_json(row.url) + "\"" +
  "}"
}

///|
pub fn export_diagnostics_json(diags : Array[Diagnostic]) -> String {
  let mut out = "["
  for i = 0; i < diags.length(); i = i + 1 {
    if i > 0 {
      out = out + ","
    }
    let d = diags[i]
    out = out + "{"
    out = out + "\"severity\":\"" + escape_json(severity_text(d.severity)) + "\","
    out = out + "\"code\":\"" + escape_json(d.code) + "\","
    out = out + "\"path\":\"" + escape_json(d.path) + "\","
    out = out + "\"message\":\"" + escape_json(d.message) + "\""
    out = out + "}"
  }
  out + "]"
}

///|
pub fn export_full_report_json(archive : HarArchive) -> String {
  let summary = analyze_archive(archive)
  let diagnostics = validate_archive(archive)
  let rows = build_waterfall(archive)
  "{" +
  "\"summary\":" + render_summary_json(summary) + "," +
  "\"diagnostics\":" + export_diagnostics_json(diagnostics) + "," +
  "\"waterfall\":" + export_waterfall_json(rows) +
  "}"
}
