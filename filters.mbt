///|
/// Request filter used by query helpers.
pub(all) struct EntryFilter {
  domain : String?
  method : String?
  status_min : Int?
  status_max : Int?
  resource : String?
  slow_ms : Int?
  url_contains : String?
  failed_only : Bool
} derive(Eq, Show)

///|
pub fn EntryFilter::new() -> EntryFilter {
  EntryFilter::{
    domain: None,
    method: None,
    status_min: None,
    status_max: None,
    resource: None,
    slow_ms: None,
    url_contains: None,
    failed_only: false,
  }
}

///|
pub fn EntryFilter::for_domain(domain : String) -> EntryFilter {
  let f = EntryFilter::new()
  EntryFilter::{ ..f, domain: Some(domain) }
}

///|
pub fn EntryFilter::for_method(method : String) -> EntryFilter {
  let f = EntryFilter::new()
  EntryFilter::{ ..f, method: Some(method) }
}

///|
pub fn EntryFilter::for_resource(kind : String) -> EntryFilter {
  let f = EntryFilter::new()
  EntryFilter::{ ..f, resource: Some(kind) }
}

///|
pub fn EntryFilter::slow(ms : Int) -> EntryFilter {
  let f = EntryFilter::new()
  EntryFilter::{ ..f, slow_ms: Some(ms) }
}

///|
pub fn EntryFilter::failed() -> EntryFilter {
  let f = EntryFilter::new()
  EntryFilter::{ ..f, failed_only: true }
}

///|
pub fn filter_entries(archive : HarArchive, filter : EntryFilter) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let entry = archive.log.entries[i]
    if entry_matches(entry, filter) {
      out.push(entry)
    }
  }
  out
}

///|
pub fn entry_matches(entry : HarEntry, filter : EntryFilter) -> Bool {
  if filter.failed_only && entry.response.status < 400 {
    return false
  }
  match filter.domain {
    Some(domain) =>
      if extract_domain(entry.request.url) != domain {
        return false
      }
    None => ()
  }
  match filter.method {
    Some(method) =>
      if entry.request.method != method {
        return false
      }
    None => ()
  }
  match filter.status_min {
    Some(min) =>
      if entry.response.status < min {
        return false
      }
    None => ()
  }
  match filter.status_max {
    Some(max) =>
      if entry.response.status > max {
        return false
      }
    None => ()
  }
  match filter.resource {
    Some(kind) =>
      if resource_kind(entry.response.content.mime_type, entry.request.url) != kind {
        return false
      }
    None => ()
  }
  match filter.slow_ms {
    Some(ms) =>
      if entry.time < ms {
        return false
      }
    None => ()
  }
  match filter.url_contains {
    Some(part) =>
      if !entry.request.url.contains(part) {
        return false
      }
    None => ()
  }
  true
}

///|
pub fn count_failed(entries : Array[HarEntry]) -> Int {
  entries.count_if(e => e.response.status >= 400)
}

///|
pub fn count_redirects(entries : Array[HarEntry]) -> Int {
  entries.count_if(e => e.response.status >= 300 && e.response.status < 400)
}

///|
pub fn count_method(entries : Array[HarEntry], method : String) -> Int {
  entries.count_if(e => e.request.method == method)
}

///|
pub fn count_resource(entries : Array[HarEntry], kind : String) -> Int {
  entries.count_if(e => resource_kind(e.response.content.mime_type, e.request.url) == kind)
}

///|
pub fn total_entry_time(entries : Array[HarEntry]) -> Int {
  let mut total = 0
  for i = 0; i < entries.length(); i = i + 1 {
    total = total + entries[i].time
  }
  total
}

///|
pub fn total_entry_bytes(entries : Array[HarEntry]) -> Int {
  let mut total = 0
  for i = 0; i < entries.length(); i = i + 1 {
    total = total + entry_bytes(entries[i])
  }
  total
}

///|
pub fn fastest_entry(entries : Array[HarEntry]) -> HarEntry? {
  if entries.is_empty() {
    return None
  }
  let mut best = entries[0]
  for i = 1; i < entries.length(); i = i + 1 {
    if entries[i].time < best.time {
      best = entries[i]
    }
  }
  Some(best)
}

///|
pub fn slowest_entry(entries : Array[HarEntry]) -> HarEntry? {
  if entries.is_empty() {
    return None
  }
  let mut best = entries[0]
  for i = 1; i < entries.length(); i = i + 1 {
    if entries[i].time > best.time {
      best = entries[i]
    }
  }
  Some(best)
}

///|
pub fn entries_over_time(entries : Array[HarEntry], ms : Int) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < entries.length(); i = i + 1 {
    if entries[i].time >= ms {
      out.push(entries[i])
    }
  }
  out
}

///|
pub fn entries_for_status_group(entries : Array[HarEntry], group : String) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < entries.length(); i = i + 1 {
    if status_group(entries[i].response.status) == group {
      out.push(entries[i])
    }
  }
  out
}

///|
pub fn entries_for_domain(entries : Array[HarEntry], domain : String) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < entries.length(); i = i + 1 {
    if extract_domain(entries[i].request.url) == domain {
      out.push(entries[i])
    }
  }
  out
}

///|
pub fn entries_with_header(entries : Array[HarEntry], name : String) -> Array[HarEntry] {
  let lower = name.to_lower()
  let out : Array[HarEntry] = []
  for i = 0; i < entries.length(); i = i + 1 {
    if has_header(entries[i], lower) {
      out.push(entries[i])
    }
  }
  out
}

///|
fn has_header(entry : HarEntry, lower : String) -> Bool {
  entry.request.headers.any(h => h.name.to_lower() == lower) ||
  entry.response.headers.any(h => h.name.to_lower() == lower)
}
