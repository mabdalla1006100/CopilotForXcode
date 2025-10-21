import SwiftUI
import AppKit

// MARK: - SplitButton Menu Item

public struct SplitButtonMenuItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

// MARK: - SplitButton using NSComboButton

@available(macOS 13.0, *)
public struct SplitButton: NSViewRepresentable {
    let title: String
    let primaryAction: () -> Void
    let isDisabled: Bool
    let menuItems: [SplitButtonMenuItem]
    
    public init(
        title: String,
        isDisabled: Bool = false,
        primaryAction: @escaping () -> Void,
        menuItems: [SplitButtonMenuItem] = []
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.primaryAction = primaryAction
        self.menuItems = menuItems
    }
    
    public func makeNSView(context: Context) -> NSComboButton {
        let button = NSComboButton()
        
        button.title = title
        button.target = context.coordinator
        button.action = #selector(Coordinator.handlePrimaryAction)
        button.isEnabled = !isDisabled
        
        
        context.coordinator.button = button
        context.coordinator.updateMenu(with: menuItems)
        
        return button
    }
    
    public func updateNSView(_ nsView: NSComboButton, context: Context) {
        nsView.title = title
        nsView.isEnabled = !isDisabled
        context.coordinator.updateMenu(with: menuItems)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(primaryAction: primaryAction)
    }
    
    public class Coordinator: NSObject {
        let primaryAction: () -> Void
        weak var button: NSComboButton?
        private var menuItemActions: [UUID: () -> Void] = [:]
        
        init(primaryAction: @escaping () -> Void) {
            self.primaryAction = primaryAction
        }
        
        @objc func handlePrimaryAction() {
            primaryAction()
        }
        
        @objc func handleMenuItemAction(_ sender: NSMenuItem) {
            if let itemId = sender.representedObject as? UUID,
               let action = menuItemActions[itemId] {
                action()
            }
        }
        
        func updateMenu(with items: [SplitButtonMenuItem]) {
            let menu = NSMenu()
            menuItemActions.removeAll()
            
            // Add fixed menu title if there are items
            if !items.isEmpty {
                if #available(macOS 14.0, *) {
                    let headerItem = NSMenuItem.sectionHeader(title: "Install Server With")
                    menu.addItem(headerItem)
                } else {
                    let headerItem = NSMenuItem()
                    headerItem.title = "Install Server With"
                    headerItem.isEnabled = false
                    menu.addItem(headerItem)
                }
                
                // Add menu items
                for item in items {
                    let menuItem = NSMenuItem(
                        title: item.title,
                        action: #selector(handleMenuItemAction(_:)),
                        keyEquivalent: ""
                    )
                    menuItem.target = self
                    menuItem.representedObject = item.id
                    menuItemActions[item.id] = item.action
                    menu.addItem(menuItem)
                }
            }
            
            button?.menu = menu
        }
    }
}
