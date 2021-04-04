//
//  ShareViewController.swift
//  ShareExtensionSiteSnap
//
//  Created by Paul Oprea on 03.04.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import Social
import CoreServices
import MobileCoreServices
import Photos

class ShareViewController: UIViewController {

    private let typeJpg = String(kUTTypeJPEG)
    private let typePng = String(kUTTypePNG)
    private let typeGif = String(kUTTypeGIF)
    private let groupName = "group.com.au.tridenttechnologies.sitesnapapp"
    private let userDefaultsKey = "incomingLocalIdentifiers"
    private var appURLString = "SiteSnap://"
    private var librarySetupResult: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    var imageLocalIdentifiers: [String]!
    //private var handleAssets = [PHAsset]()
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // let containerURL = FileManager().containerURL(forSecurityApplicationGroupIdentifier: groupName)!
//        docPath = "\(containerURL.path)/share"
//        print(docPath)
//        do {
//            try FileManager.default.createDirectory(atPath: docPath, withIntermediateDirectories: true, attributes: nil)
//        } catch let error as NSError {
//            print("Could not create the directory \(error)")
//        } catch {
//            fatalError()
//        }
//
//        //  removing previous stored files
//        let files = try! FileManager.default.contentsOfDirectory(atPath: docPath)
//        for file in files {
//            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "\(docPath)/\(file)"))
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        libraryAuthorization()
        
        
    }
    
    func libraryAuthorization() {
        switch librarySetupResult {
            case .authorized:
                handleExtensionItems()
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({status in
                    if status == PHAuthorizationStatus.authorized {
                        /* do stuff here */
                        self.handleExtensionItems()
                    }
                    self.librarySetupResult = status
                })
            case .restricted:
                print("User do not have access to photo album.")
            case .denied:
                print("User has denied the permission.")
            case .limited:
                break
            @unknown default:
                print("unknown")
        }
    }
    
    private func handleExtensionItems(){
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let _ = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        if let item = self.extensionContext?.inputItems[0] as? NSExtensionItem{
            print("Was selected \(String(describing: item.attachments!.count)) items")
            print("===========")
            if imageLocalIdentifiers != nil {
                imageLocalIdentifiers.removeAll()
            }
            for itemProvider in item.attachments! {
                var imageType = ""
                if itemProvider.hasItemConformingToTypeIdentifier(typePng) {
                    imageType = typePng
                }
                if itemProvider.hasItemConformingToTypeIdentifier(typeJpg) {
                    imageType = typeJpg
                }
                if itemProvider.hasItemConformingToTypeIdentifier(typeGif) {
                    imageType = typeGif
                }
                if itemProvider.hasItemConformingToTypeIdentifier(imageType){
                    //print(imageType)
                    itemProvider.loadItem(forTypeIdentifier: imageType, options: nil) { (item, error) in
                        if let error = error {
                            print("Text-Error: \(error.localizedDescription)")
                        }
                        if let url = item as? NSURL, let urlString = url.absoluteString {
                            if self.imageLocalIdentifiers == nil {
                                self.imageLocalIdentifiers = [String]()
                            }
//                            if let imageData = NSData(contentsOf: url as URL){
//                                print("done")
//                                if let _: UIImage = UIImage(data: imageData as Data, scale: UIScreen.main.scale) {
//                                    print("tru")
//                                }
//                            }
                        
                            if let imageFilePath = url.path, imageFilePath.hasPrefix("/var/mobile/Media/"){
                                for component in imageFilePath.components(separatedBy: "/") where component.contains("IMG_"){
                                    let fileName = component.components(separatedBy: ".").first!
                                    if let asset = self.imageAssetDictionary[fileName] {
                                        self.imageLocalIdentifiers.append(asset.localIdentifier)
                                    }
                                    break
                                }
                            }
                            //ONLY FOR SIMULATORS
                            else if let imageFilePath = url.path, imageFilePath.contains("/Library/Developer/CoreSimulator/"){
                                for component in imageFilePath.components(separatedBy: "/") where component.contains("IMG_"){
                                    let fileName = component.components(separatedBy: ".").first!
                                    if let asset = self.imageAssetDictionary[fileName] {
                                        self.imageLocalIdentifiers.append(asset.localIdentifier)
                                    }
                                    break
                                }
                            }
                        
                        
                            self.saveUrlString(self.imageLocalIdentifiers)
                           // print(urlString)
                        }
                        self.openMainApp()
                    }
                } else {
                    print("error: No accepted URL found")
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }
    
    private lazy var imageAssetDictionary: [String : PHAsset] = {

        let options = PHFetchOptions()
        options.includeHiddenAssets = true

        let fetchResult = PHAsset.fetchAssets(with: options)

        var assetDictionary = [String : PHAsset]()

        for i in 0 ..< fetchResult.count {
            let asset = fetchResult[i]
            let fileName = asset.value(forKey: "filename") as! String
            let fileNameWithoutSuffix = fileName.components(separatedBy: ".").first!
            assetDictionary[fileNameWithoutSuffix] = asset
        }

        return assetDictionary
    }()
    
    private func saveUrlString(_ urls: [String]){
        UserDefaults(suiteName: self.groupName)?.set(urls, forKey: self.userDefaultsKey)
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
    private func openMainApp(){
//        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
            //for url in self.urls{
            guard let url = URL(string: self.appURLString) else { return }
            _ = self.openURL(url)
           // }
        })
    }

}
