///|
fn sample_archive_for_ext() -> HarArchive raise {
  match parse_har(sample_har()) {
    Ok(v) => v
    Err(e) => fail(e.path + ": " + e.message)
  }
}

///|
test "entry filter selects by domain" {
  let archive = sample_archive_for_ext()
  let entries = filter_entries(archive, EntryFilter::for_domain("example.com"))
  inspect(entries.length(), content="1")
  inspect(entries[0].request.url, content="https://example.com/index.html")
}

///|
test "entry filter selects by method" {
  let archive = sample_archive_for_ext()
  let entries = filter_entries(archive, EntryFilter::for_method("POST"))
  inspect(entries.length(), content="1")
  inspect(entries[0].request.method, content="POST")
}

///|
test "entry filter selects slow entries" {
  let archive = sample_archive_for_ext()
  let entries = filter_entries(archive, EntryFilter::slow(100))
  inspect(entries.length(), content="1")
  inspect(entries[0].time, content="120")
}

///|
test "entry filter supports failed only" {
  let archive = sample_archive_for_ext()
  let entries = filter_entries(archive, EntryFilter::failed())
  inspect(entries.length(), content="0")
}

///|
test "entry_matches handles url contains" {
  let archive = sample_archive_for_ext()
  let f = EntryFilter::{
    domain: None,
    method: None,
    status_min: None,
    status_max: None,
    resource: None,
    slow_ms: None,
    url_contains: Some("/v1/events"),
    failed_only: false,
  }
  inspect(entry_matches(archive.log.entries[1], f), content="true")
  inspect(entry_matches(archive.log.entries[0], f), content="false")
}

///|
test "entry helper counts and totals" {
  let archive = sample_archive_for_ext()
  let entries = archive.log.entries
  inspect(count_failed(entries), content="0")
  inspect(count_redirects(entries), content="0")
  inspect(count_method(entries, "GET"), content="1")
  inspect(count_resource(entries, "json"), content="1")
  inspect(total_entry_time(entries), content="155")
  inspect(total_entry_bytes(entries), content="4615")
}

///|
test "fastest and slowest helpers" {
  let archive = sample_archive_for_ext()
  match fastest_entry(archive.log.entries) {
    Some(e) => inspect(e.time, content="35")
    None => fail("expected fastest entry")
  }
  match slowest_entry(archive.log.entries) {
    Some(e) => inspect(e.time, content="120")
    None => fail("expected slowest entry")
  }
}

///|
test "entry helper subsets" {
  let archive = sample_archive_for_ext()
  inspect(entries_over_time(archive.log.entries, 100).length(), content="1")
  inspect(entries_for_status_group(archive.log.entries, "2xx").length(), content="2")
  inspect(entries_for_domain(archive.log.entries, "api.example.com").length(), content="1")
  inspect(entries_with_header(archive.log.entries, "content-type").length(), content="2")
}

///|
test "default budget passes sample" {
  let archive = sample_archive_for_ext()
  let result = check_budget(archive, HarBudget::default())
  inspect(result.passed, content="true")
  inspect(result.diagnostics.length(), content="0")
  inspect(budget_score(archive, HarBudget::default()), content="100")
}

///|
test "strict custom budget fails sample" {
  let archive = sample_archive_for_ext()
  let budget = HarBudget::{
    max_entries: 1,
    max_total_bytes: 100,
    max_total_time: 10,
    max_average_time: 10,
    max_failed: 0,
    max_redirects: 0,
    max_slowest_time: 10,
  }
  let result = check_budget(archive, budget)
  inspect(result.passed, content="false")
  inspect(result.diagnostics.length(), content="5")
  inspect(render_budget_result(result).contains("Performance budget failed"), content="true")
}

///|
test "waterfall rows normalize entries" {
  let archive = sample_archive_for_ext()
  let rows = build_waterfall(archive)
  inspect(rows.length(), content="2")
  inspect(rows[0].index, content="0")
  inspect(rows[0].domain, content="example.com")
  inspect(rows[1].start_offset, content="120")
  inspect(waterfall_total_duration(rows), content="155")
}

///|
test "waterfall row filters" {
  let rows = build_waterfall(sample_archive_for_ext())
  inspect(rows_for_domain(rows, "example.com").length(), content="1")
  inspect(rows_for_kind(rows, "json").length(), content="1")
  inspect(rows_after(rows, 100).length(), content="1")
}

///|
test "waterfall ratios and table rendering" {
  let rows = build_waterfall(sample_archive_for_ext())
  inspect(row_wait_ratio(rows[0]), content="75")
  inspect(row_receive_ratio(rows[0]), content="15")
  inspect(render_waterfall_table(rows).contains("idx method status"), content="true")
}

///|
test "redaction strips query and token segments" {
  let policy = RedactionPolicy::default()
  inspect(
    redact_url("https://example.com/session-abcdef1234567890/data?token=abc", policy),
    content="https://example.com/<redacted>/data",
  )
}

///|
test "redaction can replace domain" {
  let policy = RedactionPolicy::{
    redact_query: true,
    redact_tokens: false,
    redact_cookies: true,
    redact_domains: true,
    replacement: "hidden.local",
  }
  inspect(redact_url("https://api.example.com/a?b=1", policy), content="https://hidden.local/a")
}

///|
test "redaction masks sensitive pairs" {
  let policy = RedactionPolicy::default()
  let auth = HarPair::{ name: "Authorization", value: "Bearer abc" }
  let cookie = HarPair::{ name: "Cookie", value: "sid=abc" }
  let normal = HarPair::{ name: "Accept", value: "text/html" }
  inspect(redact_pair(auth, policy).value, content="<redacted>")
  inspect(redact_pair(cookie, policy).value, content="<redacted>")
  inspect(redact_pair(normal, policy).value, content="text/html")
}

///|
test "redacted slow report hides query" {
  let summary = analyze_archive(sample_archive_for_ext())
  let report = render_redacted_slow_entries(summary, RedactionPolicy::default())
  inspect(report.contains("?debug=1"), content="false")
  inspect(report.contains("/v1/events"), content="true")
}

///|
test "summary comparison has zero delta for same archive" {
  let archive = sample_archive_for_ext()
  let diff = compare_archives(archive, archive)
  inspect(diff.entry_delta, content="0")
  inspect(diff.failed_delta, content="0")
  inspect(diff_is_regression(diff), content="false")
}

///|
test "summary diff rendering uses signs" {
  let diff = SummaryDiff::{
    entry_delta: 1,
    failed_delta: 0,
    bytes_delta: -5,
    total_time_delta: 20,
    average_time_delta: 3,
    longest_time_delta: 9,
  }
  let report = render_diff(diff)
  inspect(report.contains("entries: +1"), content="true")
  inspect(report.contains("bytes: -5"), content="true")
}

///|
test "domain and resource count helpers" {
  let summary = analyze_archive(sample_archive_for_ext())
  inspect(domain_count(summary, "example.com"), content="1")
  inspect(domain_count(summary, "missing.example"), content="0")
  inspect(resource_count(summary, "document"), content="1")
  inspect(resource_count(summary, "video"), content="0")
}

///|
test "domain and resource delta helpers" {
  let summary = analyze_archive(sample_archive_for_ext())
  inspect(domain_delta(summary, summary, "example.com"), content="0")
  inspect(resource_delta(summary, summary, "json"), content="0")
}
