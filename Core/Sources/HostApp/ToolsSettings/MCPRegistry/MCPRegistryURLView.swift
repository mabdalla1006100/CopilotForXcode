import AppKit
import Logger
import SharedUIComponents
import SwiftUI
import Client
import XPCShared

struct MCPRegistryURLView: View {
    @State private var isExpanded: Bool = false
    @AppStorage(\.mcpRegistryURL) var mcpRegistryURL
    @AppStorage(\.mcpRegistryURLHistory) private var mcpRegistryURLHistory
    @State private var isLoading: Bool = false
    @State private var tempURLText: String = ""
    @State private var errorMessage: String = ""

    private let maxURLLength = 2048

    var body: some View {
        VStack(spacing: 0) {
            DisclosureSettingsRow(
                isExpanded: $isExpanded,
                accessibilityLabel: { $0 ? "Collapse mcp registry URL section" : "Expand mcp registry URL section" },
                title: { Text("MCP Registry URL").font(.headline) + Text(" (Optional)") },
                subtitle: { Text("Connect to available MCP servers for your AI workflows using the Registry URL.") },
                actions: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView().controlSize(.small)
                        }
                        
                        Button {
                            isExpanded = true
                        } label: {
                            HStack(spacing: 0) {
                                Image(systemName: "square.and.pencil")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12, alignment: .center)
                                    .padding(4)
                                Text("Edit URL")
                            }
                            .conditionalFontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .help("Configure your MCP Registry URL")

                        Button { Task{ await loadMCPServers() } } label: {
                            HStack(spacing: 0) {
                                Image(systemName: "square.grid.2x2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12, alignment: .center)
                                    .padding(4)
                                Text("Browse MCP Servers...")
                            }
                            .conditionalFontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .help("Browse MCP Servers")
                    }
                    .padding(.vertical, 12)
                }
            )

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    MCPRegistryURLInputField(
                        urlText: $tempURLText,
                        maxURLLength: maxURLLength,
                        isSheet: false,
                        onValidationChange: { isValid in
                            if isValid && (!tempURLText.isEmpty || tempURLText.isEmpty) {
                                mcpRegistryURL = tempURLText
                            }
                        }
                    )
                    
                    if !errorMessage.isEmpty {
                        Badge(text: errorMessage, level: .danger, icon: "xmark.circle.fill")
                    }
                }
                .padding(.leading, 36)
                .padding([.trailing, .bottom], 20)
                .background(QuaternarySystemFillColor.opacity(0.75))
                .transition(.opacity.combined(with: .scale(scale: 1, anchor: .top)))
                .onAppear {
                    tempURLText = mcpRegistryURL
                }
            }
        }
        .cornerRadius(12)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(SecondarySystemFillColor, lineWidth: 1)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private func loadMCPServers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let service = try getService()
            let serverList = try await service.listMCPRegistryServers(
                .init(baseUrl: mcpRegistryURL, limit: 30)
            )
            
            guard let serverList = serverList, !serverList.servers.isEmpty else {
                Logger.client.info("No MCP servers found at registry URL: \(mcpRegistryURL)")
                return
            }
            
            // Add to history on successful load
            mcpRegistryURLHistory.addToHistory(mcpRegistryURL)
            errorMessage = ""
            
            MCPServerGalleryWindow.open(serverList: serverList)
        } catch {
            Logger.client.error("Failed to load MCP servers from registry: \(error.localizedDescription)")
            if let serviceError = error as? XPCExtensionServiceError {
                errorMessage = serviceError.underlyingError?.localizedDescription ?? serviceError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            isExpanded = true
        }
    }
}

#Preview {
    MCPRegistryURLView()
        .padding()
        .frame(width: 900)
}
