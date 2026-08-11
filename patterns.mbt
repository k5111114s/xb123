///|
pub(all) struct UrlPattern {
  pattern : String
  count : Int
  total_time : Int
  total_bytes : Int
} derive(Eq, Show)

///|
pub fn url_pattern(url : String) -> String {
  let path = url_path(url)
  let parts = path.split("/").collect()
  let mut out = ""
  for i = 0; i < parts.length(); i = i + 1 {
    if i > 0 {
      out = out + "/"
    }
    let part = parts[i].to_owned()
    if part == "" {
      out = out + part
    } else if looks_numeric(part) {
      out = out + ":int"
    } else if looks_uuidish(part) {
      out = out + ":id"
    } else {
      out = out + part
    }
  }
  if out == "" { "/" } else { out }
}

///|
fn looks_numeric(text : String) -> Bool {
  text.length() > 0 && text.all(ch => ch >= '0' && ch <= '9')
}

///|
fn looks_uuidish(text : String) -> Bool {
  text.length() >= 16 && text.contains("-")
}

///|
pub fn collect_url_patterns(archive : HarArchive) -> Array[UrlPattern] {
  let out : Array[UrlPattern] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let entry = archive.log.entries[i]
    bump_pattern(out, url_pattern(entry.request.url), entry.time, entry_bytes(entry))
  }
  out
}

///|
fn bump_pattern(out : Array[UrlPattern], pattern : String, time : Int, bytes : Int) -> Unit {
  for i = 0; i < out.length(); i = i + 1 {
    if out[i].pattern == pattern {
      out[i] = UrlPattern::{
        pattern,
        count: out[i].count + 1,
        total_time: out[i].total_time + time,
        total_bytes: out[i].total_bytes + bytes,
      }
      return
    }
  }
  out.push(UrlPattern::{ pattern, count: 1, total_time: time, total_bytes: bytes })
}

///|
pub fn render_url_patterns(patterns : Array[UrlPattern]) -> String {
  let mut out = ""
  for i = 0; i < patterns.length(); i = i + 1 {
    let p = patterns[i]
    out = out + p.pattern + " count=" + p.count.to_string() + " total_ms=" + p.total_time.to_string() + " bytes=" + p.total_bytes.to_string() + "\n"
  }
  out
}

///|
pub fn hottest_pattern(patterns : Array[UrlPattern]) -> UrlPattern? {
  if patterns.is_empty() {
    return None
  }
  let mut best = patterns[0]
  for i = 1; i < patterns.length(); i = i + 1 {
    if patterns[i].total_time > best.total_time {
      best = patterns[i]
    }
  }
  Some(best)
}

///|
pub fn heaviest_pattern(patterns : Array[UrlPattern]) -> UrlPattern? {
  if patterns.is_empty() {
    return None
  }
  let mut best = patterns[0]
  for i = 1; i < patterns.length(); i = i + 1 {
    if patterns[i].total_bytes > best.total_bytes {
      best = patterns[i]
    }
  }
  Some(best)
}
