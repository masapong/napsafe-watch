import Foundation
import WatchKit
import UserNotifications

class SessionManager: ObservableObject {
    @Published var activeSession: NapSession?
    @Published var isAlerting = false
    @Published var totalNapMinutes: Int = 0

    private let totalKey = "totalNapMinutes"
    private var alarmTimer: Timer?
    private var alarmNotificationIDs: [String] = []

    init() {
        totalNapMinutes = UserDefaults.standard.integer(forKey: totalKey)
    }

    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
        }
    }

    func startSession(_ session: NapSession) {
        activeSession = session
        isAlerting = false
        scheduleLocalNotification(for: session)
    }

    func endSession() {
        if let session = activeSession {
            let elapsedMin = Int(Date().timeIntervalSince(session.startTime) / 60)
            if elapsedMin > 0 {
                totalNapMinutes += elapsedMin
                UserDefaults.standard.set(totalNapMinutes, forKey: totalKey)
            }
        }
        stopAlerting()
        activeSession = nil
    }

    func resetTotalNapTime() {
        totalNapMinutes = 0
        UserDefaults.standard.set(0, forKey: totalKey)
    }

    func triggerAlert() {
        guard !isAlerting else { return }
        isAlerting = true
        startAlarmLoop()
    }

    func stopAlerting() {
        isAlerting = false
        alarmTimer?.invalidate()
        alarmTimer = nil
        removeAlarmNotifications()
    }

    private func startAlarmLoop() {
        fireHapticPattern()
        sendImmediateAlarmNotification()
        schedulePersistentNotifications()

        alarmTimer?.invalidate()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.fireHapticPattern()
        }
    }

    private func fireHapticPattern() {
        WKInterfaceDevice.current().play(.notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func scheduleLocalNotification(for session: NapSession) {
        let content = UNMutableNotificationContent()
        content.title = "Approaching \(session.destination.name)"
        content.body = "Wake up! Your stop is near."
        content.sound = .default
        content.categoryIdentifier = "ARRIVAL_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "napsafe.arrival", content: content, trigger: trigger)
        addNotificationRequest(request, description: "arrival alert")
    }

    private func sendImmediateAlarmNotification() {
        let content = UNMutableNotificationContent()
        content.title = "WAKE UP NOW"
        content.body = "You are near your destination."
        content.sound = .default
        content.categoryIdentifier = "ARRIVAL_ALERT"
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(identifier: "napsafe.alarm.immediate", content: content, trigger: nil)
        addNotificationRequest(request, description: "immediate alarm")
    }

    private func schedulePersistentNotifications() {
        for index in 1...20 {
            let id = "napsafe.alarm.\(index)"
            alarmNotificationIDs.append(id)

            let content = UNMutableNotificationContent()
            content.title = "WAKE UP NOW"
            content.body = "You are near your destination."
            content.sound = .default
            content.categoryIdentifier = "ARRIVAL_ALERT"
            content.interruptionLevel = .timeSensitive

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(index * 10), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            addNotificationRequest(request, description: "alarm reminder \(index)")
        }
    }

    private func addNotificationRequest(_ request: UNNotificationRequest, description: String) {
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule \(description): \(error)")
            }
        }
    }

    private func removeAlarmNotifications() {
        var idsToRemove = alarmNotificationIDs
        idsToRemove.append("napsafe.alarm.immediate")
        idsToRemove.append("napsafe.arrival")

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: idsToRemove)
        alarmNotificationIDs.removeAll()
    }
}
