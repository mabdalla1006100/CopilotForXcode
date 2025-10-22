import GitHubCopilotService
import SwiftUI
import SharedUIComponents

struct MCPRegistryURLInputField: View {
    @Binding var urlText: String
    @AppStorage(\.mcpRegistryURLHistory) private var urlHistory
    @State private var showHistory: Bool = false
    @FocusState private var isFocused: Bool
    
    let defaultMCPRegistryURL = "https://api.mcp.github.com/2025-09-15/v0/servers"
    let maxURLLength: Int
    let isSheet: Bool
    let mcpRegistryEntry: MCPRegistryEntry?
    let onValidationChange: ((Bool) -> Void)?
    
    private var isRegistryOnly: Bool {
        mcpRegistryEntry?.registryAccess == .registryOnly
    }
    
    init(
        urlText: Binding<String>,
        maxURLLength: Int = 2048,
        isSheet: Bool = false,
        mcpRegistryEntry: MCPRegistryEntry? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self._urlText = urlText
        self.maxURLLength = maxURLLength
        self.isSheet = isSheet
        self.mcpRegistryEntry = mcpRegistryEntry
        self.onValidationChange = onValidationChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if isSheet {
                    TextFieldsContainer {
                        TextField("MCP Registry URL", text: $urlText)
                            .focused($isFocused)
                            .disabled(isRegistryOnly)
                            .onChange(of: urlText) { newValue in
                                handleURLChange(newValue)
                            }
                    }
                } else {
                    TextField("MCP Registry URL:", text: $urlText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .disabled(isRegistryOnly)
                        .onChange(of: urlText) { newValue in
                            handleURLChange(newValue)
                        }
                }
                
                Menu {
                    ForEach(urlHistory, id: \.self) { url in
                        Button(url) {
                            urlText = url
                            isFocused = false
                        }
                    }
                    
                    Divider()
                    
                    Button("Reset to Default") {
                        urlText = defaultMCPRegistryURL
                    }
                    
                    if !urlHistory.isEmpty {
                        Button("Clear History") {
                            urlHistory = []
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .padding(isSheet ? 9 : 3)
                }
                .labelStyle(.iconOnly)
                .menuIndicator(.hidden)
                .buttonStyle(
                    HoverButtonStyle(
                        hoverColor: SecondarySystemFillColor,
                        backgroundColor: SecondarySystemFillColor,
                        cornerRadius: isSheet ? 12 : 6
                    )
                )
                .opacity(isRegistryOnly ? 0.5 : 1)
                .disabled(isRegistryOnly)
            }
            
            if isRegistryOnly {
                Badge(
                    text: "This URL is managed by \(mcpRegistryEntry!.owner.login) and cannot be modified",
                    level: .info,
                    icon: "info.circle.fill"
                )
            }
        }
        .onAppear {
            if isRegistryOnly, let entryURL = mcpRegistryEntry?.url {
                urlText = entryURL
            }
        }
        .onChange(of: mcpRegistryEntry) { newEntry in
            if newEntry?.registryAccess == .registryOnly, let entryURL = newEntry?.url {
                urlText = entryURL
            }
        }
    }
    
    private func handleURLChange(_ newValue: String) {
        // If registryOnly, force the URL back to the registry entry URL
        if isRegistryOnly, let entryURL = mcpRegistryEntry?.url {
            urlText = entryURL
            return
        }
        
        let limitedText = String(newValue.prefix(maxURLLength))
        if limitedText != newValue {
            urlText = limitedText
        }
        
        let isValid = limitedText.isEmpty || isValidURL(limitedText)
        onValidationChange?(isValid)
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard !string.isEmpty else { return true }
        return URL(string: string) != nil && (string.hasPrefix("http://") || string.hasPrefix("https://"))
    }
}

extension Array where Element == String {
    mutating func addToHistory(_ url: String, maxItems: Int = 10) {
        // Remove if already exists
        removeAll { $0 == url }
        // Add to beginning
        insert(url, at: 0)
        // Keep only maxItems
        if count > maxItems {
            removeLast(count - maxItems)
        }
    }
}
