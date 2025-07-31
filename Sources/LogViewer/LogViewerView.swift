import SwiftUI
import OSLog

struct LogViewerView: View {
    @ObservedObject private var viewModel: LogViewerViewModel
    @Binding private var showSidebar: Bool
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    private let levelStrings: [OSLogEntryLog.Level: String] = [
        .debug: "DEBUG",
        .info: "INFO",
        .notice: "NOTICE",
        .error: "ERROR",
        .fault: "FAULT"
    ]
    
    init(viewModel: LogViewerViewModel, showSidebar: Binding<Bool>) {
        self.viewModel = viewModel
        self._showSidebar = showSidebar
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            logList
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var toolbar: some View {
        HStack {
            Button(action: {
                logger.info("User clicked pause/resume button")
                viewModel.togglePause()
            }) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
            }
            .help(viewModel.isPaused ? "Resume logging" : "Pause logging")
            
            Button(action: {
                logger.notice("User clicked clear logs button")
                viewModel.clearLogs()
            }) {
                Image(systemName: "trash")
            }
            .help("Clear logs")
            
            SearchBar(text: $viewModel.searchText, logger: logger)
        }
        .padding()
    }
    
    private var logList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.logEntries) { entry in
                    LogEntryRow(entry: entry)
                        .padding(.horizontal, 12)
                }
            }
        }
        .background(.white)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let logger: Logger
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search logs...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: text) { oldValue, newValue in
                    if newValue.isEmpty && !oldValue.isEmpty {
                        logger.info("User cleared search field")
                    } else if !newValue.isEmpty {
                        logger.debug("User updated search text: '\(newValue)'")
                    }
                }
            
            if !text.isEmpty {
                Button(action: {
                    logger.info("User clicked search clear button")
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Self.timeFormatter.string(from: entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.levelString)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.levelColor.opacity(0.2))
                    .foregroundColor(entry.levelColor)
                    .cornerRadius(4)
                
                Text(entry.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.message)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LogViewerView(viewModel: LogViewerViewModel(logService: LogService(), logCategories: [LogCategory(category: "Cat 1"), LogCategory(category: "Cat 2")]), showSidebar: .constant(true))
}
