//
//  File.swift
//  SwiftToasts
//
//  Created by Sharan Thakur on 25/11/24.
//

import SwiftUI

/// A type alias for a collection of Toast notifications
public typealias Toasts = [Toast]

/// Represents a single toast notification with customizable content and interactions
public struct Toast: Identifiable, Equatable {
    /// Unique identifier for each toast
    private(set) public var id = UUID()
    
    /// The view content of the toast
    var content: AnyView
    
    /// Horizontal offset for swipe interactions
    var offsetX: CGFloat = 0.0
    
    /// Flag indicating whether the toast is in the process of being deleted
    var isDeleting: Bool = false
    
    /// Creates a custom toast with dynamic content
    /// - Parameter content: A view builder closure that generates the toast's content, receiving the toast's unique ID
    public init<Content: View>(@ViewBuilder content: @escaping (UUID) -> Content) {
        self.content = AnyView(content(id))
    }
    
    /// Creates a simple, pre-formatted toast with an icon and text
    /// - Parameters:
    ///   - titleKey: The text to display in the toast
    ///   - systemImage: The SF Symbol name for the icon
    /// - Returns: A standardized toast notification
    @MainActor
    public static func simple(
        _ titleKey: AttributedString,
        systemImage: String
    ) -> Toast {
        Toast { id in
            HStack(spacing: 12) {
                // Display system icon
                Image(systemName: systemImage)
                
                // Display toast text
                Text(titleKey)
                    .font(.callout)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background {
                // Create a capsule-shaped background with subtle shadow
                Capsule()
                    .fill(.background)
                    .shadow(color: .secondary, radius: 3, x: -1, y: -3)
                    .shadow(color: .secondary, radius: 2, x: 1, y: 3)
            }
        }
    }
    
    /// Equality check based on toast ID
    public static func ==(lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}


/// Extension to add toast functionality to any SwiftUI View
public extension View {
    /// Adds an interactive toast notification overlay to the view
    /// - Parameter toasts: A binding to the collection of toasts to display
    /// - Returns: A view with toast notifications
    @ViewBuilder
    func interactiveToasts(_ toasts: Binding<Toasts>) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastView(toasts: toasts)
            }
    }
}

/// Internal view responsible for rendering and managing toast notifications
fileprivate struct ToastView: View {
    /// Binding to the collection of toasts
    @Binding var toasts: Toasts
    
    /// State to track whether toasts are expanded
    @State private var isExpanded: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Overlay for expanded state
            if isExpanded {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isExpanded = false
                    }
            }
            
            // Dynamic layout based on expanded state
            layout {
                ForEach($toasts) { $t in
                    let index = toasts.count - 1 - (toasts.firstIndex(of: t) ?? 0)
                    
                    // iOS 17+ specific implementation with visual effects
                    if #available(iOS 17, *) {
                        t.content
                            .offset(x: t.offsetX)
                            .gesture(swipeGesture($t))
                            .visualEffect { [isExpanded] content, proxy in
                                // Scale and offset effect for stacked toasts
                                content
                                    .scaleEffect(isExpanded ? 1 : scale(ofIndex: index), anchor: .bottom)
                                    .offset(y: isExpanded ? 0 : offsetY(ofIndex: index))
                            }
                            .zIndex(t.isDeleting ? 1000 : 0)
                            .frame(maxWidth: .infinity)
                            .animation(.smooth, value: t.offsetX)
                            .transition(
                                .asymmetric(
                                    insertion: .offset(y: 100),
                                    removal: .move(edge: .leading)
                                )
                            )
                    } else {
                        // Fallback implementation for pre-iOS 17
                        t.content
                            .offset(x: t.offsetX)
                            .gesture(swipeGesture($t))
                            .zIndex(t.isDeleting ? 1000 : 0)
                            .frame(maxWidth: .infinity)
                            .animation(.smooth, value: t.offsetX)
                            .transition(
                                .asymmetric(
                                    insertion: .offset(y: 100),
                                    removal: .move(edge: .leading)
                                )
                            )
                    }
                }
            }
            .onTapGesture {
                // Toggle expanded state on tap
                isExpanded.toggle()
            }
            .padding(.bottom, 15)
        }
        .animation(.bouncy, value: isExpanded)
        .onChange(of: toasts.isEmpty) { newValue in
            // Collapse when no toasts remain
            if newValue {
                isExpanded = false
            }
        }
    }
    
    private func swipeGesture(_ t: Binding<Toast>) -> some Gesture {
        // Swipe-to-dismiss gesture
        DragGesture()
            .onChanged { value in
                let xOffset = value.translation.width < 0 ? value.translation.width : 0
                t.wrappedValue.offsetX = xOffset
            }
            .onEnded { value in
                let xOffset = value.translation.width + (value.velocity.width / 2)
                
                if -xOffset > 200 {
                    // Remove toast if swiped far enough
                    $toasts.delete(id: t.id)
                } else {
                    // Reset position if not swiped far enough
                    t.wrappedValue.offsetX = 0.0
                }
            }
    }
    
    /// Determines layout based on expanded state
    private var layout: AnyLayout {
        isExpanded ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
    }
    
    /// Calculates vertical offset for stacked toasts
    /// - Parameter index: The index of the toast in the stack
    /// - Returns: Vertical offset value
    nonisolated private func offsetY(ofIndex index: Int) -> CGFloat {
        let offset: CGFloat = min(
            CGFloat(index) * 15.0, 30.0
        )
        return -offset
    }
    
    /// Calculates scale effect for stacked toasts
    /// - Parameter index: The index of the toast in the stack
    /// - Returns: Scale value
    nonisolated private func scale(ofIndex index: Int) -> CGFloat {
        let scale: CGFloat = min(
            CGFloat(index) * 0.1, 1
        )
        
        return 1 - scale
    }
}


/// Extension to add deletion functionality to Toast collection
public extension Binding<Toasts> {
    /// Removes a toast with the specified ID
    /// - Parameter id: The unique identifier of the toast to remove
    func delete(id: Toast.ID) {
        // Mark toast for deletion
        if let toast = self.first(where: { $0.id == id }) {
            toast.wrappedValue.isDeleting = true
        }
        
        // Animate toast removal
        withAnimation(.bouncy) {
            self.wrappedValue.removeAll(where: { $0.id == id })
        }
    }
}
