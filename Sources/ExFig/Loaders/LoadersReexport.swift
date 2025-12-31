// Re-export all loader types from ExFigKit for backward compatibility.
// The actual implementations now live in ExFigKit to allow GUI app to use them.

@_exported import ExFigKit

// Note: The following types are now available from ExFigKit:
// - ImageLoaderBase
// - IconsLoader, IconsLoaderConfig, IconsLoaderOutput, IconsLoaderResultWithHashes
// - ImagesLoader, ImagesLoaderConfig, ImagesLoaderFormat, ImagesSourceFormat, ImagesLoaderOutput,
// ImagesLoaderResultWithHashes
// - ColorsLoader, ColorsLoaderOutput
// - ColorsVariablesLoader
// - TextStylesLoader
// - GranularCacheProvider, GranularCacheFilterResult
// - ComponentsProvider, ComponentsProviderStorage
// - NodesProvider, NodesProviderStorage
// - ImageLoaderResult
