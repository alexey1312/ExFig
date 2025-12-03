# Tasks: Add SVG Gradient Support

TDD approach - write tests first, then implement.

## 1. Gradient Types (SVGTypes.swift)

- [x] 1.1 Write tests for SVGGradientStop
- [x] 1.2 Write tests for SVGLinearGradient
- [x] 1.3 Write tests for SVGRadialGradient
- [x] 1.4 Write tests for SVGFill enum
- [x] 1.5 Implement gradient types in SVGTypes.swift
- [x] 1.6 Run tests - verify pass

## 2. Gradient Parsing (SVGParser.swift)

- [x] 2.1 Write tests for parsing linearGradient element
- [x] 2.2 Write tests for parsing radialGradient element
- [x] 2.3 Write tests for parsing stop elements with opacity
- [x] 2.4 Write tests for resolving url(#id) references
- [x] 2.5 Write tests for backward compatibility (SVG without gradients)
- [x] 2.6 Implement gradient parsing in SVGParser.swift
- [x] 2.7 Run tests - verify pass

## 3. Vector Drawable XML Generation (VectorDrawableXMLGenerator.swift)

- [x] 3.1 Write tests for aapt namespace addition
- [x] 3.2 Write tests for linear gradient XML output
- [x] 3.3 Write tests for radial gradient XML output
- [x] 3.4 Write tests for gradient stop opacity in ARGB format
- [x] 3.5 Implement gradient generation in VectorDrawableXMLGenerator.swift
- [x] 3.6 Run tests - verify pass

## 4. Compose ImageVector Generation (ImageVectorGenerator.swift)

- [x] 4.1 Write tests for Brush.linearGradient() output
- [x] 4.2 Write tests for Brush.radialGradient() output
- [x] 4.3 Write tests for gradient stop opacity
- [x] 4.4 Write tests for required imports (Brush, Offset)
- [x] 4.5 Write tests for backward compatibility (solid colors)
- [x] 4.6 Implement gradient generation in ImageVectorGenerator.swift
- [x] 4.7 Run tests - verify pass

## 5. Integration

- [x] 5.1 Write integration test with real SVG containing gradients
- [x] 5.2 Test VD XML output validates against Android schema
- [x] 5.3 Test Compose output compiles in sample project
- [x] 5.4 Update documentation if needed
