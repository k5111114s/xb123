///|
/// Diagnostic severity for validation findings.
pub(all) enum Severity {
  Info
  Warning
  Error
} derive(Eq, Show)

///|
/// Validation diagnostic.
pub(all) struct Diagnostic {
  severity : Severity
  code : String
  path : String
  message : String
} derive(Eq, Show)

///|
/// Validate an archive and return all findings.
pub fn validate_archive(archive : HarArchive) -> Array[Diagnostic] {
  let out : Array[Diagnostic] = []
  validate_log(archive.log, out)
  for i = 0; i < archive.log.pages.length(); i = i + 1 {
    validate_page(archive.log.pages[i], i, out)
  }
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    validate_entry(archive.log.entries[i], i, out)
  }
  out
}

///|
pub fn is_valid_archive(archive : HarArchive) -> Bool {
  validate_archive(archive).all(d => d.severity != Error)
}

///|
fn push_diag(out : Array[Diagnostic], severity : Severity, code : String, path : String, message : String) -> Unit {
  out.push(Diagnostic::{ severity, code, path, message })
}

///|
fn validate_log(log : HarLog, out : Array[Diagnostic]) -> Unit {
  if log.version == "" {
    push_diag(out, Error, "har.log.version.missing", "$.log.version", "HAR log version is required")
  }
  if log.version != "" && log.version != "1.1" && log.version != "1.2" {
    push_diag(out, Warning, "har.log.version.unknown", "$.log.version", "HAR version is not a common 1.1/1.2 value")
  }
  if log.creator_name == "" {
    push_diag(out, Warning, "har.creator.name.missing", "$.log.creator.name", "creator name is empty")
  }
  if log.entries.is_empty() {
    push_diag(out, Warning, "har.entries.empty", "$.log.entries", "archive contains no request entries")
  }
}

///|
fn validate_page(page : HarPage, index : Int, out : Array[Diagnostic]) -> Unit {
  let path = "$.log.pages[" + index.to_string() + "]"
  if page.id == "" {
    push_diag(out, Warning, "har.page.id.empty", path + ".id", "page id is empty")
  }
  if page.started_date_time == "" {
    push_diag(out, Warning, "har.page.started.empty", path + ".startedDateTime", "page start time is empty")
  }
  if page.page_timings.on_content_load < -1 {
    push_diag(out, Error, "har.page.timings.content.negative", path + ".pageTimings.onContentLoad", "page timing cannot be below -1")
  }
  if page.page_timings.on_load < -1 {
    push_diag(out, Error, "har.page.timings.load.negative", path + ".pageTimings.onLoad", "page timing cannot be below -1")
  }
  if page.page_timings.on_content_load > page.page_timings.on_load && page.page_timings.on_load >= 0 {
    push_diag(out, Warning, "har.page.timings.order", path + ".pageTimings", "content load happens after page load")
  }
}

///|
fn validate_entry(entry : HarEntry, index : Int, out : Array[Diagnostic]) -> Unit {
  let path = "$.log.entries[" + index.to_string() + "]"
  if entry.started_date_time == "" {
    push_diag(out, Warning, "har.entry.started.empty", path + ".startedDateTime", "entry start time is empty")
  }
  if entry.time < 0 {
    push_diag(out, Error, "har.entry.time.negative", path + ".time", "entry total time cannot be negative")
  }
  validate_request(entry.request, path + ".request", out)
  validate_response(entry.response, path + ".response", out)
  validate_timings(entry, path + ".timings", out)
}

///|
fn validate_request(req : HarRequest, path : String, out : Array[Diagnostic]) -> Unit {
  if req.method == "" {
    push_diag(out, Error, "har.request.method.empty", path + ".method", "request method is required")
  }
  if !is_common_method(req.method) {
    push_diag(out, Warning, "har.request.method.uncommon", path + ".method", "request method is uncommon")
  }
  if req.url == "" {
    push_diag(out, Error, "har.request.url.empty", path + ".url", "request URL is required")
  }
  if req.url != "" && !(req.url.has_prefix("http://") || req.url.has_prefix("https://")) {
    push_diag(out, Warning, "har.request.url.scheme", path + ".url", "request URL is not http or https")
  }
  if req.headers_size < -1 {
    push_diag(out, Error, "har.request.headersSize.range", path + ".headersSize", "headersSize must be -1 or non-negative")
  }
  if req.body_size < -1 {
    push_diag(out, Error, "har.request.bodySize.range", path + ".bodySize", "bodySize must be -1 or non-negative")
  }
  validate_pairs(req.headers, path + ".headers", out)
  validate_pairs(req.query_string, path + ".queryString", out)
  validate_pairs(req.cookies, path + ".cookies", out)
  match req.post_data {
    Some(pd) => validate_post_data(pd, path + ".postData", out)
    None => ()
  }
}

///|
fn validate_response(res : HarResponse, path : String, out : Array[Diagnostic]) -> Unit {
  if res.status < 0 || res.status > 999 {
    push_diag(out, Error, "har.response.status.range", path + ".status", "HTTP status must be between 0 and 999")
  }
  if res.status >= 400 {
    push_diag(out, Warning, "har.response.status.failure", path + ".status", "response status is an HTTP error")
  }
  if res.headers_size < -1 {
    push_diag(out, Error, "har.response.headersSize.range", path + ".headersSize", "headersSize must be -1 or non-negative")
  }
  if res.body_size < -1 {
    push_diag(out, Error, "har.response.bodySize.range", path + ".bodySize", "bodySize must be -1 or non-negative")
  }
  if res.content.size < 0 {
    push_diag(out, Error, "har.response.content.size.range", path + ".content.size", "content size cannot be negative")
  }
  if res.content.mime_type == "" {
    push_diag(out, Info, "har.response.content.mime.empty", path + ".content.mimeType", "content MIME type is empty")
  }
  validate_pairs(res.headers, path + ".headers", out)
  validate_pairs(res.cookies, path + ".cookies", out)
}

///|
fn validate_timings(entry : HarEntry, path : String, out : Array[Diagnostic]) -> Unit {
  validate_phase(entry.timings.blocked, path + ".blocked", out)
  validate_phase(entry.timings.dns, path + ".dns", out)
  validate_phase(entry.timings.connect, path + ".connect", out)
  validate_phase(entry.timings.ssl, path + ".ssl", out)
  validate_phase(entry.timings.send, path + ".send", out)
  validate_phase(entry.timings.wait, path + ".wait", out)
  validate_phase(entry.timings.receive, path + ".receive", out)
  let total = sum_known_timings(entry.timings)
  if entry.time > 0 && total > entry.time * 2 {
    push_diag(out, Warning, "har.timings.sum.large", path, "known timing phases are much larger than entry time")
  }
}

///|
fn validate_phase(value : Int, path : String, out : Array[Diagnostic]) -> Unit {
  if value < -1 {
    push_diag(out, Error, "har.timings.phase.range", path, "timing phase must be -1 or non-negative")
  }
}

///|
fn validate_pairs(values : Array[HarPair], path : String, out : Array[Diagnostic]) -> Unit {
  for i = 0; i < values.length(); i = i + 1 {
    let item = values[i]
    let item_path = path + "[" + i.to_string() + "]"
    if item.name == "" {
      push_diag(out, Warning, "har.pair.name.empty", item_path + ".name", "name is empty")
    }
  }
}

///|
fn validate_post_data(pd : HarPostData, path : String, out : Array[Diagnostic]) -> Unit {
  if pd.mime_type == "" && pd.text != "" {
    push_diag(out, Info, "har.postData.mime.empty", path + ".mimeType", "post data has text but no MIME type")
  }
  validate_pairs(pd.params, path + ".params", out)
}

///|
fn is_common_method(method : String) -> Bool {
  method == "GET" || method == "POST" || method == "PUT" || method == "PATCH" ||
  method == "DELETE" || method == "HEAD" || method == "OPTIONS" || method == "TRACE"
}

///|
pub fn sum_known_timings(t : HarTimings) -> Int {
  positive(t.blocked) + positive(t.dns) + positive(t.connect) + positive(t.ssl) +
  positive(t.send) + positive(t.wait) + positive(t.receive)
}

///|
fn positive(value : Int) -> Int {
  if value > 0 { value } else { 0 }
}
