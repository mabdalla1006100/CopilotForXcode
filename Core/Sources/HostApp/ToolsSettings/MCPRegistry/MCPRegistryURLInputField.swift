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
    let onValidationChange: ((Bool) -> Void)?
    
    init(
        urlText: Binding<String>,
        maxURLLength: Int = 2048,
        isSheet: Bool = false,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self._urlText = urlText
        self.maxURLLength = maxURLLength
        self.isSheet = isSheet
        self.onValidationChange = onValidationChange
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if isSheet {
                TextFieldsContainer {
                    TextField("MCP Registry URL", text: $urlText)
                        .focused($isFocused)
                        .onChange(of: urlText) { newValue in
                            handleURLChange(newValue)
                        }
                }
            } else {
                TextField("MCP Registry URL:", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
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
        }
    }
    
    private func handleURLChange(_ newValue: String) {
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
