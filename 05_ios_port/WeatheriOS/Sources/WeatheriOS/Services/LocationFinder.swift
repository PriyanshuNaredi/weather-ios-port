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
    /// Every caller waiting for the permission dialog, not just the first. The
    /// previous single slot resumed the earlier waiter with `false` and never
    /// called `requestWhenInUseAuthorization()` for the second caller, which then
    /// waited for a delegate callback that had already been delivered — a hang.
    private nonisolated(unsafe) var authWaiters: [CheckedContinuation<Bool, Never>] = []

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
                let alreadyAsking = !authWaiters.isEmpty
                authWaiters.append(continuation)
                lock.unlock()
                // One dialog at a time; every waiter is resumed by the same
                // `locationManagerDidChangeAuthorization` callback.
                if !alreadyAsking { manager.requestWhenInUseAuthorization() }
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
        // The cancellation handler is what makes the caller's timeout real: on
        // cancel it resolves this continuation with nil, so the awaiting task
        // finishes instead of being pinned by the parent's task group.
        await withTaskCancellationHandler {
            let coordinate = await withCheckedContinuation { continuation in
                lock.lock()
                // A previous attempt that timed out may still hold the slot;
                // resolve it rather than leaking it.
                let stale = locationContinuation
                locationContinuation = continuation
                lock.unlock()
                stale?.resume(returning: nil)
                manager.requestLocation()
            }
            return coordinate.map { ($0.latitude, $0.longitude) }
        } onCancel: {
            lock.lock()
            let pending = locationContinuation
            locationContinuation = nil
            lock.unlock()
            pending?.resume(returning: nil)
        }
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
        let waiters = authWaiters
        authWaiters = []
        lock.unlock()
        guard !waiters.isEmpty else { return }
        let granted: Bool
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: granted = true
        default: granted = false
        }
        for waiter in waiters { waiter.resume(returning: granted) }
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
