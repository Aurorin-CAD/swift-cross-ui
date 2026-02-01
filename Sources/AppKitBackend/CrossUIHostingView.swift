import AppKit
import SwiftCrossUI

/// An AppKit view that hosts a SwiftCrossUI view hierarchy.
///
/// Use this view to embed SwiftCrossUI views within a native AppKit view hierarchy.
/// This is the inverse of ``NSViewRepresentable``, which embeds AppKit views within
/// SwiftCrossUI.
///
/// Example usage:
/// ```swift
/// let hostingView = CrossUIHostingView(rootView: MySwiftCrossUIView())
/// myNativeView.addSubview(hostingView)
/// ```
@MainActor
public class CrossUIHostingView<Content: View>: NSView {
    /// The root SwiftCrossUI view being hosted.
    public var rootView: Content {
        didSet {
            updateViewGraph()
        }
    }
    
    /// The backend used for rendering.
    private let backend: AppKitBackend
    
    /// The root node of the view graph.
    private var viewGraphNode: ViewGraphNode<Content, AppKitBackend>?
    
    /// The environment values for the hosted view.
    private var environment: EnvironmentValues
    
    /// Cancellables for state observations.
    private var cancellables: [Cancellable] = []
    
    /// The content view created by the view graph.
    private var contentWidget: NSView?
    
    /// Creates a hosting view with the specified SwiftCrossUI view as its root.
    ///
    /// - Parameter rootView: The SwiftCrossUI view to host.
    public init(rootView: Content) {
        self.rootView = rootView
        self.backend = AppKitBackend()
        self.environment = EnvironmentValues(backend: backend)
        
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        setupViewGraph()
    }
    
    /// Creates a hosting view with the specified SwiftCrossUI view and environment.
    ///
    /// - Parameters:
    ///   - rootView: The SwiftCrossUI view to host.
    ///   - environment: Custom environment values to use.
    public init(rootView: Content, environment: EnvironmentValues) {
        self.rootView = rootView
        self.backend = AppKitBackend()
        self.environment = environment
        
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        setupViewGraph()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    private func setupViewGraph() {
        // Create the view graph node
        let node = ViewGraphNode<Content, AppKitBackend>(
            for: rootView,
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        self.viewGraphNode = node
        
        // Add the widget as a subview
        let widget = node.widget
        self.contentWidget = widget
        self.addSubview(widget)
        
        // Setup constraints
        widget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widget.topAnchor.constraint(equalTo: self.topAnchor),
            widget.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            widget.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            widget.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
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
            bounds.width > 0 ? bounds.width : nil,
            bounds.height > 0 ? bounds.height : nil
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
            bounds.width > 0 ? bounds.width : nil,
            bounds.height > 0 ? bounds.height : nil
        )
        
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
    }
    
    public override func layout() {
        super.layout()
        performLayout()
    }
    
    public override var intrinsicContentSize: NSSize {
        guard let node = viewGraphNode else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
        
        // Compute ideal size without constraints
        let result = node.computeLayout(
            proposedSize: .unspecified,
            environment: environment
        )
        
        return NSSize(width: result.size.width, height: result.size.height)
    }
    
    /// Invalidates the view graph and triggers a complete rebuild.
    public func invalidate() {
        contentWidget?.removeFromSuperview()
        contentWidget = nil
        viewGraphNode = nil
        setupViewGraph()
    }
}

/// An AppKit view controller that hosts a SwiftCrossUI view hierarchy.
///
/// Use this controller to present SwiftCrossUI views within an AppKit view controller
/// hierarchy, such as in a tab view or split view.
///
/// Example usage:
/// ```swift
/// let hostingController = CrossUIHostingController(rootView: MySwiftCrossUIView())
/// presentViewController(hostingController, asPopoverRelativeTo: ...)
/// ```
@MainActor
public class CrossUIHostingController<Content: View>: NSViewController {
    /// The hosting view managed by this controller.
    public var hostingView: CrossUIHostingView<Content> {
        view as! CrossUIHostingView<Content>
    }
    
    /// The root SwiftCrossUI view being hosted.
    public var rootView: Content {
        get { hostingView.rootView }
        set { hostingView.rootView = newValue }
    }
    
    /// Creates a hosting controller with the specified SwiftCrossUI view as its root.
    ///
    /// - Parameter rootView: The SwiftCrossUI view to host.
    public init(rootView: Content) {
        super.init(nibName: nil, bundle: nil)
        self.view = CrossUIHostingView(rootView: rootView)
    }
    
    /// Creates a hosting controller with the specified SwiftCrossUI view and environment.
    ///
    /// - Parameters:
    ///   - rootView: The SwiftCrossUI view to host.
    ///   - environment: Custom environment values to use.
    public init(rootView: Content, environment: EnvironmentValues) {
        super.init(nibName: nil, bundle: nil)
        self.view = CrossUIHostingView(rootView: rootView, environment: environment)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    public override func loadView() {
        // View is set in init, this prevents loading from nib
    }
    
    /// Invalidates the hosted view graph and triggers a complete rebuild.
    public func invalidate() {
        hostingView.invalidate()
    }
}
