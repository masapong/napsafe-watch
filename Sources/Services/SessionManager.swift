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

    private static let arrivalNotificationID = "napsafe.arrival"
    private static let immediateAlarmID = "napsafe.alarm.immediate"
    private static let persistentAlarmCount = 20
    private static let persistentAlarmInterval: TimeInterval = 10

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
        stopAlerting()
        activeSession = session
        isAlerting = false
        // Do not schedule an arrival notification here — proximity is handled by LocationManager.
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
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.fireHapticPattern()
        }
        RunLoop.main.add(timer, forMode: .common)
        alarmTimer = timer
    }

    private func fireHapticPattern() {
        WKInterfaceDevice.current().play(.notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func makeAlarmContent(title: String, body: String, timeSensitive: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ARRIVAL_ALERT"
        if timeSensitive {
            content.interruptionLevel = .timeSensitive
        }
        return content
    }

    private func sendImmediateAlarmNotification() {
        let content = makeAlarmContent(
            title: "WAKE UP NOW",
            body: "You are near your destination.",
            timeSensitive: true
        )
        let request = UNNotificationRequest(identifier: Self.immediateAlarmID, content: content, trigger: nil)
        addNotificationRequest(request, description: "immediate alarm")
    }

    private func schedulePersistentNotifications() {
        for index in 1...Self.persistentAlarmCount {
            let id = "napsafe.alarm.\(index)"
            alarmNotificationIDs.append(id)

            let content = makeAlarmContent(
                title: "WAKE UP NOW",
                body: "You are near your destination.",
                timeSensitive: true
            )
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: Double(index) * Self.persistentAlarmInterval,
                repeats: false
            )
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
        idsToRemove.append(Self.immediateAlarmID)
        idsToRemove.append(Self.arrivalNotificationID)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: idsToRemove)
        alarmNotificationIDs.removeAll()
    }
}
