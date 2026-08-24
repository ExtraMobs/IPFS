---
test-group: services
generated: 2026-08-24T09:15:13.519118
---

# `test/services/`

## `test/services/block_store_service_test.dart`

- BlockStoreService
- addBlock delegates to blockstore
- getBlock delegates to blockstore
- removeBlock delegates to blockstore
- getAllBlocks delegates to blockstore

## `test/services/block_store_service_test.mocks.dart`


## `test/services/content_service_test.dart`

- ContentService
- store and get content
- pin and unpin
- remove content blocked by pin
- getContentSize
- hasContent
- getContent returns null on error
- removeContent success when not pinned
- removeContent returns false on error
- pinContent returns false on error
- unpinContent returns false on error
- getContentSize returns null when content not found
- computeHash
- listPinnedContent empty

## `test/services/content_service_test.mocks.dart`


## `test/services/gateway/acme_client_test.dart`

- AcmeClient
- fetches directory and registers account
- creates order for domain
- gets HTTP-01 challenge from authorization
- full issuance flow with mock server
- throws when ToS not agreed
- LetsEncryptAutoTlsProvider
- exposes pendingChallenges map
- refuses without ToS acceptance
- refuses without domain
- refuses without email
- staging uses staging directory URL
- dispose clears state
- GatewayTlsManager activeAutoTlsProvider
- returns provider when LetsEncryptAutoTlsProvider is set
- returns null for custom provider

## `test/services/gateway/acme_integration_test.dart`

- ACME Integration Tests
- AcmePersistence creates and loads account key
- AcmePersistence checks certificate validity
- DomainValidator validates domain structure
- LetsEncryptAutoTlsProvider requires ToS acceptance
- LetsEncryptAutoTlsProvider requires domain
- LetsEncryptAutoTlsProvider requires email
- AcmeClient can be created with staging URL
- AcmeClient can be created with production URL
- GatewayConfig has ACME persistence fields
- GatewayConfig serializes ACME persistence fields
- GatewayConfig deserializes ACME persistence fields
- ACME Staging Integration (Manual)
- Full ACME flow with staging server - MANUAL

## `test/services/gateway/acme_persistence_test.dart`

- AcmePersistence
- save and load certificate roundtrip
- hasValidCertificate returns true for non-expired cert
- hasValidCertificate returns false when expired
- needsRenewal returns false when far from expiry
- needsRenewal returns true within threshold
- needsRenewal returns true when metadata missing
- load returns null for missing files
- saveAccountKeyPem and loadAccountKeyPem roundtrip
- loadAccountKey returns null and saveAccountKey throws
- deleteAll removes files and directory
- loadCertificate returns null when file is not readable
- loadPrivateKey returns null when file is not readable
- loadMetadata returns null when JSON is invalid
- loadAccountKeyPem returns null when file is not readable
- deleteAll ignores directory deletion errors

## `test/services/gateway/adaptive_compression_handler_test.dart`

- AdaptiveCompressionHandler
- getOptimalCompression selects correct type
- compressBlock returns original if disabled
- compressBlock compresses text content
- compressBlock skips compression if not beneficial

## `test/services/gateway/adaptive_compression_handler_test.mocks.dart`


## `test/services/gateway/compressed_cache_store_test.dart`

- CompressedCacheStore
- storeCompressedData stores data and metadata
- getCompressedData retrieves and decompresses data
- getCompressedData returns null for missing file
- initialization creates directory if missing
- CompressionStats calculates compression ratio
- CompressionStats handles zero original size
- getCompressionStats returns empty stats for empty directory
- storeCompressedData with small data uses no compression
- storeCompressedData with different content types
- getCompressedData handles corrupted metadata
- getCompressionStats handles corrupted metadata files
- CompressionStats handles division by zero
- getCompressedData handles missing metadata
- multiple stores and retrieves
- storeCompressedData with empty data
- storeCompressedData with binary data
- CompressionStats with large values
- storeCompressedData overwrites existing data
- getCompressedData with same CID different content type

## `test/services/gateway/content_type_handler_test.dart`

- ContentTypeHandler
- Detection
- detectContentType detects known signatures
- detectContentType detects directory
- detectContentType falls back to octet-stream
- detectContentType detects text
- detectContentType favors filename
- Processing
- processContent renders markdown
- processContent passes through CAR files
- processContent calls pass-through for unknown types
- cacheContentType stores in memory
- processContent handles text/html pass-through
- Path Extraction
- extractPathFromRequest handles ipfs prefix
- extractPathFromRequest handles null context

## `test/services/gateway/directory_parser_test.dart`

- DirectoryHandler
- addEntry and listEntries
- listEntries returns unmodifiable list
- DirectoryEntry
- constructor initializes all fields
- metadata can be null
- DirectoryParser
- parseDirectoryBlock throws on non-dag-pb codec
- generateHtmlListing includes header
- generateHtmlListing includes parent link for non-root paths
- generateHtmlListing does not include parent link for root
- generateHtmlListing sorts directories before files
- generateHtmlListing formats size correctly
- generateHtmlListing includes metadata tooltip
- parseDirectoryBlock with HAMTShard type
- parseDirectoryBlock throws on invalid PBNode
- parseDirectoryBlock throws on non-Directory UnixFS type
- _formatSize handles different units
- _getFileType handles various extensions
- _getIcon returns default for unknown type
- generateHtmlListing formats date correctly
- generateHtmlListing with empty directory
- parseDirectoryBlock with empty links
- parseDirectoryBlock with multiple links
- parseDirectoryBlock with link without name
- generateHtmlListing with special characters in names
- generateHtmlListing with nested path
- generateHtmlListing with very large file

## `test/services/gateway/domain_validator_test.dart`

- DomainValidator
- toString formats result
- getPublicIp returns IP on success
- getPublicIp returns null on non-200
- getPublicIp returns null on exception
- checkHttpAccessibility succeeds on HTTP response

## `test/services/gateway/file_preview_handler_test.dart`

- FilePreviewHandler
- generatePreview returns null for unsupported type
- generatePreview returns null for too large file
- generateImagePreview generates valid base64 image tag
- generateTextPreview handles JSON and escapes XSS
- generateTextPreview formats Markdown correctly

## `test/services/gateway/gateway_content_handler_test.dart`

- GatewayContentHandler
- serveContent
- returns 404 when block not found
- serves raw block when not UnixFS
- serves UnixFS file with correct content type
- serves directory listing for UnixFS directory
- serveContent with range requests
- handles range request on raw block
- returns 416 for invalid range format
- returns 416 for range beyond data length
- handles open-ended range (start only)
- getBlockByCid
- returns block from blockstore when found
- returns null when block not found and no bitswap
- handles blockstore exception gracefully
- resolveSubPath
- returns root block when subPath is empty
- returns null block when root not found
- index.html resolution
- serves index.html content when directory contains it
- HAMT directory rendering
- renders directory listing for HAMT shard root
- resolves sub-path in HAMT-sharded directory

## `test/services/gateway/gateway_content_handler_test.mocks.dart`


## `test/services/gateway/gateway_directory_handler_test.dart`

- GatewayDirectoryHandler
- renderDirectory
- renders HTML with correct title and headers
- renders links for directory entries
- escapes HTML in file names to prevent XSS
- formats sizes correctly
- navigateDirectory
- returns 404 when path not found
- calls serveContentCallback for matching link
- passes remaining path to callback for nested navigation
- findChildCid
- returns null for non-dag-pb codec
- returns CID for matching link name
- returns null when link name does not match
- returns null for invalid DAG-PB data
- renderDirectory extras
- includes parent directory link when parentPath is provided
- findIndexHtml returns CID for index.html child
- findIndexHtml returns null when no index.html child
- HAMT directory navigation
- findChildCid resolves entry in HAMT-sharded directory
- findChildCid returns null for missing HAMT entry
- navigateDirectory resolves HAMT sub-path

## `test/services/gateway/gateway_handler_test.dart`

- GatewayHandler
- handlePath ipfs root content
- handlePath ipns
- handleSubdomain
- range request
- handlePath invalid path
- handlePath ipns disabled
- handlePath ipns resolution failure
- handleSubdomain missing host header
- handleSubdomain invalid subdomain
- handleSubdomain block not found
- handlePath block not found
- range request invalid format
- range request out of bounds
- handlePath with storage error
- range request with only start
- handlePath with trailing slash
- handlePath with path segments

## `test/services/gateway/gateway_handler_test.mocks.dart`


## `test/services/gateway/gateway_handlers_test.dart`

- LazyPreviewHandler
- generateLazyPreview and getPreviewBlock
- getPreviewBlock throws on empty ID
- getPreviewBlock returns null for missing ID
- generateLazyLoadScript returns script
- generateLazyLoadStyles returns CSS
- validation: empty data block
- validation: CID mismatch
- CachedPreviewGenerator
- generatePreview - cache hit
- generatePreview - cache miss, generate success
- generatePreview - cache miss, generate fail
- preloadPreviews

## `test/services/gateway/gateway_handlers_test.mocks.dart`


## `test/services/gateway/gateway_helpers_test.dart`

- GatewayLruCache
- capacity check
- put/get/eviction
- clear
- ContentTypeHandler
- detectContentType from filename
- detectContentType from content
- processContent markdown
- DirectoryParser
- parseDirectoryBlock valid unixfs
- generateHtmlListing

## `test/services/gateway/gateway_lru_cache_test.dart`

- GatewayLruCache
- put and get
- eviction
- update moves to front
- clear and remove
- keys and values

## `test/services/gateway/gateway_server_test.dart`

- GatewayServer
- initial state
- start and stop success
- cannot start twice
- handles start failure
- routing - health check
- routing - version endpoint
- CORS middleware - OPTIONS request
- CORS middleware - regular request headers
- Rate limiting middleware
- HEAD request returns headers only
- Rate limiting middleware with X-Forwarded-For
- routing - ipns support
- routing - /metrics returns Prometheus text when enabled
- routing - /metrics returns 404 when disabled

## `test/services/gateway/gateway_services_test.dart`

- GatewayHandler
- should serve text file
- should return 404 for missing block
- should handle range request
- PersistentPreviewCache
- should cache and retrieve preview
- should evict old entries when cache is full
- CachedPreviewGenerator
- should generate and cache new preview
- should return cached preview if available

## `test/services/gateway/gateway_tls_manager_extra_test.dart`

- GatewayTlsManager manager methods
- markActive, markInactive, dispose and getters
- markActive without context throws
- autoTLS state defaults to idle when no provider
- LetsEncryptAutoTlsProvider
- initial state and dispose
- obtainCertificate with missing ToS throws
- obtainCertificate with missing domain throws
- obtainCertificate with missing email throws
- obtainCertificate falls back to ACME when no valid cert

## `test/services/gateway/gateway_tls_test.dart`

- GatewayConfig TLS fields
- round-trip through JSON
- defaults are off
- GatewayTlsManager
- throws when TLS is not enabled
- throws when certificate files are missing
- loads SecurityContext from PEM files and extracts expiry
- refuses AutoTLS without ToS acceptance
- obtains AutoTLS certificate when ToS is accepted
- GatewayServer TLS
- binds HTTPS when enableTls is true
- starts HTTP redirect server when redirectHttpToHttps is true
- binds plain HTTP when TLS is disabled
- uses AutoTLS provider when autoTls is true
- WSS route requires upgrade headers

## `test/services/gateway/gateway_trustless_handler_test.dart`

- GatewayTrustlessHandler
- detectTrustlessFormat
- detects raw from ?format=raw
- detects car from ?format=car
- detects dag-json from ?format=dag-json
- detects dag-cbor from ?format=dag-cbor
- detects ipns-record from ?format=ipns-record
- returns null for unknown format
- detects from Accept header
- ?format= takes precedence over Accept header
- returns null when no format specified
- parses Accept header with q-values
- serveRawBlock
- serves raw block with correct headers
- returns 404 when block not found
- sets X-IPFS-Path from ipnsPath when provided
- serveDagJson
- serves raw codec as DAG-JSON
- returns 404 when block not found
- serveDagCbor
- serves raw codec as DAG-CBOR
- returns 404 when block not found
- serveIpnsRecord
- returns 501 when no resolver configured
- returns 404 when record not found
- returns 404 when record is empty
- serves record with correct content type
- serveTrustless dispatch
- dispatches to raw block for raw format
- returns 400 for ipns-record format on /ipfs/ path
- checkDenylist
- returns null when no denylist service configured
- returns 451 when content is blocked

## `test/services/gateway/gateway_trustless_handler_test.mocks.dart`


## `test/services/gateway/preview_cache_manager_test.dart`

- PreviewCacheManager
- returns null for uncached preview
- caches and retrieves preview
- returns correct cache stats
- memory cache is used for repeated requests
- different content types are cached separately
- cache stats updates correctly

## `test/services/gateway/subdomain_gateway_test.dart`

- SubdomainGateway
- host parsing
- localhost ipfs subdomain is detected
- localhost ipns subdomain is detected
- configured domain ipfs subdomain is detected
- bare configured domain is not a subdomain
- unconfigured production domain is not a subdomain
- CID validation
- valid CIDv1 base32 is accepted
- CIDv0 is converted to CIDv1 base32
- invalid CID label returns 400
- IPNS resolution
- peer-id ipns subdomain resolves via ipnsResolver
- DNSLink ipns subdomain resolves via dnsLinkResolver
- DNSLink /ipns path is recursively resolved
- missing IPNS resolver for DNS-like name returns 400/502
- trustless negotiation
- ?format=raw on subdomain returns raw block
- Accept car on subdomain returns CAR archive
- denylist
- blocked CID returns 451
- blocked IPNS name returns 451 before resolution
- CORS headers
- subdomain response sets Access-Control-Allow-Origin: *
- TLS redirect
- http request is redirected to HTTPS when enabled
- TLS redirect never triggers for localhost
- GatewayServer integration
- subdomain request is routed before path gateway
- bare gateway domain falls back to path gateway

## `test/services/gateway/trustless_gateway_test.dart`

- TrustlessGateway
- format detection
- ?format=raw takes precedence over Accept text/html
- Accept header selects raw-block when no ?format
- unsupported Accept falls back to path gateway
- ?format=raw
- returns raw block bytes
- uses Bitswap fallback when block is missing locally
- returns 404 when block is missing and Bitswap fails
- ?format=car
- returns CAR archive with correct root CID
- uses Bitswap fallback for missing root block
- ?format=dag-json
- returns DAG-JSON for raw block
- ?format=dag-cbor
- returns DAG-CBOR for raw block
- ?format=ipns-record
- returns signed record bytes via resolver
- returns default TTL when record TTL is missing
- returns 501 when resolver is disabled
- subdomain gateway
- detects trustless format in subdomain request
- denylist
- returns 451 for blocked CID with ?format=raw
- returns 451 for blocked CID via path
- returns 451 for blocked IPNS name

## `test/services/gateway/trustless_gateway_test.mocks.dart`


## `test/services/gateway_test.dart`

- GatewayHandler
- handlePath returns 404 for missing block
- handlePath serves raw block if not UnixFS
- handlePath serves UnixFS File
- handlePath serves range request
- handlePath renders Directory
- handlePath navigates directory to subpath
- handlePath resolves IPNS name
- handlePath returns 404 for unknown IPNS name

## `test/services/general_services_test.dart`

- BlockStoreService
- ContentService with MockDatastore
- store and get content via datastore
- pin content via key prefix
- GatewayServer
- start/stop

## `test/services/pinning/cluster_client_test.dart`

- IPFSClusterClient
- pin sends POST and parses response
- unpin sends DELETE
- unpin throws on error
- status gets pin info
- listPins returns list of pins
- listPins handles map response with pins key
- recover sends POST and returns pin status
- listPeers returns cluster peers
- health returns cluster health
- version returns cluster version
- sync sends POST and returns pin status
- statusAll returns all pin statuses
- ClusterPinStatus fromString roundtrip
- ReplicationFactor values
- ClusterPinOptions toJson
- ClusterPin toJson
- ClusterPeerInfo fromJson
- ClusterPeer fromJson
- ClusterHealth fromJson
- dispose closes client
- basic auth credentials

## `test/services/pinning/cluster_client_test.mocks.dart`


## `test/services/pinning/remote_pinning_service_manager_test.dart`

- RemotePinningService manager
- addService, hasService, listServices and getClient
- addService duplicate throws
- removeService removes and throws for missing
- load and listRemotePins filter
- save persists services and pins
- services getter returns registered configs
- dispose clears clients

## `test/services/pinning/remote_pinning_service_test.dart`

- PinningServiceAPIClient
- addPin sends POST and parses response
- addPin handles error response
- getPin sends GET and parses response
- listPins sends GET with query params
- removePin sends DELETE
- removePin throws on error
- replacePin sends POST with mode=replace
- PinStatus fromString and toApiString roundtrip
- PinRequest toJson includes optional fields
- PinRequest toJson excludes empty optional fields
- PinListFilter toQueryParams
- PinListFilter with meta params
- PinObject fromJson and toJson
- PinStatusResponse fromJson
- PinListResponse fromJson
- PinningServiceError fromJson
- dispose closes client
- RemotePinningService
- addService registers a new service
- addService throws on duplicate name
- removeService removes a registered service
- removeService throws on unknown service
- listServices returns service configs
- getClient throws on unknown service
- listRemotePins filters by service name
- PinningServiceConfig toJson and fromJson
- RemotePin toJson
- load and save config

## `test/services/pinning/remote_pinning_service_test.mocks.dart`


## `test/services/rpc/mfs_handlers_test.dart`

- MFSHandlers
- handleFilesLs returns entries and hash
- handleFilesLs error path
- handleFilesStat returns full stat
- handleFilesStat hash only flag
- handleFilesStat error path
- handleFilesRead returns octet stream
- handleFilesRead missing path
- handleFilesRead invalid offset/count
- handleFilesRead error path
- handleFilesWrite success with multipart
- handleFilesWrite missing path
- handleFilesWrite invalid offset
- handleFilesWrite invalid cid-version
- handleFilesWrite missing content-type
- handleFilesWrite invalid content-type
- handleFilesWrite empty multipart
- handleFilesWrite error path
- handleFilesMkdir success
- handleFilesMkdir missing path
- handleFilesMkdir invalid cid-version
- handleFilesMkdir error path
- handleFilesCp success
- handleFilesCp missing args
- handleFilesCp blocked path returns 451
- handleFilesCp blocked path log action proceeds
- handleFilesCp denylist disabled
- handleFilesCp error path
- handleFilesMv success
- handleFilesMv blocked path
- handleFilesMv missing args
- handleFilesMv error path
- handleFilesRm success
- handleFilesRm missing path
- handleFilesRm error path
- handleFilesFlush success
- handleFilesFlush error path
- handleFilesChcid success
- handleFilesChcid missing path
- handleFilesChcid invalid cid-version
- handleFilesChcid error path

## `test/services/rpc/rpc_handlers_test.dart`

- RPCHandlers
- handleVersion
- handleId
- handleCat
- handleSwarmPeers
- handleBlockGet success
- handleDhtProvide
- handleAdd success
- handleAdd multiple files
- handleAdd no files
- handleAdd no filename
- handleLs success
- handleLs missing arg
- handleDagGet success
- handleDagGet not found
- handleDhtFindProviders
- handleDhtFindPeer success
- handleNamePublish
- handleNameResolve
- handleSwarmConnect
- handleBlockPut
- handleBlockStat success
- handleSwarmDisconnect success
- handleGet returns 501
- handleDagPut returns 501
- handleId error
- handleCat missing arg
- handleAdd missing content-type
- handleAdd invalid boundary
- handleLs error
- handleDhtFindPeer not found
- handleBlockGet missing arg
- handleBlockGet not found
- handleDagGet missing arg
- handleDhtFindProviders missing arg
- handleDhtProvide missing arg
- handleNamePublish missing arg
- handleNameResolve missing arg
- handleSwarmConnect missing arg
- handleSwarmDisconnect missing arg
- handleBlockStat missing arg
- handleBlockStat not found
- handleDhtFindProviders error
- handleDhtProvide error
- handleNamePublish error
- handleNameResolve error
- handleSwarmConnect error
- handleSwarmDisconnect error
- handleBlockPut error
- handleBlockStat error

## `test/services/rpc/rpc_handlers_test.mocks.dart`


## `test/services/rpc/rpc_server_test.dart`

- RPCServer
- should return version details
- should return node ID
- should require API key for protected endpoints
- should allow protected endpoints with valid API key
- should reject invalid API key
- should expose /metrics as Prometheus text

## `test/services/rpc_handlers_test.dart`

- RPCHandlers
- handleVersion returns version info
- handleId returns identity info
- handleCat retrieves content
- handleLs lists directory
- handleBlockPut stores block
- handleBlockGet retrieves block
- handleDhtFindProviders
- handleAdd accepts multipart upload
- handleSwarmPeers

