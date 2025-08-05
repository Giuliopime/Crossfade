//
//  VideoPlayerView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 01/08/25.
//

import SwiftUI
import AVKit


struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        guard let player = player else { return view }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(playerLayer)
        
        // Store the layer for frame updates
        context.coordinator.playerLayer = playerLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update player layer frame when view size changes
        if let playerLayer = context.coordinator.playerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}
