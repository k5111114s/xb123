///|
pub fn package_name() -> String {
  "k5111114s/xb123"
}

///|
pub fn project_name() -> String {
  "xb123: MoonHAR"
}

///|
pub fn repository_url() -> String {
  "https://github.com/k5111114s/xb123"
}

///|
pub fn maintainer_name() -> String {
  "Xu Bo"
}

///|
pub fn maintainer_email() -> String {
  "2230679121@qq.com"
}

///|
pub fn license_name() -> String {
  "Apache-2.0"
}

///|
pub fn package_keywords() -> Array[String] {
  ["har", "http", "performance", "analysis", "moonbit"]
}

///|
pub fn package_banner() -> String {
  project_name() + "\n" + repository_url() + "\n" + license_name() + "\n"
}

///|
pub fn about_text() -> String {
  "MoonHAR parses, validates, analyzes, redacts, compares, and exports HTTP Archive data in MoonBit."
}

///|
pub fn submission_identity() -> String {
  maintainer_name() + " <" + maintainer_email() + "> " + repository_url()
}
