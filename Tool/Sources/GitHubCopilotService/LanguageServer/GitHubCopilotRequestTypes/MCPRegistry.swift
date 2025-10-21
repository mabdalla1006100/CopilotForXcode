import Foundation
import JSONRPC
import ConversationServiceProvider

/// Schema definitions for MCP Registry API based on the OpenAPI spec:
/// https://github.com/modelcontextprotocol/registry/blob/main/docs/reference/api/openapi.yaml

// MARK: - Repository

public struct Repository: Codable {
    public let url: String
    public let source: String
    public let id: String?
    public let subfolder: String?
    
    public init(url: String, source: String, id: String?, subfolder: String?) {
        self.url = url
        self.source = source
        self.id = id
        self.subfolder = subfolder
    }

    enum CodingKeys: String, CodingKey {
        case url, source, id, subfolder
    }
}

// MARK: - Server Status

public enum ServerStatus: String, Codable {
    case active
    case deprecated
}

// MARK: - Base Input Protocol

public protocol InputProtocol: Codable {
    var description: String? { get }
    var isRequired: Bool? { get }
    var format: ArgumentFormat? { get }
    var value: String? { get }
    var isSecret: Bool? { get }
    var defaultValue: String? { get }
    var choices: [String]? { get }
}

// MARK: - Input (base type)

public struct Input: InputProtocol {
    public let description: String?
    public let isRequired: Bool?
    public let format: ArgumentFormat?
    public let value: String?
    public let isSecret: Bool?
    public let defaultValue: String?
    public let choices: [String]?

    enum CodingKeys: String, CodingKey {
        case description
        case isRequired = "is_required"
        case format
        case value
        case isSecret = "is_secret"
        case defaultValue = "default"
        case choices
    }
}

// MARK: - Input with Variables

public struct InputWithVariables: InputProtocol {
    public let description: String?
    public let isRequired: Bool?
    public let format: ArgumentFormat?
    public let value: String?
    public let isSecret: Bool?
    public let defaultValue: String?
    public let choices: [String]?
    public let variables: [String: Input]?

    enum CodingKeys: String, CodingKey {
        case description
        case isRequired = "is_required"
        case format
        case value
        case isSecret = "is_secret"
        case defaultValue = "default"
        case choices
        case variables
    }
}

// MARK: - Argument Format

public enum ArgumentFormat: String, Codable {
    case string
    case number
    case boolean
    case filepath
}

// MARK: - Argument Type

public enum ArgumentType: String, Codable {
    case positional
    case named
}

// MARK: - Base Argument Protocol

public protocol ArgumentProtocol: InputProtocol {
    var type: ArgumentType { get }
    var variables: [String: Input]? { get }
}

// MARK: - Positional Argument

public struct PositionalArgument: ArgumentProtocol, Hashable {
    public let type: ArgumentType = .positional
    public let description: String?
    public let isRequired: Bool?
    public let format: ArgumentFormat?
    public let value: String?
    public let isSecret: Bool?
    public let defaultValue: String?
    public let choices: [String]?
    public let variables: [String: Input]?
    public let valueHint: String?
    public let isRepeated: Bool?

    enum CodingKeys: String, CodingKey {
        case type, description, format, value, choices, variables
        case isRequired = "is_required"
        case isSecret = "is_secret"
        case defaultValue = "default"
        case valueHint = "value_hint"
        case isRepeated = "is_repeated"
    }
    
    // Implement Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(description)
        hasher.combine(isRequired)
        hasher.combine(format)
        hasher.combine(value)
        hasher.combine(isSecret)
        hasher.combine(defaultValue)
        hasher.combine(choices)
        hasher.combine(valueHint)
        hasher.combine(isRepeated)
    }
    
    public static func == (lhs: PositionalArgument, rhs: PositionalArgument) -> Bool {
        lhs.type == rhs.type &&
        lhs.description == rhs.description &&
        lhs.isRequired == rhs.isRequired &&
        lhs.format == rhs.format &&
        lhs.value == rhs.value &&
        lhs.isSecret == rhs.isSecret &&
        lhs.defaultValue == rhs.defaultValue &&
        lhs.choices == rhs.choices &&
        lhs.valueHint == rhs.valueHint &&
        lhs.isRepeated == rhs.isRepeated
    }
}

// MARK: - Named Argument

public struct NamedArgument: ArgumentProtocol, Hashable {
    public let type: ArgumentType = .named
    public let name: String?
    public let description: String?
    public let isRequired: Bool?
    public let format: ArgumentFormat?
    public let value: String?
    public let isSecret: Bool?
    public let defaultValue: String?
    public let choices: [String]?
    public let variables: [String: Input]?
    public let isRepeated: Bool?

    enum CodingKeys: String, CodingKey {
        case type, name, description, format, value, choices, variables
        case isRequired = "is_required"
        case isSecret = "is_secret"
        case defaultValue = "default"
        case isRepeated = "is_repeated"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(isRequired)
        hasher.combine(format)
        hasher.combine(value)
        hasher.combine(isSecret)
        hasher.combine(defaultValue)
        hasher.combine(choices)
        hasher.combine(isRepeated)
    }
    
    public static func == (lhs: NamedArgument, rhs: NamedArgument) -> Bool {
        lhs.type == rhs.type &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.isRequired == rhs.isRequired &&
        lhs.format == rhs.format &&
        lhs.value == rhs.value &&
        lhs.isSecret == rhs.isSecret &&
        lhs.defaultValue == rhs.defaultValue &&
        lhs.choices == rhs.choices &&
        lhs.isRepeated == rhs.isRepeated
    }
}

// MARK: - Argument Enum

public enum Argument: Codable, Hashable {
    case positional(PositionalArgument)
    case named(NamedArgument)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Discriminator.self)
        let type = try container.decode(ArgumentType.self, forKey: .type)
        switch type {
        case .positional:
            self = .positional(try PositionalArgument(from: decoder))
        case .named:
            self = .named(try NamedArgument(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .positional(let arg):
            try arg.encode(to: encoder)
        case .named(let arg):
            try arg.encode(to: encoder)
        }
    }

    private enum Discriminator: String, CodingKey {
        case type
    }
}

// MARK: - KeyValueInput

public struct KeyValueInput: InputProtocol, Hashable {
    public let name: String?
    public let description: String?
    public let isRequired: Bool?
    public let format: ArgumentFormat?
    public let value: String?
    public let isSecret: Bool?
    public let defaultValue: String?
    public let choices: [String]?
    public let variables: [String: Input]?
    
    public init(
        name: String,
        description: String?,
        isRequired: Bool?,
        format: ArgumentFormat?,
        value: String?,
        isSecret: Bool?,
        defaultValue: String?,
        choices: [String]?,
        variables: [String : Input]?
    ) {
        self.name = name
        self.description = description
        self.isRequired = isRequired
        self.format = format
        self.value = value
        self.isSecret = isSecret
        self.defaultValue = defaultValue
        self.choices = choices
        self.variables = variables
    }

    enum CodingKeys: String, CodingKey {
        case name, description, format, value, choices, variables
        case isRequired = "is_required"
        case isSecret = "is_secret"
        case defaultValue = "default"
    }
    
    // Implement Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(isRequired)
        hasher.combine(format)
        hasher.combine(value)
        hasher.combine(isSecret)
        hasher.combine(defaultValue)
        hasher.combine(choices)
        // Note: variables is excluded as Input would also need to be Hashable
    }
    
    public static func == (lhs: KeyValueInput, rhs: KeyValueInput) -> Bool {
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.isRequired == rhs.isRequired &&
        lhs.format == rhs.format &&
        lhs.value == rhs.value &&
        lhs.isSecret == rhs.isSecret &&
        lhs.defaultValue == rhs.defaultValue &&
        lhs.choices == rhs.choices
        // Note: variables is excluded as Input would also need to be Hashable
    }
}

// MARK: - Package

public struct Package: Codable, Hashable {
    public let registryType: String?
    public let registryBaseURL: String?
    public let identifier: String?
    public let version: String?
    public let fileSHA256: String?
    public let runtimeHint: String?
    public let runtimeArguments: [Argument]?
    public let packageArguments: [Argument]?
    public let environmentVariables: [KeyValueInput]?
    
    public init(
        registryType: String?,
        registryBaseURL: String?,
        identifier: String?,
        version: String?,
        fileSHA256: String?,
        runtimeHint: String?,
        runtimeArguments: [Argument]?,
        packageArguments: [Argument]?,
        environmentVariables: [KeyValueInput]?
    ) {
        self.registryType = registryType
        self.registryBaseURL = registryBaseURL
        self.identifier = identifier
        self.version = version
        self.fileSHA256 = fileSHA256
        self.runtimeHint = runtimeHint
        self.runtimeArguments = runtimeArguments
        self.packageArguments = packageArguments
        self.environmentVariables = environmentVariables
    }

    enum CodingKeys: String, CodingKey {
        case version, identifier
        case registryType = "registry_type"
        case registryBaseURL = "registry_base_url"
        case fileSHA256 = "file_sha256"
        case runtimeHint = "runtime_hint"
        case runtimeArguments = "runtime_arguments"
        case packageArguments = "package_arguments"
        case environmentVariables = "environment_variables"
    }
}

// MARK: - Transport Type

public enum TransportType: String, Codable {
    case streamableHttp = "streamable-http"
    case http = "http"
    case sse = "sse"
    
    public var displayText: String {
        switch self {
        case .streamableHttp:
            return "Streamable HTTP"
        case .http:
            return "HTTP"
        case .sse:
            return "SSE"
        }
    }
}

// MARK: - Remote

public struct Remote: Codable, Hashable {
    public let transportType: TransportType
    public let url: String
    public let headers: [KeyValueInput]?
    
    public init(
        transportType: TransportType,
        url: String,
        headers: [KeyValueInput]?
    ) {
        self.transportType = transportType
        self.url = url
        self.headers = headers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try "transport_type" first, then fall back to "type"
        transportType = try container.decodeIfPresent(TransportType.self, forKey: .transportTypePreferred) 
                    ?? container.decode(TransportType.self, forKey: .transportType)
        
        url = try container.decode(String.self, forKey: .url)
        headers = try container.decodeIfPresent([KeyValueInput].self, forKey: .headers)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transportType, forKey: .transportTypePreferred)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(headers, forKey: .headers)
    }

    enum CodingKeys: String, CodingKey {
        case url, headers
        case transportType = "type"
        case transportTypePreferred = "transport_type"
    }
}

// MARK: - Publisher Provided Meta

public struct PublisherProvidedMeta: Codable {
    public let tool: String?
    public let version: String?
    public let buildInfo: BuildInfo?
    private let additionalProperties: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case tool, version
        case buildInfo = "build_info"
    }
    
    public init(
        tool: String?,
        version: String?,
        buildInfo: BuildInfo?,
        additionalProperties: [String: AnyCodable]? = nil
    ) {
        self.tool = tool
        self.version = version
        self.buildInfo = buildInfo
        self.additionalProperties = additionalProperties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tool = try container.decodeIfPresent(String.self, forKey: .tool)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        buildInfo = try container.decodeIfPresent(BuildInfo.self, forKey: .buildInfo)

        // Capture additional properties
        let allKeys = try decoder.container(keyedBy: AnyCodingKey.self)
        var extras: [String: AnyCodable] = [:]
        
        for key in allKeys.allKeys {
            if !["tool", "version", "build_info"].contains(key.stringValue) {
                extras[key.stringValue] = try allKeys.decode(AnyCodable.self, forKey: key)
            }
        }
        additionalProperties = extras.isEmpty ? nil : extras
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(tool, forKey: .tool)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(buildInfo, forKey: .buildInfo)

        if let additionalProperties = additionalProperties {
            var dynamicContainer = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in additionalProperties {
                try dynamicContainer.encode(value, forKey: AnyCodingKey(stringValue: key)!)
            }
        }
    }
}

public struct BuildInfo: Codable {
    public let commit: String?
    public let timestamp: String?
    public let pipelineID: String?
    
    public init(commit: String?, timestamp: String?, pipelineID: String?) {
        self.commit = commit
        self.timestamp = timestamp
        self.pipelineID = pipelineID
    }

    enum CodingKeys: String, CodingKey {
        case commit, timestamp
        case pipelineID = "pipeline_id"
    }
}

// MARK: - Official Meta

public struct OfficialMeta: Codable {
    public let id: String
    public let publishedAt: String
    public let updatedAt: String
    public let isLatest: Bool
    
    public init(
        id: String,
        publishedAt: String,
        updatedAt: String,
        isLatest: Bool
    ) {
        self.id = id
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.isLatest = isLatest
    }

    enum CodingKeys: String, CodingKey {
        case id
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
        case isLatest = "is_latest"
    }
}

// MARK: - Server Meta

public struct ServerMeta: Codable {
    public let publisherProvided: PublisherProvidedMeta?
    public let official: OfficialMeta?
    private let additionalProperties: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case publisherProvided = "io.modelcontextprotocol.registry/publisher-provided"
        case official = "io.modelcontextprotocol.registry/official"
    }
    
    public init(
        publisherProvided: PublisherProvidedMeta?,
        official: OfficialMeta?,
        additionalProperties: [String: AnyCodable]? = nil
    ) {
        self.publisherProvided = publisherProvided
        self.official = official
        self.additionalProperties = additionalProperties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        publisherProvided = try container.decodeIfPresent(PublisherProvidedMeta.self, forKey: .publisherProvided)
        official = try container.decodeIfPresent(OfficialMeta.self, forKey: .official)

        // Capture additional properties
        let allKeys = try decoder.container(keyedBy: AnyCodingKey.self)
        var extras: [String: AnyCodable] = [:]
        
        let knownKeys = ["io.modelcontextprotocol.registry/publisher-provided", "io.modelcontextprotocol.registry/official"]
        for key in allKeys.allKeys {
            if !knownKeys.contains(key.stringValue) {
                extras[key.stringValue] = try allKeys.decode(AnyCodable.self, forKey: key)
            }
        }
        additionalProperties = extras.isEmpty ? nil : extras
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(publisherProvided, forKey: .publisherProvided)
        try container.encodeIfPresent(official, forKey: .official)

        if let additionalProperties = additionalProperties {
            var dynamicContainer = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in additionalProperties {
                try dynamicContainer.encode(value, forKey: AnyCodingKey(stringValue: key)!)
            }
        }
    }
}

// MARK: - Dynamic Coding Key Helper

private struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Server Detail

public struct MCPRegistryServerDetail: Codable {
    public let name: String
    public let description: String
    public let status: ServerStatus?
    public let repository: Repository?
    public let version: String
    public let websiteURL: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let schemaURL: String?
    public let packages: [Package]?
    public let remotes: [Remote]?
    public let meta: ServerMeta?
    
    public init(
        name: String,
        description: String,
        status: ServerStatus?,
        repository: Repository?,
        version: String,
        websiteURL: String?,
        createdAt: String?,
        updatedAt: String?,
        schemaURL: String?,
        packages: [Package]?,
        remotes: [Remote]?,
        meta: ServerMeta?
    ) {
        self.name = name
        self.description = description
        self.status = status
        self.repository = repository
        self.version = version
        self.websiteURL = websiteURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.schemaURL = schemaURL
        self.packages = packages
        self.remotes = remotes
        self.meta = meta
    }

    enum CodingKeys: String, CodingKey {
        case name, description, status, repository, version, packages, remotes
        case websiteURL = "website_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case schemaURL = "$schema"
        case meta = "_meta"
    }
}

// MARK: - Server List Metadata

public struct MCPRegistryServerListMetadata: Codable {
    public let nextCursor: String?
    public let count: Int?

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case count
    }
}

// MARK: - Server List

public struct MCPRegistryServerList: Codable {
    public let servers: [MCPRegistryServerDetail]
    public let metadata: MCPRegistryServerListMetadata?
}

// MARK: - Request Parameters

public struct MCPRegistryListServersParams: Codable {
    public let baseUrl: String
    public let cursor: String?
    public let limit: Int?

    public init(baseUrl: String, cursor: String? = nil, limit: Int? = nil) {
        self.baseUrl = baseUrl
        self.cursor = cursor
        self.limit = limit
    }
}

public struct MCPRegistryGetServerParams: Codable {
    public let baseUrl: String
    public let id: String
    public let version: String?

    public init(baseUrl: String, id: String, version: String?) {
        self.baseUrl = baseUrl
        self.id = id
        self.version = version
    }
}
