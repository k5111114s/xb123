# xb123: MoonHAR

MoonHAR is a MoonBit library and small CLI toolkit for working with HTTP
Archive (`.har`) files. It parses HAR-style JSON, validates common browser and
proxy exports, computes performance summaries, and emits compact reports for
CI, troubleshooting, and web performance experiments.

Repository: <https://github.com/k5111114s/xb123>

## Goals

- Parse HAR 1.2 JSON into MoonBit data structures.
- Validate required fields, timings, HTTP status ranges, and request metadata.
- Analyze request counts, status groups, resource types, domains, byte sizes,
  cache hits, and slow entries.
- Provide examples that can actually run with `moon run cmd/main`.
- Keep tests executable with `moon test`.

## Current Usage

```bash
moon test
moon run cmd/main
```

The library is intentionally dependency-light so it can be published to
mooncakes.io and used in CI without a complicated setup.

## License

Apache-2.0.
