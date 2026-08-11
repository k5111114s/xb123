///|
fn sample_archive_for_smoke() -> HarArchive raise {
  match parse_har(sample_har()) {
    Ok(v) => v
    Err(e) => fail(e.path + ": " + e.message)
  }
}

///|
test "readme public api smoke flow" {
  let archive = sample_archive_for_smoke()
  let diagnostics = validate_archive(archive)
  let summary = analyze_archive(archive)
  let rows = build_waterfall(archive)
  let budget = check_budget(archive, HarBudget::default())
  let quality = score_archive(archive)
  inspect(diagnostics.length(), content="0")
  inspect(summary.entry_count, content="2")
  inspect(rows.length(), content="2")
  inspect(budget.passed, content="true")
  inspect(quality.grade, content="A")
}

///|
test "reporting public api smoke flow" {
  let archive = sample_archive_for_smoke()
  let summary = analyze_archive(archive)
  inspect(render_summary(summary).contains("MoonHAR summary"), content="true")
  inspect(render_summary_json(summary).contains("\"entryCount\""), content="true")
  inspect(export_entries_csv(archive).contains("index,method"), content="true")
  inspect(export_full_report_json(archive).contains("\"waterfall\""), content="true")
  inspect(readiness_summary(archive).contains("ready"), content="true")
}

///|
test "query public api smoke flow" {
  let archive = sample_archive_for_smoke()
  inspect(filter_entries(archive, EntryFilter::for_method("GET")).length(), content="1")
  inspect(select_secure_requests(archive).length(), content="2")
  inspect(unique_domains(archive).contains("example.com"), content="true")
  inspect(collect_url_patterns(archive).length(), content="2")
  inspect(build_timeline(archive).length(), content="6")
}

///|
test "metadata public api smoke flow" {
  inspect(package_name(), content="k5111114s/xb123")
  inspect(project_name().contains("MoonHAR"), content="true")
  inspect(repository_url().contains("github.com/k5111114s/xb123"), content="true")
  inspect(maintainer_name(), content="Xu Bo")
  inspect(maintainer_email(), content="2230679121@qq.com")
  inspect(about_text().contains("HTTP Archive"), content="true")
}

///|
test "classification public api smoke flow" {
  let archive = sample_archive_for_smoke()
  let entry = archive.log.entries[0]
  inspect(status_family_label(entry.response.status), content="success")
  inspect(method_is_safe(entry.request.method), content="true")
  inspect(content_type(entry), content="text/html")
  inspect(url_path(entry.request.url), content="/index.html")
  inspect(entry_origin(entry), content="https://example.com")
}

///|
test "submission package identity is internally consistent" {
  let banner = package_banner()
  let identity = submission_identity()
  let keywords = package_keywords()
  inspect(banner.contains(project_name()), content="true")
  inspect(banner.contains(repository_url()), content="true")
  inspect(identity.contains(maintainer_name()), content="true")
  inspect(identity.contains(maintainer_email()), content="true")
  inspect(keywords.length(), content="5")
  inspect(keywords[0], content="har")
  inspect(keywords[1], content="http")
  inspect(keywords[2], content="performance")
  inspect(keywords[3], content="analysis")
  inspect(keywords[4], content="moonbit")
}

///|
test "about text mentions core verbs" {
  let about = about_text()
  inspect(about.contains("parses"), content="true")
  inspect(about.contains("validates"), content="true")
  inspect(about.contains("analyzes"), content="true")
  inspect(about.contains("exports"), content="true")
  inspect(about.contains("MoonBit"), content="true")
}

///|
test "license metadata is osi friendly" {
  inspect(license_name(), content="Apache-2.0")
}
