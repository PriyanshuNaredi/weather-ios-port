import Foundation
#if canImport(os)
import os
#endif

// Structured debug logging for the runtime-debugging mission (Phase 1).
// Every event goes to (a) os.Logger subsystem dev.kiankonrad.weather,
// category "stability" — visible via Console.app on a connected Mac — and
// (b) the in-app DiagLog ring buffer, so the Diagnostics screen can show and
// export the trail on the device itself without any Mac tooling.
// Instrumentation is compiled into ALL configurations of this diagnostic
// build (temporary by design; removed once the device issues are resolved).
// PRIVACY: never log coordinates, city names or any user content — only
// counts, screen names and opaque identifiers.

enum Diag {
    #if canImport(os)
    private static let log = Logger(subsystem: "dev.kiankonrad.weather", category: "stability")
    #endif

    /// `message` must already be scrubbed of coordinates/city names.
    static func event(_ message: @autoclosure () -> String) {
        let text = message()   // evaluate once; Logger interpolation is escaping
        DiagLog.shared.record(text)
        #if canImport(os)
        log.debug("\(text, privacy: .public)")
        #else
        print("[weather] \(text)")
        #endif
    }
}
