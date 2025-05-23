import OSLog
import SwiftUI

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: OSLogEntryLog.Level
    let category: String
    let subsystem: String
    let message: String

    var levelColor: Color {
        switch level {
        case .debug:
            return .gray
        case .info:
            return .blue
        case .notice:
            return .green
        case .error:
            return .red
        case .fault:
            return .purple
        @unknown default:
            return .black
        }
    }

    var levelString: String {
        switch level {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .notice:
            return "NOTICE"
        case .error:
            return "ERROR"
        case .fault:
            return "FAULT"
        @unknown default:
            return "UNKNOWN"
        }
    }
}
