///|
/// Normalized waterfall row for renderers.
pub(all) struct WaterfallRow {
  index : Int
  url : String
  domain : String
  method : String
  status : Int
  kind : String
  start_offset : Int
  duration : Int
  blocked : Int
  dns : Int
  connect : Int
  ssl : Int
  send : Int
  wait : Int
  receive : Int
  bytes : Int
} derive(Eq, Show)

///|
pub fn build_waterfall(archive : HarArchive) -> Array[WaterfallRow] {
  let rows : Array[WaterfallRow] = []
  let mut offset = 0
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let entry = archive.log.entries[i]
    rows.push(WaterfallRow::{
      index: i,
      url: entry.request.url,
      domain: extract_domain(entry.request.url),
      method: entry.request.method,
      status: entry.response.status,
      kind: resource_kind(entry.response.content.mime_type, entry.request.url),
      start_offset: offset,
      duration: entry.time,
      blocked: phase(entry.timings.blocked),
      dns: phase(entry.timings.dns),
      connect: phase(entry.timings.connect),
      ssl: phase(entry.timings.ssl),
      send: phase(entry.timings.send),
      wait: phase(entry.timings.wait),
      receive: phase(entry.timings.receive),
      bytes: entry_bytes(entry),
    })
    offset = offset + entry.time
  }
  rows
}

///|
fn phase(value : Int) -> Int {
  if value < 0 { 0 } else { value }
}

///|
pub fn waterfall_total_duration(rows : Array[WaterfallRow]) -> Int {
  let mut total = 0
  for i = 0; i < rows.length(); i = i + 1 {
    let end = rows[i].start_offset + rows[i].duration
    if end > total {
      total = end
    }
  }
  total
}

///|
pub fn render_waterfall_table(rows : Array[WaterfallRow]) -> String {
  let mut out = "idx method status ms kind domain url\n"
  for i = 0; i < rows.length(); i = i + 1 {
    let row = rows[i]
    out = out + row.index.to_string() + " "
    out = out + row.method + " "
    out = out + row.status.to_string() + " "
    out = out + row.duration.to_string() + " "
    out = out + row.kind + " "
    out = out + row.domain + " "
    out = out + row.url + "\n"
  }
  out
}

///|
pub fn rows_for_domain(rows : Array[WaterfallRow], domain : String) -> Array[WaterfallRow] {
  let out : Array[WaterfallRow] = []
  for i = 0; i < rows.length(); i = i + 1 {
    if rows[i].domain == domain {
      out.push(rows[i])
    }
  }
  out
}

///|
pub fn rows_for_kind(rows : Array[WaterfallRow], kind : String) -> Array[WaterfallRow] {
  let out : Array[WaterfallRow] = []
  for i = 0; i < rows.length(); i = i + 1 {
    if rows[i].kind == kind {
      out.push(rows[i])
    }
  }
  out
}

///|
pub fn rows_after(rows : Array[WaterfallRow], offset : Int) -> Array[WaterfallRow] {
  let out : Array[WaterfallRow] = []
  for i = 0; i < rows.length(); i = i + 1 {
    if rows[i].start_offset >= offset {
      out.push(rows[i])
    }
  }
  out
}

///|
pub fn row_wait_ratio(row : WaterfallRow) -> Int {
  if row.duration <= 0 {
    0
  } else {
    row.wait * 100 / row.duration
  }
}

///|
pub fn row_receive_ratio(row : WaterfallRow) -> Int {
  if row.duration <= 0 {
    0
  } else {
    row.receive * 100 / row.duration
  }
}
