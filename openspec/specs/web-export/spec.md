# web-export Specification

## Purpose

TBD - created by archiving change add-web-platform. Update Purpose after archive.

## Requirements

### Requirement: Web Colors Export

The system SHALL export Figma color tokens to Web-compatible formats (CSS variables, TypeScript constants, JSON) when
`web.colors` configuration is present.

#### Scenario: Export colors to CSS variables

- **GIVEN** a YAML config with `web.colors[].cssFileName: "theme.css"`
- **AND** Figma Variables contain color tokens with light and dark modes
- **WHEN** `exfig colors` is executed
- **THEN** a CSS file is generated with class-based selectors (`.theme-light`, `.theme-dark`)
- **AND** variables use kebab-case naming (e.g., `--background-primary: #ffffff;`)

**Default CSS output format (web-ui compatible):**

```css
.theme-light {
  --background-primary: #ffffff;
  --text-and-icon-primary: #141414;
}

.theme-dark {
  --background-primary: #141414;
  --text-and-icon-primary: #ffffff;
}
```

#### Scenario: Export colors to TypeScript constants

- **GIVEN** a YAML config with `web.colors[].tsFileName: "variables.ts"`
- **AND** Figma Variables contain color tokens
- **WHEN** `exfig colors` is executed
- **THEN** a TypeScript file is generated with CSS variable references
- **AND** variable names use kebab-case keys matching CSS variables

**Default TypeScript output format (web-ui compatible):**

```typescript
export const variables = {
  'background-primary': 'var(--background-primary)',
  'text-and-icon-primary': 'var(--text-and-icon-primary)',
} as const;
```

#### Scenario: Export colors to JSON tokens

- **GIVEN** a YAML config with `web.colors[].jsonFileName: "theme.json"`
- **AND** Figma Variables contain color tokens with primitives, light, and dark modes
- **WHEN** `exfig colors` is executed
- **THEN** a JSON file is generated with `{ "primitives": {...}, "light": {...}, "dark": {...} }` structure

#### Scenario: Web colors config not present

- **GIVEN** a YAML config without `web.colors` section
- **WHEN** `exfig colors` is executed
- **THEN** no web color files are generated
- **AND** other platform exports proceed normally

### Requirement: Web Icons Export

The system SHALL export Figma icons to React TSX components and raw SVG files when `web.icons` configuration is present.

#### Scenario: Export icons as React components

- **GIVEN** a YAML config with `web.icons[].generateReactComponents: true`
- **AND** Figma frame "Icons" contains SVG components
- **WHEN** `exfig icons` is executed
- **THEN** TSX files are generated with SVGR pattern for each icon
- **AND** each component accepts `size`, `color`, and standard SVG props
- **AND** component names are PascalCase (e.g., `ArrowLeft.tsx`)

#### Scenario: Export raw SVG files

- **GIVEN** a YAML config with `web.icons[].svgDirectory: "assets/icons"`
- **AND** Figma frame contains SVG icons
- **WHEN** `exfig icons` is executed
- **THEN** raw SVG files are saved to the specified directory
- **AND** file names are kebab-case (e.g., `arrow-left.svg`)

#### Scenario: Generate icons index file

- **GIVEN** a YAML config with `web.icons[].generateIndex: true`
- **AND** multiple icons are exported
- **WHEN** `exfig icons` is executed
- **THEN** an `index.ts` file is generated with re-exports for all icons
- **AND** a `types.ts` file is generated with `SVGProps` interface

#### Scenario: SVG-to-TSX transformation

- **GIVEN** an SVG icon with HTML attributes (`class`, `fill-rule`, `stroke-width`)
- **WHEN** the icon is exported as React component
- **THEN** HTML attributes are converted to JSX (`className`, `fillRule`, `strokeWidth`)
- **AND** `width` and `height` are replaced with `{size}` prop
- **AND** static fill colors are replaced with `{color}` prop (default: `currentColor`)

**Default React component format (web-ui/mireska compatible):**

```tsx
import React from 'react';
import SVGProps from './types';

const Add = (props: SVGProps): JSX.Element => {
  const { color = 'currentColor', size, style } = props;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={style}
      {...props}
    >
      <path d="M12 21C11.4477..." fill={color} />
    </svg>
  );
};
export { Add };
```

### Requirement: Web Images Export

The system SHALL export Figma images/illustrations to React TSX components and raw image files when `web.images`
configuration is present.

#### Scenario: Export images as React components

- **GIVEN** a YAML config with `web.images[].generateReactComponents: true`
- **AND** Figma frame "Illustrations" contains image components
- **WHEN** `exfig images` is executed
- **THEN** TSX files are generated for each image
- **AND** components preserve original dimensions from Figma

#### Scenario: Export raw image files

- **GIVEN** a YAML config with `web.images[].assetsDirectory: "assets/illustrations"`
- **AND** Figma frame contains PNG or SVG images
- **WHEN** `exfig images` is executed
- **THEN** raw image files are saved to the specified directory
- **AND** file names follow configured naming style

#### Scenario: Generate images index file

- **GIVEN** a YAML config with `web.images[].generateIndex: true`
- **AND** multiple images are exported
- **WHEN** `exfig images` is executed
- **THEN** an `index.ts` file is generated with re-exports for all images

### Requirement: Web Platform Configuration

The system SHALL support `web:` configuration section in YAML config following the same patterns as `ios:`, `android:`,
and `flutter:` sections.

#### Scenario: Multiple colors configurations

- **GIVEN** a YAML config with `web.colors` as an array of entries
- **AND** each entry has different `tokensFileId` or `tokensCollectionName`
- **WHEN** `exfig colors` is executed
- **THEN** all color configurations are processed
- **AND** output files are generated according to each entry's settings

#### Scenario: Multiple icons configurations

- **GIVEN** a YAML config with `web.icons` as an array of entries
- **AND** each entry has different `figmaFrameName`
- **WHEN** `exfig icons` is executed
- **THEN** icons from all configured frames are exported
- **AND** each frame's output is placed in its configured directory

#### Scenario: Web config with custom templates

- **GIVEN** a YAML config with `web.templatesPath: "./custom-templates"`
- **AND** custom Jinja2 templates exist at the specified path
- **WHEN** export commands are executed
- **THEN** custom templates are used instead of built-in templates

### Requirement: React Component Types

The system SHALL generate TypeScript type definitions for React components that enable type-safe usage.

#### Scenario: SVGProps type definition

- **GIVEN** icons are exported with `generateReactComponents: true`
- **WHEN** `types.ts` is generated
- **THEN** it exports `SVGProps` interface extending `SVGAttributes<SVGElement>`
- **AND** it includes optional `size?: number | string` property
- **AND** it includes optional `color?: string` property
- **AND** it includes optional `style?: CSSProperties` property

**Default types.ts format (web-ui compatible):**

```typescript
import { SVGAttributes, CSSProperties } from 'react';

interface SVGProps extends SVGAttributes<SVGElement> {
  size?: number | string;
  color?: string;
  style?: CSSProperties;
}

export default SVGProps;
```

#### Scenario: Generate barrel index.ts

- **GIVEN** icons are exported with `generateIndex: true`
- **AND** multiple icons are generated (e.g., Add.tsx, ArrowLeft.tsx)
- **WHEN** `index.ts` is generated
- **THEN** it exports all icons using `export * from './icon-name'` pattern

**Default index.ts format (web-ui compatible):**

```typescript
export * from './add';
export * from './arrow-left';
export * from './close';
```

#### Scenario: ColoredSVGProps type definition

- **GIVEN** colored icons are exported
- **WHEN** `types.ts` is generated
- **THEN** it exports `ColoredSVGProps` interface extending `SVGProps`
- **AND** it includes optional `primaryColor` and `secondaryColor` properties
