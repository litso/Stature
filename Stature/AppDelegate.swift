//
//  AppDelegate.swift
//  Stature
//
//  Created by Robert Manson on 2/21/19.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }
}

extension UIColor {
    static let teal = UIColor(named: "Teal")!
    static let alert = UIColor(named: "Alert")!
    static let lightGray = UIColor(named: "Light Gray")!
    static let moon = UIColor(named: "Moon")!
}

extension Measurement where UnitType == UnitLength {
    var inchesDescription: String {
        return "\(Int(self.converted(to: .inches).value))\""
    }
}
