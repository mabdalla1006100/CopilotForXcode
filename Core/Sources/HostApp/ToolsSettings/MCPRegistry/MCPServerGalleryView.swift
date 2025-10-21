import AppKit
import Client
import CryptoKit
import GitHubCopilotService
import Logger
import SharedUIComponents
import SwiftUI

enum MCPServerGalleryWindow {
    static let identifier = "MCPServerGalleryWindow"

    static func open(serverList: MCPRegistryServerList) {
        if let existing = NSApp.windows.first(where: { $0.identifier?.rawValue == identifier }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(
            rootView: MCPServerGalleryView(
                mcpRegistryServerList: serverList
            )
        )

        let window = NSWindow(contentViewController: controller)
        window.title = "MCP Servers Marketplace"
        window.identifier = NSUserInterfaceItemIdentifier(identifier)
        window.setContentSize(NSSize(width: 800, height: 600))
        window.minSize = NSSize(width: 600, height: 400)
        window.styleMask.insert([.titled, .closable, .resizable, .miniaturizable])
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Stable ID helper

extension MCPRegistryServerDetail {
    var stableID: String {
        meta?.official?.id ?? repository?.id ?? name
    }
}

private struct IdentifiableServer: Identifiable {
    let server: MCPRegistryServerDetail
    var id: String { server.stableID }
}

struct MCPServerGalleryView: View {
    @StateObject private var viewModel: MCPServerGalleryViewModel
    @State private var isShowingURLSheet = false

    init(mcpRegistryServerList: MCPRegistryServerList) {
        _viewModel = StateObject(
            wrappedValue: MCPServerGalleryViewModel(
                initialList: mcpRegistryServerList
            )
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            tableHeaderView
            serverListView
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .background(.ultraThinMaterial)
        .onAppear {
            viewModel.loadInstalledServers()
        }
        .sheet(isPresented: $isShowingURLSheet) {
            urlSheet
        }
        .sheet(isPresented: Binding(
            get: { viewModel.infoSheetServer != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissInfo()
                }
            }
        )) {
            if let server = viewModel.infoSheetServer {
                infoSheet(server)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search")
        .toolbar {
            ToolbarItem {
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            
            ToolbarItem {
                Button(action: { isShowingURLSheet = true }) {
                    Image(systemName: "square.and.pencil")
                }
                .help("Configure your MCP Registry URL")
            }
        }
    }

    private var tableHeaderView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Name")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .frame(width: 220, alignment: .leading)

                Divider().frame(height: 20)

                Text("Description")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("Actions")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
                .frame(width: 120, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.clear)

            Divider()
        }
    }

    private var serverListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                serverRows

                if viewModel.shouldShowLoadMoreSentinel {
                    Color.clear
                        .frame(height: 1)
                        .onAppear { viewModel.loadMoreIfNeeded() }
                        .accessibilityHidden(true)
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 12)
                        Spacer()
                    }
                }
            }
        }
    }

    private var serverRows: some View {
        ForEach(Array(viewModel.filteredServers.enumerated()), id: \.element.stableID) { index, server in
            let isInstalled = viewModel.isServerInstalled(serverId: server.stableID)
            row(for: server, index: index, isInstalled: isInstalled)
                .background(rowBackground(for: index))
                .cornerRadius(8)
                .onAppear {
                    handleRowAppear(index: index)
                }
        }
    }

    private var urlSheet: some View {
        MCPRegistryURLSheet(onURLUpdated: {
            viewModel.refresh()
        })
        .frame(width: 500, height: 150)
    }

    private func rowBackground(for index: Int) -> Color {
        index.isMultiple(of: 2) ? Color.clear : Color.primary.opacity(0.03)
    }

    private func handleRowAppear(index: Int) {
        let currentFilteredCount = viewModel.filteredServers.count
        let totalServerCount = viewModel.servers.count

        // Prefetch when approaching the end of filtered results
        if index >= currentFilteredCount - 5 {
            // If we're filtering and the filtered results are small compared to total servers,
            // or if we're near the end of all available data, try to load more
            if currentFilteredCount < 20 || index >= totalServerCount - 5 {
                viewModel.loadMoreIfNeeded()
            }
        }
    }

    // MARK: - Subviews

    private func row(for server: MCPRegistryServerDetail, index: Int, isInstalled: Bool) -> some View {
        HStack {
            Text(server.name)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 8)
                .frame(width: 220, alignment: .leading)

            Divider().frame(height: 20).foregroundColor(Color.clear)

            Text(server.description)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                if isInstalled {
                    Button("Uninstall") {
                        Task {
                            await viewModel.uninstallServer(server)
                        }
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .help("Uninstall")
                } else {
                    if #available(macOS 13.0, *) {
                        SplitButton(
                            title: "Install",
                            isDisabled: viewModel.hasNoDeployments(server),
                            primaryAction: {
                                // Install with default configuration
                                Task {
                                    await viewModel.installServer(server)
                                }
                            },
                            menuItems: viewModel.getInstallationOptions(for: server).map { option in
                                SplitButtonMenuItem(title: option.displayName) {
                                    Task {
                                        await viewModel.installServer(server, configuration: option.displayName)
                                    }
                                }
                            }
                        )
                        .help("Install")
                    } else {
                        Button("Install") {
                            Task {
                                await viewModel.installServer(server)
                            }
                        }
                        .disabled(viewModel.hasNoDeployments(server))
                        .help("Install")
                    }
                }

                Button {
                    viewModel.showInfo(server)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                }
                .buttonStyle(.plain)
                .help("View Details")
            }
            .padding(.horizontal, 8)
            .frame(width: 120, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func infoSheet(_ server: MCPRegistryServerDetail) -> some View {
        if #available(macOS 13.0, *) {
            return AnyView(MCPServerDetailSheet(server: server))
        } else {
            return AnyView(EmptyView())
        }
    }
}

func defaultInstallation(for server: MCPRegistryServerDetail) -> String {
    // Get the first available type from remotes or packages
    if let firstRemote = server.remotes?.first {
        return firstRemote.transportType.rawValue
    }
    if let firstPackage = server.packages?.first {
        return firstPackage.registryType ?? ""
    }
    return ""
}
