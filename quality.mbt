///|
pub(all) struct QualityScore {
  score : Int
  grade : String
  notes : Array[String]
} derive(Eq, Show)

///|
pub fn score_archive(archive : HarArchive) -> QualityScore {
  let summary = analyze_archive(archive)
  let diagnostics = validate_archive(archive)
  let notes : Array[String] = []
  let mut score = 100
  let errors = diagnostics.count_if(d => d.severity == Error)
  let warnings = diagnostics.count_if(d => d.severity == Warning)
  if errors > 0 {
    score = score - errors * 20
    notes.push("validation errors: " + errors.to_string())
  }
  if warnings > 0 {
    score = score - warnings * 5
    notes.push("validation warnings: " + warnings.to_string())
  }
  if summary.failed_count > 0 {
    score = score - summary.failed_count * 15
    notes.push("failed requests: " + summary.failed_count.to_string())
  }
  if summary.average_time > 500 {
    score = score - 10
    notes.push("average request time above 500ms")
  }
  if summary.longest_time > 2000 {
    score = score - 10
    notes.push("slowest request above 2000ms")
  }
  if summary.total_bytes > 5_000_000 {
    score = score - 10
    notes.push("total bytes above 5MB")
  }
  let final_score = clamp_score(score)
  QualityScore::{ score: final_score, grade: grade_for_score(final_score), notes }
}

///|
fn clamp_score(score : Int) -> Int {
  if score < 0 { 0 } else if score > 100 { 100 } else { score }
}

///|
pub fn grade_for_score(score : Int) -> String {
  if score >= 90 {
    "A"
  } else if score >= 80 {
    "B"
  } else if score >= 70 {
    "C"
  } else if score >= 60 {
    "D"
  } else {
    "F"
  }
}

///|
pub fn render_quality(score : QualityScore) -> String {
  let mut out = "quality: " + score.score.to_string() + " (" + score.grade + ")\n"
  for i = 0; i < score.notes.length(); i = i + 1 {
    out = out + "- " + score.notes[i] + "\n"
  }
  out
}

///|
pub fn quality_badges(score : QualityScore) -> Array[String] {
  let badges : Array[String] = []
  if score.score >= 90 {
    badges.push("budget-friendly")
  }
  if score.notes.is_empty() {
    badges.push("clean")
  }
  if score.grade == "F" {
    badges.push("needs-attention")
  }
  badges
}

///|
pub fn recommendation_for_summary(summary : HarSummary) -> Array[String] {
  let out : Array[String] = []
  if summary.failed_count > 0 {
    out.push("fix failing HTTP responses first")
  }
  if summary.redirected_count > 3 {
    out.push("reduce redirect chains")
  }
  if summary.average_time > 500 {
    out.push("investigate slow average request time")
  }
  if summary.longest_time > 2000 {
    out.push("profile the slowest request")
  }
  if summary.total_bytes > 5_000_000 {
    out.push("reduce transferred bytes")
  }
  if out.is_empty() {
    out.push("archive is within the default quality envelope")
  }
  out
}

///|
pub fn render_recommendations(summary : HarSummary) -> String {
  let recs = recommendation_for_summary(summary)
  let mut out = ""
  for i = 0; i < recs.length(); i = i + 1 {
    out = out + "- " + recs[i] + "\n"
  }
  out
}
