///|
fn must_archive(text : String) -> HarArchive raise {
  match parse_har(text) {
    Ok(v) => v
    Err(e) => fail("parse_har failed at " + e.path + ": " + e.message)
  }
}

///|
fn must_json(text : String) -> JVal raise {
  match parse_json(text) {
    Ok(v) => v
    Err(e) => fail("parse_json failed at " + e.path + ": " + e.message)
  }
}

///|
test "json parser handles primitive values" {
  inspect(must_json("null"), content="JNull")
  inspect(must_json("true"), content="JBool(true)")
  inspect(must_json("\"hello\""), content="JStr(hello)")
  inspect(must_json("123"), content="JNum(123)")
}

///|
test "json parser handles arrays and objects" {
  inspect(
    must_json("{\"a\":1,\"b\":[true,false,null],\"c\":\"x\"}"),
    content="JObj({a: JNum(1), b: JArr([JBool(true), JBool(false), JNull]), c: JStr(x)})",
  )
}

///|
test "json parser rejects trailing tokens" {
  match parse_json("{\"a\":1} nope") {
    Ok(_) => fail("expected trailing token error")
    Err(e) => inspect(e.message, content="trailing characters after JSON value")
  }
}

///|
test "json parser rejects malformed object" {
  match parse_json("{\"a\" 1}") {
    Ok(_) => fail("expected malformed object error")
    Err(e) => inspect(e.message, content="expected colon after object key")
  }
}

///|
test "sample archive parses entries and pages" {
  let archive = must_archive(sample_har())
  inspect(archive.log.version, content="1.2")
  inspect(archive.log.creator_name, content="MoonHAR fixture")
  inspect(archive.log.pages.length(), content="1")
  inspect(archive.log.entries.length(), content="2")
}

///|
test "sample archive maps request details" {
  let archive = must_archive(sample_har())
  let first = archive.log.entries[0]
  inspect(first.request.method, content="GET")
  inspect(first.request.url, content="https://example.com/index.html")
  inspect(first.request.headers[0].name, content="accept")
  inspect(first.response.status, content="200")
  inspect(first.response.content.mime_type, content="text/html")
}

///|
test "sample archive maps post data and query string" {
  let archive = must_archive(sample_har())
  let second = archive.log.entries[1]
  inspect(second.request.method, content="POST")
  inspect(second.request.query_string[0].name, content="debug")
  match second.request.post_data {
    Some(pd) => {
      inspect(pd.mime_type, content="application/json")
      inspect(pd.text, content="{\"ok\":true}")
    }
    None => fail("expected postData")
  }
}

///|
test "sample archive validates without errors" {
  let archive = must_archive(sample_har())
  let diagnostics = validate_archive(archive)
  inspect(diagnostics.count_if(d => d.severity == Error), content="0")
  inspect(is_valid_archive(archive), content="true")
}

///|
test "validator reports bad status and timing" {
  let archive = must_archive(
    sample_har()
    .replace(old="\"status\": 200", new="\"status\": 1200")
    .replace(old="\"blocked\": 1", new="\"blocked\": -9"),
  )
  let diagnostics = validate_archive(archive)
  inspect(diagnostics.any(d => d.code == "har.response.status.range"), content="true")
  inspect(diagnostics.any(d => d.code == "har.timings.phase.range"), content="true")
}

///|
test "validator reports missing method during mapping" {
  let broken = sample_har().replace(old="\"method\": \"GET\",", new="")
  match parse_har(broken) {
    Ok(_) => fail("expected missing method")
    Err(e) => inspect(e.path, content="$.log.entries[0].request.method")
  }
}

///|
test "analyzer computes summary counts" {
  let summary = analyze_archive(must_archive(sample_har()))
  inspect(summary.entry_count, content="2")
  inspect(summary.page_count, content="1")
  inspect(summary.failed_count, content="0")
  inspect(summary.redirected_count, content="0")
  inspect(summary.total_time, content="155")
  inspect(summary.average_time, content="77")
}

///|
test "analyzer groups domains" {
  let summary = analyze_archive(must_archive(sample_har()))
  inspect(summary.domains.length(), content="2")
  inspect(summary.domains[0].domain, content="example.com")
  inspect(summary.domains[1].domain, content="api.example.com")
}

///|
test "analyzer groups status classes" {
  let summary = analyze_archive(must_archive(sample_har()))
  inspect(summary.statuses.length(), content="1")
  inspect(summary.statuses[0].group, content="2xx")
  inspect(summary.statuses[0].count, content="2")
}

///|
test "analyzer groups resources" {
  let summary = analyze_archive(must_archive(sample_har()))
  inspect(summary.resources.length(), content="2")
  inspect(summary.resources.any(r => r.kind == "document"), content="true")
  inspect(summary.resources.any(r => r.kind == "json"), content="true")
}

///|
test "slow entries sorted by time descending" {
  let summary = analyze_archive(must_archive(sample_har()))
  inspect(summary.slow_entries.length(), content="2")
  inspect(summary.slow_entries[0].time, content="120")
  inspect(summary.slow_entries[1].time, content="35")
}

///|
test "domain extraction strips scheme port and path" {
  inspect(extract_domain("https://example.com:8443/a/b?c=1"), content="example.com")
  inspect(extract_domain("http://localhost:8080"), content="localhost")
  inspect(extract_domain("bare-host/path"), content="bare-host")
}

///|
test "resource kind detects common MIME values and extensions" {
  inspect(resource_kind("text/html", "https://x/a"), content="document")
  inspect(resource_kind("application/javascript", "https://x/a"), content="script")
  inspect(resource_kind("", "https://x/a.css"), content="style")
  inspect(resource_kind("image/png", "https://x/a"), content="image")
  inspect(resource_kind("font/woff2", "https://x/a"), content="font")
}

///|
test "status group covers common ranges" {
  inspect(status_group(99), content="other")
  inspect(status_group(100), content="1xx")
  inspect(status_group(204), content="2xx")
  inspect(status_group(302), content="3xx")
  inspect(status_group(404), content="4xx")
  inspect(status_group(503), content="5xx")
}

///|
test "report renders human summary" {
  let report = render_summary(analyze_archive(must_archive(sample_har())))
  inspect(report.contains("MoonHAR summary"), content="true")
  inspect(report.contains("entries: 2"), content="true")
  inspect(report.contains("example.com"), content="true")
}

///|
test "report renders compact json" {
  let report = render_summary_json(analyze_archive(must_archive(sample_har())))
  inspect(report.contains("\"entryCount\":2"), content="true")
  inspect(report.contains("\"domains\""), content="true")
  inspect(report.contains("api.example.com"), content="true")
}

///|
test "diagnostic rendering reports no findings" {
  inspect(render_diagnostics([]), content="No validation findings.\n")
}

///|
test "diagnostic rendering includes severity and path" {
  let diagnostics = [
    Diagnostic::{
      severity: Error,
      code: "demo.error",
      path: "$.x",
      message: "broken",
    },
  ]
  inspect(render_diagnostics(diagnostics), content="ERROR demo.error $.x - broken\n")
}

///|
test "escape json handles report-sensitive characters" {
  inspect(escape_json("a\"b\\c\n"), content="a\\\"b\\\\c\\n")
}

///|
test "timing sum ignores missing phases" {
  let t = HarTimings::{
    blocked: -1,
    dns: 2,
    connect: 3,
    ssl: -1,
    send: 4,
    wait: 5,
    receive: 6,
  }
  inspect(sum_known_timings(t), content="20")
}
