@preconcurrency import CoreLocation
import Foundation

// iOS port of `MainActivity.kt:500-516 findLocation` and the permission launcher
// (lines 122-126). Kotlin picks NETWORK or GPS provider, returns the last known
// fix when fresher than 10 minutes, otherwise requests a single current fix with
// an 18 s outer timeout. iOS maps this to CLLocationManager with
// `requestWhenInUseAuthorization` + `requestLocation`.
//
// Project rule: never register a device or touch Apple services — CoreLocation
// only queries the local device, no Apple ID, signing or provisioning involved.

final class LocationFinder: NSObject, CLLocationManagerDelegate {
    nonisolated(unsafe) static let shared = LocationFinder()

    private let manager = CLLocationManager()
    // Lock-guarded continuation state: CLLocationManager delivers delegate
    // callbacks on arbitrary queue threads.
    private let lock = NSLock()
    private nonisolated(unsafe) var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private nonisolated(unsafe) var authContinuation: CheckedContinuation<Bool, Never>?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // Kotlin permission launcher (lines 122-126): if already granted → true;
    // otherwise request and report whether any grant came back.
    func ensureAuthorized() async -> Bool {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                lock.lock()
                if let existing = authContinuation {
                    authContinuation = nil
                    lock.unlock()
                    existing.resume(returning: false)
                    authContinuation = continuation
                } else {
                    authContinuation = continuation
                    lock.unlock()
                    manager.requestWhenInUseAuthorization()
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // Kotlin `findLocation` — last known fix if < 10 minutes old, else a single
    // fresh fix. Caller applies the 18 s timeout.
    func currentLocation() async -> (Double, Double)? {
        let coordinate = await withCheckedContinuation { continuation in
            lock.lock()
            locationContinuation = continuation
            lock.unlock()
            manager.requestLocation()
        }
        return coordinate.map { ($0.latitude, $0.longitude) }
    }

    // Kotlin `withTimeoutOrNull(18000)` (line 116) — 18 s outer timeout.
    func locateOnce() async -> (Double, Double)? {
        await withTaskGroup(of: (Double, Double)?.self) { group in
            group.addTask { await Self.shared.currentLocation() }
            group.addTask {
                try? await Task.sleep(nanoseconds: 18_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        lock.lock()
        let continuation = authContinuation
        authContinuation = nil
        lock.unlock()
        guard let continuation else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            continuation.resume(returning: true)
        default:
            continuation.resume(returning: false)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()
        continuation?.resume(returning: locations.last?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()
        continuation?.resume(returning: nil)
    }
}
