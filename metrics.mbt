///|
pub(all) struct NumericStats {
  count : Int
  min : Int
  max : Int
  total : Int
  average : Int
} derive(Eq, Show)

///|
pub fn entry_time_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(entries[i].time)
  }
  numeric_stats(values)
}

///|
pub fn entry_size_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(entry_bytes(entries[i]))
  }
  numeric_stats(values)
}

///|
pub fn wait_time_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(phase_value(entries[i].timings.wait))
  }
  numeric_stats(values)
}

///|
pub fn receive_time_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(phase_value(entries[i].timings.receive))
  }
  numeric_stats(values)
}

///|
pub fn dns_time_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(phase_value(entries[i].timings.dns))
  }
  numeric_stats(values)
}

///|
pub fn connect_time_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(phase_value(entries[i].timings.connect))
  }
  numeric_stats(values)
}

///|
pub fn ssl_time_stats(entries : Array[HarEntry]) -> NumericStats {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(phase_value(entries[i].timings.ssl))
  }
  numeric_stats(values)
}

///|
fn phase_value(value : Int) -> Int {
  if value < 0 { 0 } else { value }
}

///|
pub fn numeric_stats(values : Array[Int]) -> NumericStats {
  if values.is_empty() {
    return NumericStats::{ count: 0, min: 0, max: 0, total: 0, average: 0 }
  }
  let mut min = values[0]
  let mut max = values[0]
  let mut total = 0
  for i = 0; i < values.length(); i = i + 1 {
    if values[i] < min {
      min = values[i]
    }
    if values[i] > max {
      max = values[i]
    }
    total = total + values[i]
  }
  NumericStats::{ count: values.length(), min, max, total, average: total / values.length() }
}

///|
pub fn percentile_nearest_rank(values : Array[Int], percentile : Int) -> Int {
  if values.is_empty() {
    return 0
  }
  let sorted = copy_ints(values)
  sort_ints(sorted)
  let p = if percentile < 0 { 0 } else if percentile > 100 { 100 } else { percentile }
  let rank = (p * sorted.length() + 99) / 100
  let index = if rank <= 0 { 0 } else { rank - 1 }
  sorted[index]
}

///|
pub fn p50_time(entries : Array[HarEntry]) -> Int {
  percentile_entry_time(entries, 50)
}

///|
pub fn p75_time(entries : Array[HarEntry]) -> Int {
  percentile_entry_time(entries, 75)
}

///|
pub fn p90_time(entries : Array[HarEntry]) -> Int {
  percentile_entry_time(entries, 90)
}

///|
pub fn p95_time(entries : Array[HarEntry]) -> Int {
  percentile_entry_time(entries, 95)
}

///|
pub fn p99_time(entries : Array[HarEntry]) -> Int {
  percentile_entry_time(entries, 99)
}

///|
fn percentile_entry_time(entries : Array[HarEntry], percentile : Int) -> Int {
  let values : Array[Int] = []
  for i = 0; i < entries.length(); i = i + 1 {
    values.push(entries[i].time)
  }
  percentile_nearest_rank(values, percentile)
}

///|
fn copy_ints(values : Array[Int]) -> Array[Int] {
  let out : Array[Int] = []
  for i = 0; i < values.length(); i = i + 1 {
    out.push(values[i])
  }
  out
}

///|
fn sort_ints(values : Array[Int]) -> Unit {
  for i = 0; i < values.length(); i = i + 1 {
    for j = i + 1; j < values.length(); j = j + 1 {
      if values[j] < values[i] {
        let tmp = values[i]
        values[i] = values[j]
        values[j] = tmp
      }
    }
  }
}

///|
pub fn render_numeric_stats(name : String, stats : NumericStats) -> String {
  name + ": count=" + stats.count.to_string() +
  " min=" + stats.min.to_string() +
  " max=" + stats.max.to_string() +
  " avg=" + stats.average.to_string() +
  " total=" + stats.total.to_string()
}

///|
pub fn timing_breakdown(entry : HarEntry) -> String {
  "blocked=" + phase_value(entry.timings.blocked).to_string() +
  " dns=" + phase_value(entry.timings.dns).to_string() +
  " connect=" + phase_value(entry.timings.connect).to_string() +
  " ssl=" + phase_value(entry.timings.ssl).to_string() +
  " send=" + phase_value(entry.timings.send).to_string() +
  " wait=" + phase_value(entry.timings.wait).to_string() +
  " receive=" + phase_value(entry.timings.receive).to_string()
}

///|
pub fn request_overhead_bytes(entry : HarEntry) -> Int {
  known_positive(entry.request.headers_size) + known_positive(entry.request.body_size)
}

///|
pub fn response_overhead_bytes(entry : HarEntry) -> Int {
  known_positive(entry.response.headers_size) + known_positive(entry.response.body_size)
}

///|
pub fn payload_bytes(entry : HarEntry) -> Int {
  known_positive(entry.response.content.size)
}

///|
fn known_positive(value : Int) -> Int {
  if value > 0 { value } else { 0 }
}
