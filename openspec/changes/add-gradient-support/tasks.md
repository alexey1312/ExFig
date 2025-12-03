# Tasks: Add SVG Gradient Support

TDD approach - write tests first, then implement.

## 1. Gradient Types (SVGTypes.swift)

- [ ] 1.1 Write tests for SVGGradientStop
- [ ] 1.2 Write tests for SVGLinearGradient
- [ ] 1.3 Write tests for SVGRadialGradient
- [ ] 1.4 Write tests for SVGFill enum
- [ ] 1.5 Implement gradient types in SVGTypes.swift
- [ ] 1.6 Run tests - verify pass

## 2. Gradient Parsing (SVGParser.swift)

- [ ] 2.1 Write tests for parsing linearGradient element
- [ ] 2.2 Write tests for parsing radialGradient element
- [ ] 2.3 Write tests for parsing stop elements with opacity
- [ ] 2.4 Write tests for resolving url(#id) references
- [ ] 2.5 Write tests for backward compatibility (SVG without gradients)
- [ ] 2.6 Implement gradient parsing in SVGParser.swift
- [ ] 2.7 Run tests - verify pass

## 3. Vector Drawable XML Generation (VectorDrawableXMLGenerator.swift)

- [ ] 3.1 Write tests for aapt namespace addition
- [ ] 3.2 Write tests for linear gradient XML output
- [ ] 3.3 Write tests for radial gradient XML output
- [ ] 3.4 Write tests for gradient stop opacity in ARGB format
- [ ] 3.5 Implement gradient generation in VectorDrawableXMLGenerator.swift
- [ ] 3.6 Run tests - verify pass

## 4. Compose ImageVector Generation (ImageVectorGenerator.swift)

- [ ] 4.1 Write tests for Brush.linearGradient() output
- [ ] 4.2 Write tests for Brush.radialGradient() output
- [ ] 4.3 Write tests for gradient stop opacity
- [ ] 4.4 Write tests for required imports (Brush, Offset)
- [ ] 4.5 Write tests for backward compatibility (solid colors)
- [ ] 4.6 Implement gradient generation in ImageVectorGenerator.swift
- [ ] 4.7 Run tests - verify pass

## 5. Integration

- [ ] 5.1 Write integration test with real SVG containing gradients
- [ ] 5.2 Test VD XML output validates against Android schema
- [ ] 5.3 Test Compose output compiles in sample project
- [ ] 5.4 Update documentation if needed
