/// This example demonstrates how to embed SwiftCrossUI views into a native AppKit application
/// without using the `App` protocol or `SwiftCrossApp` class.
///
/// This is useful when:
/// - You're adding SwiftCrossUI views to an existing native app
/// - You want to use SwiftCrossUI for specific parts of your UI
/// - You need more control over the application lifecycle
///
/// The example creates a native NSWindow and embeds SwiftCrossUI views using
/// `CrossUIHostingView` and `CrossUIHostingController`.

#if os(macOS)
import AppKit
import AppKitBackend
import SwiftCrossUI

// MARK: - SwiftCrossUI Views

/// A simple counter view built with SwiftCrossUI
struct CounterView: View {
    @State var count: Int
    
    var body: some View {
        VStack(spacing: 15) {
            Text("SwiftCrossUI Counter")
                .emphasized()
            
            HStack(spacing: 20) {
                Button("-") { count -= 1 }
                Text("Count: \(count)")
                    .frame(minWidth: 80)
                Button("+") { count += 1 }
            }
        }
        .padding()
    }
}

/// A greeting view that demonstrates state and interaction
struct GreetingView: View {
    @State var name: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            Text("SwiftCrossUI Greeting")
                .emphasized()
            
            TextField("Enter your name", text: $name)
                .frame(width: 200)
            
            if !name.isEmpty {
                Text("Hello, \(name)!")
            }
        }
        .padding()
    }
}

// MARK: - Native AppKit Application

/// A native AppKit application delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the main window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window?.title = "Hosting View Example - Native AppKit + SwiftCrossUI"
        window?.center()
        
        // Create the native split view
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        
        // Create native views for each pane
        let leftPane = createLeftPane()
        let rightPane = createRightPane()
        
        splitView.addSubview(leftPane)
        splitView.addSubview(rightPane)
        
        // Set position for divider
        splitView.setPosition(300, ofDividerAt: 0)
        
        window?.contentView = splitView
        window?.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    /// Creates the left pane with a SwiftCrossUI counter embedded in a native view
    @MainActor func createLeftPane() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Create a native label
        let titleLabel = NSTextField(labelWithString: "Native AppKit Container")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Embed a SwiftCrossUI view using CrossUIHostingView
        let hostingView = CrossUIHostingView(rootView: CounterView(count: 0))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostingView)
        
        // Add a native button below the hosting view
        let nativeButton = NSButton(title: "Native AppKit Button", target: nil, action: nil)
        nativeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nativeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            hostingView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            
            nativeButton.topAnchor.constraint(equalTo: hostingView.bottomAnchor, constant: 20),
            nativeButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])
        
        return container
    }
    
    /// Creates the right pane with another SwiftCrossUI view
    @MainActor func createRightPane() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Create another SwiftCrossUI hosting view
        let hostingView = CrossUIHostingView(rootView: GreetingView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        
        return container
    }
}

// MARK: - Main Entry Point

/// Main entry point - launches as a native AppKit app
@main
struct HostingViewExampleApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)
        app.run()
    }
}

#else
// Fallback for non-macOS platforms
@main
struct HostingViewExampleApp {
    static func main() {
        print("This example is macOS-only. See CrossUIHostingElement for Windows support.")
    }
}
#endif
