# MoonHAR Design Notes

MoonHAR is organized around four layers:

1. JSON parsing: a small parser tailored for HAR-compatible JSON payloads.
2. HAR model mapping: typed structures for logs, pages, entries, requests,
   responses, timings, headers, cookies, and query strings.
3. Validation: diagnostics with severity, path, code, and message.
4. Analysis: summaries, status grouping, domain grouping, resource grouping,
   waterfall normalization, and text reports.

The project is original MoonBit code. It does not copy source code from browser
developer tools or existing HAR libraries.
