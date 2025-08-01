//
//  RotatingLogosView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 31/07/25.
//

import SwiftUI

struct SingleCircleView: View {
    let imageNames = ["logo_apple_music", "logo_spotify", "logo_soundcloud", "logo_youtube"]
    let circleRadius: CGFloat
    let imageSize: CGFloat
    let spacingBetweenImages: CGFloat
    
    @State private var rotationAngle: Double = 0
    @State private var visibleImage: Int = 0
    
    init(circleRadius: CGFloat = 104, imageSize: CGFloat = 44, spacingBetweenImages: CGFloat = 30) {
        self.circleRadius = circleRadius
        self.imageSize = imageSize
        self.spacingBetweenImages = spacingBetweenImages
    }
    
    var body: some View {
        ZStack {
            Image(uiImage: UIApplication.shared.alternateIconName == nil ? UIImage(named: "AppIcon60x60") ?? UIImage() : UIImage(named: UIApplication.shared.alternateIconName!) ?? UIImage())
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(16)
            
            
            // Place exactly 4 images evenly around the circle
            Group {
                ForEach(0..<imageNames.count, id: \.self) { imageIndex in
                    let angle = Double(imageIndex) * (360.0 / Double(imageNames.count)) // 90 degrees apart
                    let radians = angle * .pi / 180.0
                    
                    let x = circleRadius * cos(radians)
                    let y = circleRadius * sin(radians)
                    
                    Image(imageNames[imageIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize, height: imageSize)
                        .grayscale(visibleImage == imageIndex ? 0 : 1)
                    //                    .background(Color.white)
                    //                    .clipShape(Circle())
                    //                    .shadow(radius: 5)
                        .opacity(visibleImage == imageIndex ? 1 : 0.2)
                        .scaleEffect(visibleImage == imageIndex ? 1 : 0.8)
                        .rotationEffect(.degrees(-rotationAngle)) // Counter-rotate to keep image upright
                        .offset(x: x, y: y)
                }
            }
            .rotationEffect(.degrees(rotationAngle))
        }
        .onAppear {
            startRotationAnimation()
            startImageCycling()
        }
    }
    
    private func startRotationAnimation() {
        let rotationSpeed: Double = 10 // seconds per rotation
        
        withAnimation(.linear(duration: rotationSpeed).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func startImageCycling() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.2)) {
                visibleImage = (visibleImage + 1) % imageNames.count
            }
        }
    }
}

#Preview {
    SingleCircleView()
}
