///|
pub fn select_by_url_prefix(archive : HarArchive, prefix : String) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if archive.log.entries[i].request.url.has_prefix(prefix) {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_by_url_suffix(archive : HarArchive, suffix : String) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if archive.log.entries[i].request.url.has_suffix(suffix) {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_by_mime_prefix(archive : HarArchive, prefix : String) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if archive.log.entries[i].response.content.mime_type.has_prefix(prefix) {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_by_status(archive : HarArchive, status : Int) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if archive.log.entries[i].response.status == status {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_by_status_range(archive : HarArchive, min : Int, max : Int) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let status = archive.log.entries[i].response.status
    if status >= min && status <= max {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_secure_requests(archive : HarArchive) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if is_secure_url(archive.log.entries[i].request.url) {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_insecure_requests(archive : HarArchive) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if !is_secure_url(archive.log.entries[i].request.url) {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_post_bodies(archive : HarArchive) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    match archive.log.entries[i].request.post_data {
      Some(_) => out.push(archive.log.entries[i])
      None => ()
    }
  }
  out
}

///|
pub fn select_empty_responses(archive : HarArchive) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let entry = archive.log.entries[i]
    if entry.response.content.size == 0 && entry.response.body_size <= 0 {
      out.push(entry)
    }
  }
  out
}

///|
pub fn select_large_responses(archive : HarArchive, min_bytes : Int) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if payload_bytes(archive.log.entries[i]) >= min_bytes {
      out.push(archive.log.entries[i])
    }
  }
  out
}

///|
pub fn select_wait_bound(archive : HarArchive, min_ratio : Int) -> Array[HarEntry] {
  let out : Array[HarEntry] = []
  let rows = build_waterfall(archive)
  for i = 0; i < rows.length(); i = i + 1 {
    if row_wait_ratio(rows[i]) >= min_ratio {
      out.push(archive.log.entries[rows[i].index])
    }
  }
  out
}

///|
pub fn first_entry_for_domain(archive : HarArchive, domain : String) -> HarEntry? {
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if extract_domain(archive.log.entries[i].request.url) == domain {
      return Some(archive.log.entries[i])
    }
  }
  None
}

///|
pub fn last_entry_for_domain(archive : HarArchive, domain : String) -> HarEntry? {
  let mut found : HarEntry? = None
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    if extract_domain(archive.log.entries[i].request.url) == domain {
      found = Some(archive.log.entries[i])
    }
  }
  found
}

///|
pub fn unique_domains(archive : HarArchive) -> Array[String] {
  let out : Array[String] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let domain = extract_domain(archive.log.entries[i].request.url)
    if !out.contains(domain) {
      out.push(domain)
    }
  }
  out
}

///|
pub fn unique_methods(archive : HarArchive) -> Array[String] {
  let out : Array[String] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let method = archive.log.entries[i].request.method
    if !out.contains(method) {
      out.push(method)
    }
  }
  out
}

///|
pub fn unique_resource_kinds(archive : HarArchive) -> Array[String] {
  let out : Array[String] = []
  for i = 0; i < archive.log.entries.length(); i = i + 1 {
    let entry = archive.log.entries[i]
    let kind = resource_kind(entry.response.content.mime_type, entry.request.url)
    if !out.contains(kind) {
      out.push(kind)
    }
  }
  out
}
