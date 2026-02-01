import SwiftCrossUI
import WinUI
import WindowsFoundation

// Many force tries are required for the WinUI backend but we don't really want them
// anywhere else so just disable the lint rule at a file level.
// swiftlint:disable force_try

/// A WinUI element that hosts a SwiftCrossUI view hierarchy.
///
/// Use this element to embed SwiftCrossUI views within a native WinUI element hierarchy.
/// This is the inverse of ``WinUIElementRepresentable``, which embeds WinUI elements within
/// SwiftCrossUI.
///
/// Example usage:
/// ```swift
/// let hostingElement = CrossUIHostingElement(rootView: MySwiftCrossUIView())
/// myNativePanel.children.append(hostingElement)
/// ```
@MainActor
public class CrossUIHostingElement<Content: View>: WinUI.Canvas {
    /// The root SwiftCrossUI view being hosted.
    public var rootView: Content {
        didSet {
            updateViewGraph()
        }
    }
    
    /// The backend used for rendering.
    private let backend: WinUIBackend
    
    /// The root node of the view graph.
    private var viewGraphNode: ViewGraphNode<Content, WinUIBackend>?
    
    /// The environment values for the hosted view.
    private var environment: EnvironmentValues
    
    /// The content widget created by the view graph.
    private var contentWidget: WinUI.FrameworkElement?
    
    /// Creates a hosting element with the specified SwiftCrossUI view as its root.
    ///
    /// - Parameter rootView: The SwiftCrossUI view to host.
    public init(rootView: Content) {
        self.rootView = rootView
        self.backend = WinUIBackend()
        self.environment = EnvironmentValues(backend: backend)
        
        super.init()
        
        setupViewGraph()
    }
    
    /// Creates a hosting element with the specified SwiftCrossUI view and environment.
    ///
    /// - Parameters:
    ///   - rootView: The SwiftCrossUI view to host.
    ///   - environment: Custom environment values to use.
    public init(rootView: Content, environment: EnvironmentValues) {
        self.rootView = rootView
        self.backend = WinUIBackend()
        self.environment = environment
        
        super.init()
        
        setupViewGraph()
    }
    
    private func setupViewGraph() {
        // Create the view graph node
        let node = ViewGraphNode<Content, WinUIBackend>(
            for: rootView,
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        self.viewGraphNode = node
        
        // Add the widget as a child
        let widget = node.widget
        self.contentWidget = widget
        children.append(widget)
        
        // Perform initial layout
        performLayout()
    }
    
    private func updateViewGraph() {
        guard let node = viewGraphNode else {
            setupViewGraph()
            return
        }
        
        // Compute new layout with the updated view
        let proposedSize = ProposedViewSize(
            self.width.isNaN || self.width == 0 ? nil : self.width,
            self.height.isNaN || self.height == 0 ? nil : self.height
        )
        
        _ = node.computeLayout(
            with: rootView,
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
    }
    
    private func performLayout() {
        guard let node = viewGraphNode else { return }
        
        let proposedSize = ProposedViewSize(
            self.width.isNaN || self.width == 0 ? nil : self.width,
            self.height.isNaN || self.height == 0 ? nil : self.height
        )
        
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
    }
    
    /// Gets the desired size of the hosted view for a given constraint.
    ///
    /// - Parameter availableSize: The available space for the view.
    /// - Returns: The desired size of the hosted view.
    public func desiredSizeForContent(availableSize: WindowsFoundation.Size) -> WindowsFoundation.Size {
        guard let node = viewGraphNode else {
            return WindowsFoundation.Size(width: 0, height: 0)
        }
        
        let proposedSize = ProposedViewSize(
            availableSize.width.isInfinite ? nil : Double(availableSize.width),
            availableSize.height.isInfinite ? nil : Double(availableSize.height)
        )
        
        let result = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        
        return WindowsFoundation.Size(
            width: Float(result.size.x),
            height: Float(result.size.y)
        )
    }
    
    /// Invalidates the view graph and triggers a complete rebuild.
    public func invalidate() {
        if let contentWidget {
            if let index = children.firstIndex(where: { $0 === contentWidget }) {
                children.remove(at: index)
            }
        }
        contentWidget = nil
        viewGraphNode = nil
        setupViewGraph()
    }
}

/// A helper class to create a hosting element from a view builder closure.
///
/// Example usage:
/// ```swift
/// let hostingElement = CrossUIHostingElement {
///     VStack {
///         Text("Hello from SwiftCrossUI!")
///         Button("Click me") { print("Clicked") }
///     }
/// }
/// ```
@MainActor
public func CrossUIHostingElement<Content: View>(
    @ViewBuilder content: () -> Content
) -> CrossUIHostingElement<Content> {
    return CrossUIHostingElement(rootView: content())
}
