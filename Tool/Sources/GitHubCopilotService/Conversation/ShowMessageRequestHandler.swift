import JSONRPC
import Foundation
import Combine
import Logger
import AppKit
import LanguageServerProtocol

public protocol ShowMessageRequestHandler {
    func handleShowMessageRequest(
        _ request: ShowMessageRequest,
        callback: @escaping @Sendable (Result<MessageActionItem?, JSONRPCResponseError<JSONValue>>) async -> Void
    )
}

public final class ShowMessageRequestHandlerImpl: ShowMessageRequestHandler {
    public static let shared = ShowMessageRequestHandlerImpl()

    public func handleShowMessageRequest(
        _ request: ShowMessageRequest,
        callback: @escaping @Sendable (Result<MessageActionItem?, JSONRPCResponseError<JSONValue>>) async -> Void
    ) {
        guard let params = request.params else { return }
        Logger.gitHubCopilot.debug("Received Show Message Request: \(params)")
        Task { @MainActor in
            let selectedAction = showMessageRequestAlert(params)
            await callback(.success(selectedAction))
        }
    }
    
    @MainActor
    func showMessageRequestAlert(_ params: ShowMessageRequestParams) -> MessageActionItem? {
        let alert = NSAlert()

        alert.messageText = "GitHub Copilot"
        alert.informativeText = params.message
        alert.alertStyle = params.type == .info ? .informational : .warning
        
        let actions = params.actions ?? []
        for item in actions {
            alert.addButton(withTitle: item.title)
        }
        
        let response = alert.runModal()
        
        // Map the button response to the corresponding action
        // .alertFirstButtonReturn = 1000, .alertSecondButtonReturn = 1001, etc.
        let buttonIndex = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        
        guard buttonIndex >= 0 && buttonIndex < actions.count else {
            return nil
        }
        
        return actions[buttonIndex]
    }
}
