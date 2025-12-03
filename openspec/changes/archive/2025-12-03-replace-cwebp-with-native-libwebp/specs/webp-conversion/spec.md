# WebP Conversion Capability

## ADDED Requirements

### Requirement: Native PNG to WebP Conversion

The system SHALL convert PNG images to WebP format using the native libwebp library without requiring external binaries.

#### Scenario: Lossless WebP encoding

- **GIVEN** a valid PNG file exists at the input path
- **WHEN** the user requests lossless WebP conversion
- **THEN** the system creates a WebP file with `.webp` extension
- **AND** the output file contains valid WebP data (RIFF/WEBP magic bytes)
- **AND** the original PNG file is preserved

#### Scenario: Lossy WebP encoding with quality

- **GIVEN** a valid PNG file exists at the input path
- **WHEN** the user requests lossy WebP conversion with quality 80
- **THEN** the system creates a WebP file with `.webp` extension
- **AND** the output file size is smaller than lossless equivalent
- **AND** the output file contains valid WebP data

#### Scenario: Batch conversion with progress

- **GIVEN** multiple PNG files exist in the input directory
- **WHEN** the user requests batch WebP conversion
- **THEN** the system converts all files in parallel (up to maxConcurrent limit)
- **AND** the progress callback is invoked after each file completes
- **AND** all output files are created successfully

### Requirement: PNG Decoding

The system SHALL decode PNG images to RGBA pixel data using the native libpng library.

#### Scenario: Decode standard PNG

- **GIVEN** a valid PNG file with RGBA color type
- **WHEN** the system decodes the PNG
- **THEN** the decoder returns width, height, and RGBA byte array
- **AND** the byte array length equals width * height * 4

#### Scenario: Decode PNG without alpha

- **GIVEN** a valid PNG file with RGB color type (no alpha)
- **WHEN** the system decodes the PNG
- **THEN** the decoder converts to RGBA format
- **AND** the alpha channel is set to 255 (fully opaque)

#### Scenario: Invalid PNG handling

- **GIVEN** an invalid or corrupted PNG file
- **WHEN** the system attempts to decode the PNG
- **THEN** the decoder throws `PngDecoderError.invalidFormat`
- **AND** no partial output is created

### Requirement: WebP Encoding

The system SHALL encode RGBA pixel data to WebP format using the native libwebp library.

#### Scenario: Encode RGBA to lossless WebP

- **GIVEN** valid RGBA pixel data with known dimensions
- **WHEN** the encoder processes the data in lossless mode
- **THEN** the encoder returns WebP byte array
- **AND** the output begins with RIFF/WEBP signature

#### Scenario: Encode RGBA to lossy WebP

- **GIVEN** valid RGBA pixel data with known dimensions
- **WHEN** the encoder processes the data with quality factor (0-100)
- **THEN** the encoder returns compressed WebP byte array
- **AND** higher quality produces larger output size

#### Scenario: Invalid dimensions handling

- **GIVEN** RGBA data with invalid dimensions (width=0 or height=0)
- **WHEN** the encoder attempts to process the data
- **THEN** the encoder throws `NativeWebpEncoderError.invalidDimensions`

### Requirement: Error Handling

The system SHALL provide clear, actionable error messages for WebP conversion failures.

#### Scenario: File not found

- **GIVEN** a non-existent input file path
- **WHEN** the user requests WebP conversion
- **THEN** the system throws `WebpConverterError.fileNotFound`
- **AND** the error message includes the missing file path

#### Scenario: Invalid input format

- **GIVEN** an input file that is not a valid PNG
- **WHEN** the user requests WebP conversion
- **THEN** the system throws `WebpConverterError.invalidInputFormat`
- **AND** the error message indicates the file is not a valid PNG

#### Scenario: Encoding failure

- **GIVEN** a valid PNG file
- **WHEN** WebP encoding fails for any reason
- **THEN** the system throws `WebpConverterError.encodingFailed`
- **AND** the error message includes details about the failure

## REMOVED Requirements

### Requirement: External cwebp Binary Support

**Reason**: Replaced by native libwebp integration. External binary discovery, `CWEBP_PATH` environment variable, and
Process-based conversion are no longer needed.

**Migration**: Users should remove `CWEBP_PATH` from their environment. No other action required - WebP conversion works
automatically with the native implementation.
