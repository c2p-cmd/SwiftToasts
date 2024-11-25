//
//  File.swift
//  SwiftToasts
//
//  Created by Sharan Thakur on 25/11/24.
//

import SwiftUI

public typealias Toasts = [Toast]

public struct Toast: Identifiable, Equatable {
    private(set) public var id = UUID()
    var content: AnyView
    var offsetX: CGFloat = 0.0
    var isDeleting: Bool = false
    
    public init<Content: View>(@ViewBuilder content: @escaping (UUID) -> Content) {
        self.content = AnyView(content(id))
    }
    
    @MainActor
    public static func simple(
        _ titleKey: AttributedString,
        systemImage: String
    ) -> Toast {
        Toast { id in
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                
                Text(titleKey)
                    .font(.callout)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background {
                Capsule()
                    .fill(.background)
                    .shadow(color: .secondary, radius: 3, x: -1, y: -3)
                    .shadow(color: .secondary, radius: 2, x: 1, y: 3)
            }
        }
    }
    
    public static func ==(lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

public extension View {
    @ViewBuilder
    func interactiveToasts(_ toasts: Binding<Toasts>) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastView(toasts: toasts)
            }
    }
}

fileprivate struct ToastView: View {
    @Binding var toasts: Toasts
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isExpanded {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isExpanded = false
                    }
            }
            
            layout {
                ForEach($toasts) { $t in
                    let index = toasts.count - 1 - (toasts.firstIndex(of: t) ?? 0)
                    
                    if #available(iOS 17, *) {
                        t.content
                            .offset(x: t.offsetX)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let xOffset = value.translation.width < 0 ? value.translation.width : 0
                                        t.offsetX = xOffset
                                    }
                                    .onEnded { value in
                                        let xOffset = value.translation.width + (value.velocity.width / 2)
                                        
                                        if -xOffset > 200 {
                                            // remove
                                            $toasts.delete(id: t.id)
                                        } else {
                                            // reset pos
                                            t.offsetX = 0.0
                                        }
                                    }
                            )
                            .visualEffect { [isExpanded] content, proxy in
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
                        t.content
                            .offset(x: t.offsetX)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let xOffset = value.translation.width < 0 ? value.translation.width : 0
                                        $t.wrappedValue.offsetX = xOffset
                                    }
                                    .onEnded { value in
                                        let xOffset = value.translation.width + (value.velocity.width / 2)
                                        
                                        if -xOffset > 200 {
                                            // remove
                                            $toasts.delete(id: t.id)
                                        } else {
                                            // reset pos
                                            t.offsetX = 0.0
                                        }
                                    }
                            )
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
                isExpanded.toggle()
            }
            .padding(.bottom, 15)
        }
        .animation(.bouncy, value: isExpanded)
        .onChange(of: toasts.isEmpty) { newValue in
            if newValue {
                isExpanded = false
            }
        }
    }
    
    private var layout: AnyLayout {
        isExpanded ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
    }
    
    nonisolated private func offsetY(ofIndex index: Int) -> CGFloat {
        let offset: CGFloat = min(
            CGFloat(index) * 15.0, 30.0
        )
        return -offset
    }
    
    nonisolated private func scale(ofIndex index: Int) -> CGFloat {
        let scale: CGFloat = min(
            CGFloat(index) * 0.1, 1
        )
        
        return 1 - scale
    }
}


extension Binding<Toasts> {
    func delete(id: Toast.ID) {
        if let toast = self.first(where: { $0.id == id }) {
            toast.wrappedValue.isDeleting = true
        }
        
        withAnimation(.bouncy) {
            self.wrappedValue.removeAll(where: { $0.id == id })
        }
    }
}
