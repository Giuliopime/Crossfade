//
//  ShareExtensionView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

import SwiftUI

struct ShareExtensionView: View {
    let url: String
    
    var body: some View {
        EmptyView()
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close.share.extension"), object: nil)
    }
}

#Preview {
    ShareExtensionView(url: "https://music.apple.com/it/album/eyes-open-taylors-version-single/1676966914")
}
