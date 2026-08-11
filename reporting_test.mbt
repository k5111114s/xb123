///|
fn sample_archive_for_reporting() -> HarArchive raise {
  match parse_har(sample_har()) {
    Ok(v) => v
    Err(e) => fail(e.path + ": " + e.message)
  }
}

///|
test "numeric stats summarize entry times" {
  let archive = sample_archive_for_reporting()
  let stats = entry_time_stats(archive.log.entries)
  inspect(stats.count, content="2")
  inspect(stats.min, content="35")
  inspect(stats.max, content="120")
  inspect(stats.total, content="155")
  inspect(stats.average, content="77")
}

///|
test "numeric stats summarize byte sizes" {
  let archive = sample_archive_for_reporting()
  let stats = entry_size_stats(archive.log.entries)
  inspect(stats.count, content="2")
  inspect(stats.min, content="295")
  inspect(stats.max, content="4320")
  inspect(stats.total, content="4615")
}

///|
test "phase stats normalize missing phases" {
  let archive = sample_archive_for_reporting()
  inspect(wait_time_stats(archive.log.entries).total, content="110")
  inspect(receive_time_stats(archive.log.entries).total, content="32")
  inspect(dns_time_stats(archive.log.entries).total, content="2")
  inspect(connect_time_stats(archive.log.entries).total, content="3")
  inspect(ssl_time_stats(archive.log.entries).total, content="1")
}

///|
test "percentiles use nearest rank" {
  let archive = sample_archive_for_reporting()
  inspect(p50_time(archive.log.entries), content="35")
  inspect(p75_time(archive.log.entries), content="120")
  inspect(p90_time(archive.log.entries), content="120")
  inspect(p95_time(archive.log.entries), content="120")
  inspect(p99_time(archive.log.entries), content="120")
}

///|
test "render numeric stats and timing breakdown" {
  let archive = sample_archive_for_reporting()
  let text = render_numeric_stats("time", entry_time_stats(archive.log.entries))
  inspect(text.contains("count=2"), content="true")
  inspect(timing_breakdown(archive.log.entries[0]).contains("wait=90"), content="true")
}

///|
test "byte helper split request response and payload sizes" {
  let archive = sample_archive_for_reporting()
  let entry = archive.log.entries[0]
  inspect(request_overhead_bytes(entry), content="128")
  inspect(response_overhead_bytes(entry), content="2144")
  inspect(payload_bytes(entry), content="2048")
}

///|
test "http status helpers classify families" {
  inspect(is_success_status(200), content="true")
  inspect(is_redirect_status(302), content="true")
  inspect(is_client_error_status(404), content="true")
  inspect(is_server_error_status(503), content="true")
  inspect(is_cache_status(304), content="true")
  inspect(status_family_label(503), content="server_error")
}

///|
test "method helpers normalize semantics" {
  inspect(method_allows_body("POST"), content="true")
  inspect(method_is_safe("GET"), content="true")
  inspect(method_is_idempotent("DELETE"), content="true")
  inspect(normalize_method("post"), content="POST")
}

///|
test "header and query helpers extract values" {
  let archive = sample_archive_for_reporting()
  let first = archive.log.entries[0]
  let second = archive.log.entries[1]
  inspect(content_type(first), content="text/html")
  inspect(request_accept(first), content="text/html")
  inspect(has_query_param(second, "debug"), content="true")
  inspect(query_param_value(second, "debug"), content="Some(1)")
}

///|
test "url helpers parse origin path and scheme" {
  inspect(url_path("https://example.com/a/b?c=1"), content="/a/b")
  inspect(url_scheme("https://example.com/a"), content="https")
  inspect(is_secure_url("https://example.com"), content="true")
  inspect(same_origin("https://example.com/a", "https://example.com/b"), content="true")
  inspect(entry_origin(sample_archive_for_reporting().log.entries[0]), content="https://example.com")
}

///|
test "quality score and recommendations work for sample" {
  let archive = sample_archive_for_reporting()
  let q = score_archive(archive)
  inspect(q.score, content="100")
  inspect(q.grade, content="A")
  inspect(quality_badges(q).contains("clean"), content="true")
  inspect(render_quality(q).contains("quality: 100"), content="true")
  inspect(render_recommendations(analyze_archive(archive)).contains("within"), content="true")
}

///|
test "profiles render and choose sample profile" {
  let archive = sample_archive_for_reporting()
  inspect(profile_names().contains("mobile"), content="true")
  inspect(describe_profile("api").contains("api"), content="true")
  inspect(render_profiles().contains("default"), content="true")
  inspect(best_profile_for_archive(archive), content="default")
  inspect(render_budget_matrix().contains("relaxed"), content="true")
}

///|
test "readiness checklist passes sample" {
  let archive = sample_archive_for_reporting()
  let items = readiness_check(archive)
  inspect(readiness_passed(items), content="true")
  inspect(failed_readiness_items(items).length(), content="0")
  inspect(render_readiness(items).contains("[x] has entries"), content="true")
  inspect(readiness_summary(archive).has_prefix("ready"), content="true")
}

///|
test "csv exports contain expected sections" {
  let archive = sample_archive_for_reporting()
  let summary = analyze_archive(archive)
  inspect(export_entries_csv(archive).contains("index,method,status"), content="true")
  inspect(export_domains_csv(summary).contains("example.com"), content="true")
  inspect(export_resources_csv(summary).contains("document"), content="true")
  inspect(export_statuses_csv(summary).contains("2xx"), content="true")
  inspect(export_slow_csv(summary).contains("api.example.com"), content="true")
}

///|
test "json exports contain waterfall and diagnostics" {
  let archive = sample_archive_for_reporting()
  inspect(export_waterfall_json(build_waterfall(archive)).contains("\"duration\":120"), content="true")
  inspect(export_diagnostics_json(validate_archive(archive)), content="[]")
  inspect(export_full_report_json(archive).contains("\"summary\""), content="true")
}

///|
test "csv cell quotes unsafe values" {
  inspect(csv_cell("abc"), content="abc")
  inspect(csv_cell("a,b"), content="\"a,b\"")
  inspect(csv_cell("a\"b"), content="\"a\"\"b\"")
}

///|
test "url patterns collapse numeric and id segments" {
  inspect(url_pattern("https://api.example.com/users/123/orders"), content="/users/:int/orders")
  inspect(url_pattern("https://api.example.com/items/abc-def-1234567890"), content="/items/:id")
}

///|
test "url pattern collection renders hot paths" {
  let patterns = collect_url_patterns(sample_archive_for_reporting())
  inspect(patterns.length(), content="2")
  inspect(render_url_patterns(patterns).contains("count=1"), content="true")
  match hottest_pattern(patterns) {
    Some(p) => inspect(p.pattern, content="/index.html")
    None => fail("expected hot pattern")
  }
  match heaviest_pattern(patterns) {
    Some(p) => inspect(p.pattern, content="/index.html")
    None => fail("expected heavy pattern")
  }
}

///|
test "insights report clean sample" {
  let insights = generate_insights(sample_archive_for_reporting())
  inspect(insights.length(), content="1")
  inspect(insights[0].title, content="No major issues detected")
  inspect(insight_count_by_severity(insights, Info), content="1")
  inspect(render_insights(insights).contains("INFO"), content="true")
}

///|
test "package metadata matches submission identity" {
  inspect(package_name(), content="k5111114s/xb123")
  inspect(repository_url(), content="https://github.com/k5111114s/xb123")
  inspect(maintainer_email(), content="2230679121@qq.com")
  inspect(license_name(), content="Apache-2.0")
  inspect(package_banner().contains("MoonHAR"), content="true")
  inspect(submission_identity().contains("2230679121@qq.com"), content="true")
}

///|
test "selectors locate practical request subsets" {
  let archive = sample_archive_for_reporting()
  inspect(select_by_url_prefix(archive, "https://example.com").length(), content="1")
  inspect(select_by_url_suffix(archive, "index.html").length(), content="1")
  inspect(select_by_mime_prefix(archive, "text/").length(), content="1")
  inspect(select_by_status(archive, 200).length(), content="1")
  inspect(select_by_status_range(archive, 200, 299).length(), content="2")
}

///|
test "selectors locate security body and size groups" {
  let archive = sample_archive_for_reporting()
  inspect(select_secure_requests(archive).length(), content="2")
  inspect(select_insecure_requests(archive).length(), content="0")
  inspect(select_post_bodies(archive).length(), content="1")
  inspect(select_empty_responses(archive).length(), content="0")
  inspect(select_large_responses(archive, 2000).length(), content="1")
}

///|
test "selectors locate wait-bound and unique values" {
  let archive = sample_archive_for_reporting()
  inspect(select_wait_bound(archive, 50).length(), content="2")
  inspect(unique_domains(archive).length(), content="2")
  inspect(unique_methods(archive).length(), content="2")
  inspect(unique_resource_kinds(archive).length(), content="2")
}

///|
test "first and last domain selectors return entries" {
  let archive = sample_archive_for_reporting()
  match first_entry_for_domain(archive, "example.com") {
    Some(e) => inspect(e.request.method, content="GET")
    None => fail("expected first domain entry")
  }
  match last_entry_for_domain(archive, "api.example.com") {
    Some(e) => inspect(e.request.method, content="POST")
    None => fail("expected last domain entry")
  }
}

///|
test "timeline builds sorted events" {
  let events = build_timeline(sample_archive_for_reporting())
  inspect(events.length(), content="6")
  inspect(events[0].at, content="0")
  inspect(timeline_span(events), content="155")
  inspect(timeline_event_count_for_label(events, "request:start"), content="2")
}

///|
test "timeline filters events" {
  let events = build_timeline(sample_archive_for_reporting())
  inspect(events_at_or_after(events, 120).length(), content="4")
  inspect(events_for_entry(events, 0).length(), content="3")
  inspect(events_with_label(events, "request:wait").length(), content="2")
  inspect(render_timeline(events).contains("request:start"), content="true")
}

///|
test "budget profile helpers expose strict and relaxed budgets" {
  inspect(strictest_budget().max_entries, content="60")
  inspect(loosest_budget().max_entries, content="400")
  inspect(ci_budget().max_redirects, content="4")
  inspect(relaxed_budget().max_failed, content="2")
  inspect(profile_budget_matrix().length(), content="8")
}

///|
test "full report json combines generated report sections" {
  let archive = sample_archive_for_reporting()
  let report = export_full_report_json(archive)
  inspect(report.contains("\"summary\""), content="true")
  inspect(report.contains("\"diagnostics\""), content="true")
  inspect(report.contains("\"waterfall\""), content="true")
  inspect(report.contains("example.com"), content="true")
}

///|
test "waterfall json row includes stable fields" {
  let row = build_waterfall(sample_archive_for_reporting())[0]
  let json = export_waterfall_row_json(row)
  inspect(json.contains("\"index\":0"), content="true")
  inspect(json.contains("\"method\":\"GET\""), content="true")
  inspect(json.contains("\"status\":200"), content="true")
  inspect(json.contains("\"kind\":\"document\""), content="true")
}

///|
test "diagnostic json escapes diagnostic fields" {
  let diagnostics = [
    Diagnostic::{
      severity: Warning,
      code: "demo.warn",
      path: "$.x",
      message: "message with \"quote\"",
    },
  ]
  let json = export_diagnostics_json(diagnostics)
  inspect(json.contains("demo.warn"), content="true")
  inspect(json.contains("\\\"quote\\\""), content="true")
}

///|
test "selector empty cases return empty arrays" {
  let archive = sample_archive_for_reporting()
  inspect(select_by_url_prefix(archive, "https://missing.example").length(), content="0")
  inspect(select_by_url_suffix(archive, ".png").length(), content="0")
  inspect(select_by_status(archive, 404).length(), content="0")
  inspect(select_large_responses(archive, 999999).length(), content="0")
}

///|
test "insight severity count handles missing severity" {
  let insights = generate_insights(sample_archive_for_reporting())
  inspect(insight_count_by_severity(insights, Error), content="0")
  inspect(insight_count_by_severity(insights, Warning), content="0")
  inspect(insight_count_by_severity(insights, Info), content="1")
}

///|
test "package keywords describe package use" {
  let words = package_keywords()
  inspect(words.contains("har"), content="true")
  inspect(words.contains("performance"), content="true")
  inspect(about_text().contains("HTTP Archive"), content="true")
  inspect(project_name().contains("xb123"), content="true")
}
