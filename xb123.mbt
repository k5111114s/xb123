///|
/// JSON value used by MoonHAR.
pub(all) enum JVal {
  JNull
  JBool(Bool)
  JNum(String)
  JStr(String)
  JArr(Array[JVal])
  JObj(Map[String, JVal])
} derive(Eq, Show)

///|
/// Parse or mapping problem with a stable path.
pub(all) struct HarError {
  path : String
  message : String
} derive(Eq, Show)

///|
/// Name/value pair used by headers, cookies, and query strings.
pub(all) struct HarPair {
  name : String
  value : String
} derive(Eq, Show)

///|
/// HAR request payload model.
pub(all) struct HarPostData {
  mime_type : String
  text : String
  params : Array[HarPair]
} derive(Eq, Show)

///|
/// HAR request model.
pub(all) struct HarRequest {
  method : String
  url : String
  http_version : String
  headers : Array[HarPair]
  query_string : Array[HarPair]
  cookies : Array[HarPair]
  headers_size : Int
  body_size : Int
  post_data : HarPostData?
} derive(Eq, Show)

///|
/// HAR response body content.
pub(all) struct HarContent {
  size : Int
  mime_type : String
  text : String
  encoding : String
} derive(Eq, Show)

///|
/// HAR response model.
pub(all) struct HarResponse {
  status : Int
  status_text : String
  http_version : String
  headers : Array[HarPair]
  cookies : Array[HarPair]
  content : HarContent
  redirect_url : String
  headers_size : Int
  body_size : Int
} derive(Eq, Show)

///|
/// Timing fields are milliseconds. A value of -1 means the phase was omitted.
pub(all) struct HarTimings {
  blocked : Int
  dns : Int
  connect : Int
  ssl : Int
  send : Int
  wait : Int
  receive : Int
} derive(Eq, Show)

///|
/// HAR entry model.
pub(all) struct HarEntry {
  started_date_time : String
  time : Int
  request : HarRequest
  response : HarResponse
  timings : HarTimings
  server_ip_address : String
  connection : String
  pageref : String
} derive(Eq, Show)

///|
/// Page timings stored at HAR page level.
pub(all) struct HarPageTimings {
  on_content_load : Int
  on_load : Int
} derive(Eq, Show)

///|
/// HAR page model.
pub(all) struct HarPage {
  id : String
  title : String
  started_date_time : String
  page_timings : HarPageTimings
} derive(Eq, Show)

///|
/// Top-level HAR log.
pub(all) struct HarLog {
  version : String
  creator_name : String
  creator_version : String
  pages : Array[HarPage]
  entries : Array[HarEntry]
} derive(Eq, Show)

///|
/// Parsed HAR document.
pub(all) struct HarArchive {
  log : HarLog
} derive(Eq, Show)

///|
/// Mutable parser state.
struct JsonParser {
  text : String
  mut pos : Int
}

///|
pub fn parse_json(text : String) -> Result[JVal, HarError] {
  let p = JsonParser::{ text, pos: 0 }
  p.skip_ws()
  match p.parse_value() {
    Ok(v) => {
      p.skip_ws()
      if p.pos == text.length() {
        Ok(v)
      } else {
        Err(HarError::{ path: "$", message: "trailing characters after JSON value" })
      }
    }
    Err(e) => Err(e)
  }
}

///|
pub fn parse_har(text : String) -> Result[HarArchive, HarError] {
  match parse_json(text) {
    Ok(json) => har_from_json(json)
    Err(e) => Err(e)
  }
}

///|
fn JsonParser::current(self : JsonParser) -> Char? {
  self.text.get_char(self.pos)
}

///|
fn JsonParser::advance(self : JsonParser) -> Unit {
  self.pos = self.pos + 1
}

///|
fn JsonParser::err(self : JsonParser, message : String) -> HarError {
  HarError::{ path: "$@" + self.pos.to_string(), message }
}

///|
fn JsonParser::skip_ws(self : JsonParser) -> Unit {
  while self.pos < self.text.length() {
    match self.current() {
      Some(' ') | Some('\n') | Some('\r') | Some('\t') => self.advance()
      _ => break
    }
  }
}

///|
fn JsonParser::parse_value(self : JsonParser) -> Result[JVal, HarError] {
  self.skip_ws()
  match self.current() {
    Some('{') => self.parse_object()
    Some('[') => self.parse_array()
    Some('"') => self.parse_string_value()
    Some('t') => self.parse_literal("true", JBool(true))
    Some('f') => self.parse_literal("false", JBool(false))
    Some('n') => self.parse_literal("null", JNull)
    Some('-') => self.parse_number()
    Some(ch) =>
      if is_digit(ch) {
        self.parse_number()
      } else {
        Err(self.err("unexpected character while parsing JSON value"))
      }
    None => Err(self.err("unexpected end of JSON input"))
  }
}

///|
fn JsonParser::parse_literal(
  self : JsonParser,
  literal : String,
  value : JVal
) -> Result[JVal, HarError] {
  let end = self.pos + literal.length()
  if end <= self.text.length() && self.text.substring(start=self.pos, end~) == literal {
    self.pos = end
    Ok(value)
  } else {
    Err(self.err("invalid JSON literal"))
  }
}

///|
fn JsonParser::parse_string_value(self : JsonParser) -> Result[JVal, HarError] {
  match self.parse_string_raw() {
    Ok(s) => Ok(JStr(s))
    Err(e) => Err(e)
  }
}

///|
fn JsonParser::parse_string_raw(self : JsonParser) -> Result[String, HarError] {
  match self.current() {
    Some('"') => self.advance()
    _ => return Err(self.err("expected string opening quote"))
  }
  let mut out = ""
  while self.pos < self.text.length() {
    match self.current() {
      Some('"') => {
        self.advance()
        return Ok(out)
      }
      Some('\\') => {
        self.advance()
        match self.current() {
          Some('"') => { out = out + "\""; self.advance() }
          Some('\\') => { out = out + "\\"; self.advance() }
          Some('/') => { out = out + "/"; self.advance() }
          Some('b') => { out = out + "\b"; self.advance() }
          Some('f') => { out = out + "\u{000c}"; self.advance() }
          Some('n') => { out = out + "\n"; self.advance() }
          Some('r') => { out = out + "\r"; self.advance() }
          Some('t') => { out = out + "\t"; self.advance() }
          Some('u') => {
            self.advance()
            let start = self.pos
            let end = self.pos + 4
            if end <= self.text.length() {
              out = out + "\\u" + self.text.substring(start~, end~)
              self.pos = end
            } else {
              return Err(self.err("incomplete unicode escape"))
            }
          }
          _ => return Err(self.err("invalid string escape"))
        }
      }
      Some(ch) => {
        out = out + ch.to_string()
        self.advance()
      }
      None => return Err(self.err("unterminated JSON string"))
    }
  }
  Err(self.err("unterminated JSON string"))
}

///|
fn JsonParser::parse_number(self : JsonParser) -> Result[JVal, HarError] {
  let start = self.pos
  if self.current() == Some('-') {
    self.advance()
  }
  if self.current() == Some('0') {
    self.advance()
  } else {
    if !self.current().map_or(false, is_digit) {
      return Err(self.err("expected digit in number"))
    }
    while self.current().map_or(false, is_digit) {
      self.advance()
    }
  }
  if self.current() == Some('.') {
    self.advance()
    if !self.current().map_or(false, is_digit) {
      return Err(self.err("expected digit after decimal point"))
    }
    while self.current().map_or(false, is_digit) {
      self.advance()
    }
  }
  match self.current() {
    Some('e') | Some('E') => {
      self.advance()
      match self.current() {
        Some('+') | Some('-') => self.advance()
        _ => ()
      }
      if !self.current().map_or(false, is_digit) {
        return Err(self.err("expected digit in exponent"))
      }
      while self.current().map_or(false, is_digit) {
        self.advance()
      }
    }
    _ => ()
  }
  Ok(JNum(self.text.substring(start~, end=self.pos)))
}

///|
fn JsonParser::parse_array(self : JsonParser) -> Result[JVal, HarError] {
  self.advance()
  let arr : Array[JVal] = []
  self.skip_ws()
  if self.current() == Some(']') {
    self.advance()
    return Ok(JArr(arr))
  }
  while true {
    match self.parse_value() {
      Ok(v) => arr.push(v)
      Err(e) => return Err(e)
    }
    self.skip_ws()
    match self.current() {
      Some(',') => {
        self.advance()
        self.skip_ws()
      }
      Some(']') => {
        self.advance()
        return Ok(JArr(arr))
      }
      _ => return Err(self.err("expected comma or array closing bracket"))
    }
  }
  Err(self.err("unreachable array parser state"))
}

///|
fn JsonParser::parse_object(self : JsonParser) -> Result[JVal, HarError] {
  self.advance()
  let obj : Map[String, JVal] = Map([])
  self.skip_ws()
  if self.current() == Some('}') {
    self.advance()
    return Ok(JObj(obj))
  }
  while true {
    self.skip_ws()
    let key = match self.parse_string_raw() {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    self.skip_ws()
    if self.current() != Some(':') {
      return Err(self.err("expected colon after object key"))
    }
    self.advance()
    let value = match self.parse_value() {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    obj[key] = value
    self.skip_ws()
    match self.current() {
      Some(',') => {
        self.advance()
        self.skip_ws()
      }
      Some('}') => {
        self.advance()
        return Ok(JObj(obj))
      }
      _ => return Err(self.err("expected comma or object closing brace"))
    }
  }
  Err(self.err("unreachable object parser state"))
}

///|
fn is_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn parse_int_text(text : String) -> Int {
  let mut i = 0
  let mut sign = 1
  let mut value = 0
  if text.get_char(0) == Some('-') {
    sign = -1
    i = 1
  }
  while i < text.length() {
    match text.get_char(i) {
      Some(ch) =>
        if is_digit(ch) {
          value = value * 10 + (ch.to_int() - '0'.to_int())
          i = i + 1
        } else {
          return value * sign
        }
      None => return value * sign
    }
  }
  value * sign
}

///|
fn obj_get(obj : Map[String, JVal], key : String) -> JVal? {
  obj.get(key)
}

///|
fn expect_obj(value : JVal, path : String) -> Result[Map[String, JVal], HarError] {
  match value {
    JObj(obj) => Ok(obj)
    _ => Err(HarError::{ path, message: "expected object" })
  }
}

///|
fn expect_arr(value : JVal, path : String) -> Result[Array[JVal], HarError] {
  match value {
    JArr(arr) => Ok(arr)
    _ => Err(HarError::{ path, message: "expected array" })
  }
}

///|
fn expect_str(value : JVal, path : String) -> Result[String, HarError] {
  match value {
    JStr(s) => Ok(s)
    _ => Err(HarError::{ path, message: "expected string" })
  }
}

///|
fn expect_int(value : JVal, path : String) -> Result[Int, HarError] {
  match value {
    JNum(s) => Ok(parse_int_text(s))
    _ => Err(HarError::{ path, message: "expected number" })
  }
}

///|
fn opt_str(obj : Map[String, JVal], key : String, default : String) -> String {
  match obj.get(key) {
    Some(JStr(s)) => s
    _ => default
  }
}

///|
fn opt_int(obj : Map[String, JVal], key : String, default : Int) -> Int {
  match obj.get(key) {
    Some(JNum(s)) => parse_int_text(s)
    _ => default
  }
}

///|
fn req_obj(obj : Map[String, JVal], key : String, path : String) -> Result[Map[String, JVal], HarError] {
  match obj.get(key) {
    Some(v) => expect_obj(v, path + "." + key)
    None => Err(HarError::{ path: path + "." + key, message: "missing required object" })
  }
}

///|
fn req_arr(obj : Map[String, JVal], key : String, path : String) -> Result[Array[JVal], HarError] {
  match obj.get(key) {
    Some(v) => expect_arr(v, path + "." + key)
    None => Err(HarError::{ path: path + "." + key, message: "missing required array" })
  }
}

///|
fn req_str(obj : Map[String, JVal], key : String, path : String) -> Result[String, HarError] {
  match obj.get(key) {
    Some(v) => expect_str(v, path + "." + key)
    None => Err(HarError::{ path: path + "." + key, message: "missing required string" })
  }
}

///|
fn req_int(obj : Map[String, JVal], key : String, path : String) -> Result[Int, HarError] {
  match obj.get(key) {
    Some(v) => expect_int(v, path + "." + key)
    None => Err(HarError::{ path: path + "." + key, message: "missing required number" })
  }
}

///|
fn parse_pairs(values : Array[JVal], path : String) -> Result[Array[HarPair], HarError] {
  let out : Array[HarPair] = []
  for i = 0; i < values.length(); i = i + 1 {
    let obj = match expect_obj(values[i], path + "[" + i.to_string() + "]") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    out.push(HarPair::{
      name: opt_str(obj, "name", ""),
      value: opt_str(obj, "value", ""),
    })
  }
  Ok(out)
}

///|
fn parse_post_data(obj : Map[String, JVal], path : String) -> Result[HarPostData, HarError] {
  let params = match obj.get("params") {
    Some(JArr(arr)) => match parse_pairs(arr, path + ".params") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    _ => []
  }
  Ok(HarPostData::{
    mime_type: opt_str(obj, "mimeType", ""),
    text: opt_str(obj, "text", ""),
    params,
  })
}

///|
fn parse_content(obj : Map[String, JVal], path : String) -> Result[HarContent, HarError] {
  Ok(HarContent::{
    size: opt_int(obj, "size", 0),
    mime_type: opt_str(obj, "mimeType", ""),
    text: opt_str(obj, "text", ""),
    encoding: opt_str(obj, "encoding", ""),
  })
}

///|
fn parse_request(obj : Map[String, JVal], path : String) -> Result[HarRequest, HarError] {
  let headers = match obj.get("headers") {
    Some(JArr(arr)) => match parse_pairs(arr, path + ".headers") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    _ => []
  }
  let query_string = match obj.get("queryString") {
    Some(JArr(arr)) => match parse_pairs(arr, path + ".queryString") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    _ => []
  }
  let cookies = match obj.get("cookies") {
    Some(JArr(arr)) => match parse_pairs(arr, path + ".cookies") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    _ => []
  }
  let post_data = match obj.get("postData") {
    Some(JObj(pd)) => match parse_post_data(pd, path + ".postData") {
      Ok(v) => Some(v)
      Err(e) => return Err(e)
    }
    _ => None
  }
  Ok(HarRequest::{
    method: match req_str(obj, "method", path) { Ok(v) => v; Err(e) => return Err(e) },
    url: match req_str(obj, "url", path) { Ok(v) => v; Err(e) => return Err(e) },
    http_version: opt_str(obj, "httpVersion", ""),
    headers,
    query_string,
    cookies,
    headers_size: opt_int(obj, "headersSize", -1),
    body_size: opt_int(obj, "bodySize", -1),
    post_data,
  })
}

///|
fn parse_response(obj : Map[String, JVal], path : String) -> Result[HarResponse, HarError] {
  let headers = match obj.get("headers") {
    Some(JArr(arr)) => match parse_pairs(arr, path + ".headers") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    _ => []
  }
  let cookies = match obj.get("cookies") {
    Some(JArr(arr)) => match parse_pairs(arr, path + ".cookies") {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    _ => []
  }
  let content_obj = match req_obj(obj, "content", path) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let content = match parse_content(content_obj, path + ".content") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  Ok(HarResponse::{
    status: match req_int(obj, "status", path) { Ok(v) => v; Err(e) => return Err(e) },
    status_text: opt_str(obj, "statusText", ""),
    http_version: opt_str(obj, "httpVersion", ""),
    headers,
    cookies,
    content,
    redirect_url: opt_str(obj, "redirectURL", ""),
    headers_size: opt_int(obj, "headersSize", -1),
    body_size: opt_int(obj, "bodySize", -1),
  })
}

///|
fn parse_timings(obj : Map[String, JVal]) -> HarTimings {
  HarTimings::{
    blocked: opt_int(obj, "blocked", -1),
    dns: opt_int(obj, "dns", -1),
    connect: opt_int(obj, "connect", -1),
    ssl: opt_int(obj, "ssl", -1),
    send: opt_int(obj, "send", -1),
    wait: opt_int(obj, "wait", -1),
    receive: opt_int(obj, "receive", -1),
  }
}

///|
fn parse_entry(value : JVal, index : Int) -> Result[HarEntry, HarError] {
  let path = "$.log.entries[" + index.to_string() + "]"
  let obj = match expect_obj(value, path) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let req = match req_obj(obj, "request", path) {
    Ok(v) => match parse_request(v, path + ".request") {
      Ok(r) => r
      Err(e) => return Err(e)
    }
    Err(e) => return Err(e)
  }
  let res = match req_obj(obj, "response", path) {
    Ok(v) => match parse_response(v, path + ".response") {
      Ok(r) => r
      Err(e) => return Err(e)
    }
    Err(e) => return Err(e)
  }
  let timings = match req_obj(obj, "timings", path) {
    Ok(v) => parse_timings(v)
    Err(e) => return Err(e)
  }
  Ok(HarEntry::{
    started_date_time: opt_str(obj, "startedDateTime", ""),
    time: opt_int(obj, "time", 0),
    request: req,
    response: res,
    timings,
    server_ip_address: opt_str(obj, "serverIPAddress", ""),
    connection: opt_str(obj, "connection", ""),
    pageref: opt_str(obj, "pageref", ""),
  })
}

///|
fn parse_page_timings(obj : Map[String, JVal]) -> HarPageTimings {
  HarPageTimings::{
    on_content_load: opt_int(obj, "onContentLoad", -1),
    on_load: opt_int(obj, "onLoad", -1),
  }
}

///|
fn parse_page(value : JVal, index : Int) -> Result[HarPage, HarError] {
  let path = "$.log.pages[" + index.to_string() + "]"
  let obj = match expect_obj(value, path) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let timings = match obj.get("pageTimings") {
    Some(JObj(t)) => parse_page_timings(t)
    _ => HarPageTimings::{ on_content_load: -1, on_load: -1 }
  }
  Ok(HarPage::{
    id: opt_str(obj, "id", ""),
    title: opt_str(obj, "title", ""),
    started_date_time: opt_str(obj, "startedDateTime", ""),
    page_timings: timings,
  })
}

///|
fn har_from_json(value : JVal) -> Result[HarArchive, HarError] {
  let root = match expect_obj(value, "$") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let log = match req_obj(root, "log", "$") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let creator = match req_obj(log, "creator", "$.log") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let pages_json = match log.get("pages") {
    Some(JArr(arr)) => arr
    _ => []
  }
  let entries_json = match req_arr(log, "entries", "$.log") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let pages : Array[HarPage] = []
  for i = 0; i < pages_json.length(); i = i + 1 {
    match parse_page(pages_json[i], i) {
      Ok(page) => pages.push(page)
      Err(e) => return Err(e)
    }
  }
  let entries : Array[HarEntry] = []
  for i = 0; i < entries_json.length(); i = i + 1 {
    match parse_entry(entries_json[i], i) {
      Ok(entry) => entries.push(entry)
      Err(e) => return Err(e)
    }
  }
  Ok(HarArchive::{
    log: HarLog::{
      version: opt_str(log, "version", ""),
      creator_name: opt_str(creator, "name", ""),
      creator_version: opt_str(creator, "version", ""),
      pages,
      entries,
    },
  })
}

///|
pub fn sample_har() -> String {
  #|{
  #|  "log": {
  #|    "version": "1.2",
  #|    "creator": { "name": "MoonHAR fixture", "version": "1.0" },
  #|    "pages": [
  #|      {
  #|        "id": "page_1",
  #|        "startedDateTime": "2026-08-11T00:00:00.000Z",
  #|        "title": "Example",
  #|        "pageTimings": { "onContentLoad": 80, "onLoad": 140 }
  #|      }
  #|    ],
  #|    "entries": [
  #|      {
  #|        "pageref": "page_1",
  #|        "startedDateTime": "2026-08-11T00:00:00.010Z",
  #|        "time": 120,
  #|        "request": {
  #|          "method": "GET",
  #|          "url": "https://example.com/index.html",
  #|          "httpVersion": "HTTP/2",
  #|          "cookies": [],
  #|          "headers": [{ "name": "accept", "value": "text/html" }],
  #|          "queryString": [],
  #|          "headersSize": 128,
  #|          "bodySize": 0
  #|        },
  #|        "response": {
  #|          "status": 200,
  #|          "statusText": "OK",
  #|          "httpVersion": "HTTP/2",
  #|          "cookies": [],
  #|          "headers": [{ "name": "content-type", "value": "text/html" }],
  #|          "content": { "size": 2048, "mimeType": "text/html", "text": "" },
  #|          "redirectURL": "",
  #|          "headersSize": 96,
  #|          "bodySize": 2048
  #|        },
  #|        "cache": {},
  #|        "timings": { "blocked": 1, "dns": 2, "connect": 3, "ssl": 1, "send": 4, "wait": 90, "receive": 19 },
  #|        "serverIPAddress": "93.184.216.34",
  #|        "connection": "443"
  #|      },
  #|      {
  #|        "pageref": "page_1",
  #|        "startedDateTime": "2026-08-11T00:00:00.060Z",
  #|        "time": 35,
  #|        "request": {
  #|          "method": "POST",
  #|          "url": "https://api.example.com/v1/events?debug=1",
  #|          "httpVersion": "HTTP/2",
  #|          "cookies": [],
  #|          "headers": [{ "name": "content-type", "value": "application/json" }],
  #|          "queryString": [{ "name": "debug", "value": "1" }],
  #|          "postData": { "mimeType": "application/json", "text": "{\"ok\":true}", "params": [] },
  #|          "headersSize": 132,
  #|          "bodySize": 11
  #|        },
  #|        "response": {
  #|          "status": 201,
  #|          "statusText": "Created",
  #|          "httpVersion": "HTTP/2",
  #|          "cookies": [],
  #|          "headers": [{ "name": "content-type", "value": "application/json" }],
  #|          "content": { "size": 32, "mimeType": "application/json", "text": "{}" },
  #|          "redirectURL": "",
  #|          "headersSize": 88,
  #|          "bodySize": 32
  #|        },
  #|        "cache": {},
  #|        "timings": { "blocked": 0, "dns": -1, "connect": -1, "ssl": -1, "send": 2, "wait": 20, "receive": 13 }
  #|      }
  #|    ]
  #|  }
  #|}
}
