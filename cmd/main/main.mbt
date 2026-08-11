fn main {
  let archive = match @har.parse_har(@har.sample_har()) {
    Ok(v) => v
    Err(e) => {
      println("MoonHAR parse error at " + e.path + ": " + e.message)
      return
    }
  }
  let diagnostics = @har.validate_archive(archive)
  let summary = @har.analyze_archive(archive)
  println(@har.render_summary(summary))
  println(@har.render_diagnostics(diagnostics))
  println(@har.render_summary_json(summary))
}
