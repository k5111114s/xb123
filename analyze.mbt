///|
/// Domain aggregate.
pub(all) struct DomainStat {
  domain : String
  count : Int
  bytes : Int
  failures : Int
} derive(Eq, Show)

///|
/// Status-code aggregate.
pub(all) struct StatusStat {
  group : String
  count : Int
} derive(Eq, Show)

///|
/// Resource-type aggregate.
pub(all) struct ResourceStat {
  kind : String
  count : Int
  bytes : Int
} derive(Eq, Show)

///|
/// Slow request projection.
pub(all) struct SlowEntry {
  url : String
  method : String
  status : Int
  time : Int
  wait : Int
  receive : Int
} derive(Eq, Show)

///|
/// Main summary returned by the analyzer.
pub(all) struct HarSummary {
  entry_count : Int
  page_count : Int
  failed_count : Int
  redirected_count : Int
  cached_count : Int
  total_bytes : Int
  total_time : Int
  longest_time : Int
  average_time : Int
  domains : Array[DomainStat]
  statuses : Array[StatusStat]
  resources : Array[ResourceStat]
  slow_entries : Array[SlowEntry]
} derive(Eq, Show)

///|
pub fn analyze_archive(archive : HarArchive) -> HarSummary {
  let domains : Array[DomainStat] = []
  let statuses : Array[StatusStat] = []
  let resources : Array[ResourceStat] = []
  let slow : Array[SlowEntry] = []
  let mut failed_count = 0
  let mut redirected_count = 0
  let mut cached_count = 0
  let mut total_bytes = 0
  let mut total_time = 0
  let mut longest_time = 0
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let entry = archive.log.entries[i]
    let bytes = entry_bytes(entry)
    total_bytes = total_bytes + bytes
    total_time = total_time + entry.time
    if entry.time > longest_time {
      longest_time = entry.time
    }
    if entry.response.status >= 400 {
      failed_count = failed_count + 1
    }
    if entry.response.status >= 300 && entry.response.status < 400 {
      redirected_count = redirected_count + 1
    }
    if entry.response.status == 304 || (entry.response.body_size == 0 && entry.response.content.size == 0) {
      cached_count = cached_count + 1
    }
    bump_domain(domains, extract_domain(entry.request.url), bytes, entry.response.status >= 400)
    bump_status(statuses, status_group(entry.response.status))
    bump_resource(resources, resource_kind(entry.response.content.mime_type, entry.request.url), bytes)
    insert_slow(slow, SlowEntry::{
      url: entry.request.url,
      method: entry.request.method,
      status: entry.response.status,
      time: entry.time,
      wait: entry.timings.wait,
      receive: entry.timings.receive,
    }, 10)
  }
  HarSummary::{
    entry_count: archive.log.entries.length(),
    page_count: archive.log.pages.length(),
    failed_count,
    redirected_count,
    cached_count,
    total_bytes,
    total_time,
    longest_time,
    average_time: if archive.log.entries.length() == 0 { 0 } else { total_time / archive.log.entries.length() },
    domains,
    statuses,
    resources,
    slow_entries: slow,
  }
}

///|
pub fn entry_bytes(entry : HarEntry) -> Int {
  known_size(entry.request.headers_size) + known_size(entry.request.body_size) +
  known_size(entry.response.headers_size) + known_size(entry.response.body_size) +
  entry.response.content.size
}

///|
fn known_size(value : Int) -> Int {
  if value > 0 { value } else { 0 }
}

///|
pub fn extract_domain(url : String) -> String {
  let no_scheme = match url.split_once("://") {
    Some((_, rest)) => rest.to_string()
    None => url
  }
  let host = match no_scheme.split_once("/") {
    Some((left, _)) => left.to_string()
    None => no_scheme
  }
  match host.split_once(":") {
    Some((left, _)) => left.to_string()
    None => host
  }
}

///|
pub fn status_group(status : Int) -> String {
  if status < 100 { "other" } else if status < 200 { "1xx" } else if status < 300 { "2xx" } else if status < 400 { "3xx" } else if status < 500 { "4xx" } else if status < 600 { "5xx" } else { "other" }
}

///|
pub fn resource_kind(mime : String, url : String) -> String {
  let lower = mime.to_lower()
  if lower.contains("html") {
    "document"
  } else if lower.contains("javascript") || lower.contains("ecmascript") || url.has_suffix(".js") {
    "script"
  } else if lower.contains("css") || url.has_suffix(".css") {
    "style"
  } else if lower.contains("image") || url.has_suffix(".png") || url.has_suffix(".jpg") || url.has_suffix(".jpeg") || url.has_suffix(".webp") || url.has_suffix(".gif") {
    "image"
  } else if lower.contains("json") {
    "json"
  } else if lower.contains("font") || url.has_suffix(".woff") || url.has_suffix(".woff2") {
    "font"
  } else if lower.contains("video") {
    "video"
  } else if lower.contains("audio") {
    "audio"
  } else {
    "other"
  }
}

///|
fn bump_domain(stats : Array[DomainStat], domain : String, bytes : Int, failed : Bool) -> Unit {
  for i = 0; i < stats.length(); i = i + 1 {
    if stats[i].domain == domain {
      let fail_add = if failed { 1 } else { 0 }
      stats[i] = DomainStat::{
        domain,
        count: stats[i].count + 1,
        bytes: stats[i].bytes + bytes,
        failures: stats[i].failures + fail_add,
      }
      return
    }
  }
  let fail_add = if failed { 1 } else { 0 }
  stats.push(DomainStat::{ domain, count: 1, bytes, failures: fail_add })
}

///|
fn bump_status(stats : Array[StatusStat], group : String) -> Unit {
  for i = 0; i < stats.length(); i = i + 1 {
    if stats[i].group == group {
      stats[i] = StatusStat::{ group, count: stats[i].count + 1 }
      return
    }
  }
  stats.push(StatusStat::{ group, count: 1 })
}

///|
fn bump_resource(stats : Array[ResourceStat], kind : String, bytes : Int) -> Unit {
  for i = 0; i < stats.length(); i = i + 1 {
    if stats[i].kind == kind {
      stats[i] = ResourceStat::{ kind, count: stats[i].count + 1, bytes: stats[i].bytes + bytes }
      return
    }
  }
  stats.push(ResourceStat::{ kind, count: 1, bytes })
}

///|
fn insert_slow(items : Array[SlowEntry], item : SlowEntry, limit : Int) -> Unit {
  let mut inserted = false
  for i = 0; i < items.length(); i = i + 1 {
    if item.time > items[i].time {
      items.insert(i, item)
      inserted = true
      break
    }
  }
  if !inserted {
    items.push(item)
  }
  while items.length() > limit {
    ignore(items.pop())
  }
}

///|
pub fn summary_line(summary : HarSummary) -> String {
  "entries=" + summary.entry_count.to_string() +
  " pages=" + summary.page_count.to_string() +
  " failed=" + summary.failed_count.to_string() +
  " bytes=" + summary.total_bytes.to_string() +
  " avg_ms=" + summary.average_time.to_string()
}
