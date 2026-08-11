///|
pub fn is_success_status(status : Int) -> Bool {
  status >= 200 && status < 300
}

///|
pub fn is_redirect_status(status : Int) -> Bool {
  status >= 300 && status < 400
}

///|
pub fn is_client_error_status(status : Int) -> Bool {
  status >= 400 && status < 500
}

///|
pub fn is_server_error_status(status : Int) -> Bool {
  status >= 500 && status < 600
}

///|
pub fn is_cache_status(status : Int) -> Bool {
  status == 304
}

///|
pub fn status_family_label(status : Int) -> String {
  if is_success_status(status) {
    "success"
  } else if is_redirect_status(status) {
    "redirect"
  } else if is_client_error_status(status) {
    "client_error"
  } else if is_server_error_status(status) {
    "server_error"
  } else {
    "other"
  }
}

///|
pub fn method_allows_body(method : String) -> Bool {
  method == "POST" || method == "PUT" || method == "PATCH" || method == "DELETE"
}

///|
pub fn method_is_safe(method : String) -> Bool {
  method == "GET" || method == "HEAD" || method == "OPTIONS" || method == "TRACE"
}

///|
pub fn method_is_idempotent(method : String) -> Bool {
  method == "GET" || method == "HEAD" || method == "OPTIONS" || method == "TRACE" ||
  method == "PUT" || method == "DELETE"
}

///|
pub fn normalize_method(method : String) -> String {
  method.to_upper()
}

///|
pub fn header_value(headers : Array[HarPair], name : String) -> String? {
  let lower = name.to_lower()
  for i = 0; i < headers.length(); i = i + 1 {
    if headers[i].name.to_lower() == lower {
      return Some(headers[i].value)
    }
  }
  None
}

///|
pub fn content_type(entry : HarEntry) -> String {
  match header_value(entry.response.headers, "content-type") {
    Some(value) => value
    None => entry.response.content.mime_type
  }
}

///|
pub fn request_accept(entry : HarEntry) -> String {
  match header_value(entry.request.headers, "accept") {
    Some(value) => value
    None => ""
  }
}

///|
pub fn has_query_param(entry : HarEntry, name : String) -> Bool {
  entry.request.query_string.any(q => q.name == name)
}

///|
pub fn query_param_value(entry : HarEntry, name : String) -> String? {
  for i = 0; i < entry.request.query_string.length(); i = i + 1 {
    if entry.request.query_string[i].name == name {
      return Some(entry.request.query_string[i].value)
    }
  }
  None
}

///|
pub fn cache_policy(entry : HarEntry) -> String {
  match header_value(entry.response.headers, "cache-control") {
    Some(value) => value
    None => if entry.response.status == 304 { "revalidated" } else { "unknown" }
  }
}

///|
pub fn url_path(url : String) -> String {
  let no_scheme = match url.split_once("://") {
    Some((_, rest)) => rest.to_owned()
    None => url
  }
  match no_scheme.split_once("/") {
    Some((_, path)) => "/" + path.to_owned().split_once("?").map_or(path.to_owned(), p => p.0.to_owned())
    None => "/"
  }
}

///|
pub fn url_scheme(url : String) -> String {
  match url.split_once("://") {
    Some((scheme, _)) => scheme.to_owned()
    None => ""
  }
}

///|
pub fn is_secure_url(url : String) -> Bool {
  url_scheme(url) == "https"
}

///|
pub fn same_origin(left : String, right : String) -> Bool {
  url_scheme(left) == url_scheme(right) && extract_domain(left) == extract_domain(right)
}

///|
pub fn entry_origin(entry : HarEntry) -> String {
  let scheme = url_scheme(entry.request.url)
  let domain = extract_domain(entry.request.url)
  if scheme == "" {
    domain
  } else {
    scheme + "://" + domain
  }
}
