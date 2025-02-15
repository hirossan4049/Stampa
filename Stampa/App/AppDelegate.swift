//
//  AppDelegate.swift
//  Stampa
//
//  Created by a on 2/15/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
  
  // APNs からのデバイストークン登録時にも、FirebaseAuth に転送
  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    /// TODO: FIXME
    Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
  }
  
  // リモート通知受信時に FirebaseAuth へ転送
  func application(_ application: UIApplication,
                   didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    
    // FirebaseAuth で処理されなかった場合は、ここで独自の通知処理を実装
    completionHandler(.newData)
  }
}
