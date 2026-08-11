///|
pub(all) struct TimelineEvent {
  at : Int
  label : String
  url : String
  entry_index : Int
} derive(Eq, Show)

///|
pub fn build_timeline(archive : HarArchive) -> Array[TimelineEvent] {
  let rows = build_waterfall(archive)
  let events : Array[TimelineEvent] = []
  for i = 0; i < rows.length(); i = i + 1 {
    let row = rows[i]
    events.push(TimelineEvent::{
      at: row.start_offset,
      label: "request:start",
      url: row.url,
      entry_index: row.index,
    })
    events.push(TimelineEvent::{
      at: row.start_offset + row.duration,
      label: "request:end",
      url: row.url,
      entry_index: row.index,
    })
    if row.wait > 0 {
      events.push(TimelineEvent::{
        at: row.start_offset + row.blocked + row.dns + row.connect + row.ssl + row.send,
        label: "request:wait",
        url: row.url,
        entry_index: row.index,
      })
    }
  }
  sort_timeline(events)
  events
}

///|
fn sort_timeline(events : Array[TimelineEvent]) -> Unit {
  for i = 0; i < events.length(); i = i + 1 {
    for j = i + 1; j < events.length(); j = j + 1 {
      if events[j].at < events[i].at {
        let tmp = events[i]
        events[i] = events[j]
        events[j] = tmp
      }
    }
  }
}

///|
pub fn events_at_or_after(events : Array[TimelineEvent], at : Int) -> Array[TimelineEvent] {
  let out : Array[TimelineEvent] = []
  for i = 0; i < events.length(); i = i + 1 {
    if events[i].at >= at {
      out.push(events[i])
    }
  }
  out
}

///|
pub fn events_for_entry(events : Array[TimelineEvent], entry_index : Int) -> Array[TimelineEvent] {
  let out : Array[TimelineEvent] = []
  for i = 0; i < events.length(); i = i + 1 {
    if events[i].entry_index == entry_index {
      out.push(events[i])
    }
  }
  out
}

///|
pub fn events_with_label(events : Array[TimelineEvent], label : String) -> Array[TimelineEvent] {
  let out : Array[TimelineEvent] = []
  for i = 0; i < events.length(); i = i + 1 {
    if events[i].label == label {
      out.push(events[i])
    }
  }
  out
}

///|
pub fn render_timeline(events : Array[TimelineEvent]) -> String {
  let mut out = ""
  for i = 0; i < events.length(); i = i + 1 {
    let e = events[i]
    out = out + e.at.to_string() + "ms " + e.label + " #" + e.entry_index.to_string() + " " + e.url + "\n"
  }
  out
}

///|
pub fn timeline_span(events : Array[TimelineEvent]) -> Int {
  if events.is_empty() {
    return 0
  }
  let mut min = events[0].at
  let mut max = events[0].at
  for i = 1; i < events.length(); i = i + 1 {
    if events[i].at < min {
      min = events[i].at
    }
    if events[i].at > max {
      max = events[i].at
    }
  }
  max - min
}

///|
pub fn timeline_event_count_for_label(events : Array[TimelineEvent], label : String) -> Int {
  events.count_if(e => e.label == label)
}
