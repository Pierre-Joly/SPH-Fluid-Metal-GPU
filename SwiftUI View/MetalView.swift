//
//  MetalView.swift
//  SPH
//
//  Created by Pierre joly on 26/08/2024.
//

import SwiftUI
import MetalKit

struct MetalView: View {
    @State private var metalView = MTKView()
    @State private var renderer: Renderer?
    @Binding var particleSize: Float
    @Binding var restDensity: Float
    @Binding var stiffness: Float

    var body: some View {
        MetalViewRepresentable(metalView: $metalView)
            .onAppear {
                renderer = Renderer(metalView: metalView)
            }
    }
}

typealias ViewRepresentable = NSViewRepresentable

struct MetalViewRepresentable: ViewRepresentable {
  @Binding var metalView: MTKView

  func makeNSView(context: Context) -> some NSView {
    metalView
  }
  func updateNSView(_ uiView: NSViewType, context: Context) {
    updateMetalView()
  }

  func updateMetalView() {
  }
}
