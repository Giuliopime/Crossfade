//
//  ConcentricCirclesView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 31/07/25.
//


import SwiftUI

struct ConcentricCirclesView: View {
    let imageNames = ["logo_apple_music", "logo_spotify", "logo_soundcloud", "logo_youtube"]
    let circleRadii: [CGFloat]
    let imageSize: CGFloat
    let spacingBetweenImages: CGFloat
    
    @State private var rotationAngles: [Double] = [0, 0, 0, 0]
    
    init(circleRadii: [CGFloat] = [245, 330], imageSize: CGFloat = 44, spacingBetweenImages: CGFloat = 30) {
        self.circleRadii = circleRadii
        self.imageSize = imageSize
        self.spacingBetweenImages = spacingBetweenImages
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<circleRadii.count, id: \.self) { circleIndex in
                let radius = circleRadii[circleIndex]
                let imageCount = calculateImageCount(for: radius)
                
                ZStack {
                    // Optional: Show circle outline for reference
//                    Circle()
//                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
//                        .frame(width: radius * 2, height: radius * 2)
                    
                    // Place calculated number of images around the circle
                    ForEach(0..<imageCount, id: \.self) { imageIndex in
                        let staticOffset = Double(circleIndex) * 15.0 // Static offset per circle
                        let angle = Double(imageIndex) * (360.0 / Double(imageCount)) + staticOffset
                        let radians = angle * .pi / 180.0
                        
                        let x = radius * cos(radians)
                        let y = radius * sin(radians)
                        
                        Image(imageNames[imageIndex % imageNames.count])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
//                            .background(Color.white)
//                            .clipShape(Circle())
//                            .shadow(radius: 5)
                            .grayscale(1)
                            .rotationEffect(.degrees(-rotationAngles[circleIndex])) // Counter-rotate to keep image upright
                            .offset(x: x, y: y)
                    }
                }
                .rotationEffect(.degrees(rotationAngles[circleIndex]))
            }
        }
        .opacity(0.2)
        .onAppear {
            startRotationAnimations()
        }
    }
    
    private func startRotationAnimations() {
        let baseRotationSpeed: Double = 40 // Base speed for the smallest circle (seconds per rotation)
        let baseRadius = circleRadii[0] // Use the innermost circle as reference
        
        for index in 0..<circleRadii.count {
            let radius = circleRadii[index]
            let isClockwise = index % 2 == 0 // Even indices clockwise, odd counterclockwise
            
            // Adjust speed based on radius to maintain same angular velocity
            let adjustedSpeed = baseRotationSpeed * (radius / baseRadius)
            let targetAngle: Double = isClockwise ? 360 : -360
            
            withAnimation(.linear(duration: adjustedSpeed).repeatForever(autoreverses: false)) {
                rotationAngles[index] = targetAngle
            }
        }
    }
    
    
    private func calculateImageCount(for radius: CGFloat) -> Int {
        let circumference = 2 * .pi * radius
        let spacePerImage = imageSize + spacingBetweenImages
        let maxImages = Int(circumference / spacePerImage)
        return max(1, maxImages) // Ensure at least 1 image
    }
}

#Preview {
    ConcentricCirclesView()
}
