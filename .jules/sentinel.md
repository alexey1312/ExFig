## 2024-05-22 - [XXE Protection in SVG Parser]
**Vulnerability:** The `XMLDocument` initializer in `SVGParser.swift` used empty options `[]`, which potentially allows XML External Entity (XXE) attacks if the underlying parser defaults are permissive.
**Learning:** Even when using higher-level abstractions like `XMLDocument`, one must explicitly disable dangerous features like external entity loading when processing untrusted input.
**Prevention:** Always use `.nodeLoadExternalEntitiesNever` (or equivalent flags in other parsers) when parsing XML/SVG data from external sources.
