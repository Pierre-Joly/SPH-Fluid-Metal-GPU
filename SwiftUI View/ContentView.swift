//
//  ContentView.swift
//  SPH
//
//  Created by Pierre joly on 26/08/2024.
//

import SwiftUI

let size: CGFloat = 700

struct ContentView: View {
    @State private var showGrid = true
    @State private var particleSize: Float = 0.05 // Initial value for particle size
    @State private var restDensity: Float = 100.0 // Initial value for restDensity
    @State private var stiffness: Float = 1.0 // Initial value for stiffness

    var body: some View {
        VStack {
            MetalView(particleSize: $particleSize, restDensity: $restDensity, stiffness: $stiffness)
                .border(Color.white, width: 20)
        }
        .frame(width: size, height: size)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
