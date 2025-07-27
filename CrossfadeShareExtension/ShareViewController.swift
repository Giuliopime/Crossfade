//
//  ShareViewController.swift
//  CrossfadeShareExtension
//
//  Created by Giulio Pimenoff Verdolin on 14/06/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import SwiftData

@objc(ShareViewController)
class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlDataType = UTType.url.identifier
        
        if let inputItem = (extensionContext?.inputItems.first as? NSExtensionItem),
           let itemProvider = inputItem.attachments?.first {
            if itemProvider.hasItemConformingToTypeIdentifier(urlDataType) {
                itemProvider.loadItem(forTypeIdentifier: urlDataType, options: nil) { (url, error) in
                    if error == nil {
                        if let url = (url as? URL) {
                            self.showView(url: url)
                        }
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("close.share.extension"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
    func showView(url: URL) {
        DispatchQueue.main.async {
            let contentView = UIHostingController(
                rootView: ShareExtensionView(url: url)
                    .environment(AppleMusicClient())
                    .environment(SpotifyClient())
                    .environment(SoundCloudClient())
                    .environment(YouTubeClient())
                    .modelContainer(for: [TrackAnalysis.self])
                    .defaultAppStorage(UserDefaults(suiteName: Identifiers.app_group)!)
            )
            self.addChild(contentView)
            self.view.addSubview(contentView.view)
            
            // set up constraints
            contentView.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
            contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
        }
    }
    
    /// Close the Share Extension
    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
