//
//  AppDelegate.swift
//  Spending-Manager
//
//  Created by  User on 30.10.2025.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let db = AppDatabase.shared
        db.insertDefaultTransactionTypes()
        db.insertDefaultSampleCategoriesIfNeeded()
        
        let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    print(granted ? "Đã cho phép thông báo" : "Người dùng từ chối thông báo")
                }
                center.delegate = self

                // Lên lịch nhắc nhở
                scheduleDailyReminder()
        return true
    }
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Xóa lịch cũ (nếu có)
        center.removeAllPendingNotificationRequests()
        
        // Tạo nội dung thông báo
        let content = UNMutableNotificationContent()
        content.title = "Nhắc nhở chi tiêu"
        content.body = "Đừng quên thêm các khoản chi tiêu của bạn hôm nay nhé 💸"
        content.sound = .default
        
        // Test nhanh sau 10 giây
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        
        /*
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        */
        
        // Tạo request
        let request = UNNotificationRequest(identifier: "daily_spending_reminder", content: content, trigger: trigger)
        
        // Thêm vào notification center
        center.add(request) { error in
            if let error = error {
                print("Lỗi khi lên lịch thông báo: \(error.localizedDescription)")
            } else {
                print("Đã đặt nhắc nhở (test 10 giây)")
            }
        }
    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Spending_Manager")
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
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Cho phép hiển thị khi app đang mở
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}


