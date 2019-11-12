//
//  AppDelegate.swift
//  SiteSnap
//
//  Created by Paul Oprea on 12/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import CoreData
import AWSCognitoIdentityProvider

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var signInViewController: SignInViewController?
    var storyboard: UIStoryboard?
    var userTappedLogOut: Bool = false
    var userWantToResetPassword: Bool = false
    var isSignInControlerPresenting = false
    
    //    var user: AWSCognitoIdentityUser?
    //    var pool: AWSCognitoIdentityUserPool?
    
    //MARK: - Set Orientation
    /// set orientations you want to be allowed in this property by default
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    struct AppUtility {
        
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        
        /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            
            self.lockOrientation(orientation)
            
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
        
    }
    
    //MARK: - Launcher Screen
    //    private func splashScreen(){
    //        let launchScreenVC = UIStoryboard.init(name: "LaunchScreen", bundle: nil)
    //        let rootVC = launchScreenVC.instantiateViewController(withIdentifier: "splashScreen")
    //        self.window?.rootViewController = rootVC
    //        self.window?.makeKeyAndVisible()
    //        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(dismissSplashController), userInfo: nil, repeats: false)
    //    }
    //    @objc func dismissSplashController(){
    //        let mainVC = UIStoryboard.init(name: "Main", bundle: nil)
    //        let rootVC = mainVC.instantiateViewController(withIdentifier: "initController")
    //        self.window?.rootViewController = rootVC
    //        self.window?.makeKeyAndVisible()
    //    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //self.splashScreen()
        AWSDDLog.sharedInstance.logLevel = .verbose
        
        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: nil)
        
        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: CognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: nil,
                                                                        poolId: CognitoIdentityUserPoolId)
        
        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: AWSCognitoUserPoolsSignInProviderKey)
        
        // fetch the user pool client we initialized in above step
        let pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        self.storyboard = UIStoryboard(name: "Main", bundle: nil)
        pool.delegate = self
        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        // print("resignActve")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // print("didenterbackground")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to itemn. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "SiteSnap")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
extension AppDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    /*
     If user is logged out the method is called.
     This method is called when we need to log into the application.
     
     It will grab the view controller from the storyboard and present it.
     */
    
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        
        if self.signInViewController == nil {
            self.signInViewController = storyboard!.instantiateViewController(withIdentifier: "signInViewController") as? SignInViewController
            signInViewController?.modalPresentationStyle = .fullScreen
        }
        
        DispatchQueue.main.async {
            
            if (!self.signInViewController!.isViewLoaded || self.signInViewController!.view.window == nil) {
                if(!self.userWantToResetPassword){
                    print("START PASSWORD AUTHENTICATION - signIn should appear")
                    print(self.userTappedLogOut ? "LOG OUT" : "LOG CHECKED OK")
                    if self.userTappedLogOut {
                        let initialViewController = self.storyboard!.instantiateInitialViewController() as! CameraViewController
                        initialViewController.modalPresentationStyle = .fullScreen
                        self.window?.rootViewController = initialViewController
                    }
                    if (!self.isSignInControlerPresenting){
                        self.isSignInControlerPresenting = true
                        print("signInLoaded = \(self.signInViewController!.isViewLoaded)")
                        self.window?.rootViewController?.present(self.signInViewController!, animated: true, completion: {() in
                            self.isSignInControlerPresenting = false
                        })
                    }
                }
            } else {
                print("Log in screen is already visible")
            }
        }
        
        return self.signInViewController!
    }
    
    
    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
        return self
    }
}

// MARK:- AWSCognitoIdentityRememberDevice protocol delegate

extension AppDelegate: AWSCognitoIdentityRememberDevice {
    
    func getRememberDevice(_ rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>) {
        //        self.rememberDeviceCompletionSource = rememberDeviceCompletionSource
        //        DispatchQueue.main.async {
        //            // dismiss the view controller being present before asking to remember device
        //            self.window?.rootViewController!.presentedViewController?.dismiss(animated: true, completion: nil)
        //            let alertController = UIAlertController(title: "Remember Device",
        //                                                    message: "Do you want to remember this device?.",
        //                                                    preferredStyle: .actionSheet)
        //
        //            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
        //                self.rememberDeviceCompletionSource?.set(result: true)
        //            })
        //            let noAction = UIAlertAction(title: "No", style: .default, handler: { (action) in
        //                self.rememberDeviceCompletionSource?.set(result: false)
        //            })
        //            alertController.addAction(yesAction)
        //            alertController.addAction(noAction)
        //
        //            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        //        }
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        
        DispatchQueue.main.async {
            
            if let error = error as NSError? {
                print("DID COMPLETE STEP WITH ERROR")
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async {
                    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}
