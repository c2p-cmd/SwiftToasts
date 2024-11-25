//
//  SwiftUIView.swift
//  SwiftToasts
//
//  Created by Sharan Thakur on 25/11/24.
//

import SwiftUI

struct DemoView: View {
    @State private var toasts = Toasts()
    
    var body: some View {
        NavigationStack {
            List {
                Text("Dummy Row View")
            }
            .navigationTitle("Swift Toasts Demo")
            .toolbar {
                Button("Show") {
                    withAnimation(.bouncy) {
                        let newToast = Toast.simple("Pick", systemImage: "pencil.circle")
                        
                        toasts.append(newToast)
                    }
                }
            }
        }
        .interactiveToasts($toasts)
    }
}

#Preview {
    DemoView()
}
