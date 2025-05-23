import SwiftUI
import OSLog

struct LogView: View {
    @ObservedObject private var viewModel: LogViewModel
    @State private var showFilters = false
    
    private let levelStrings: [OSLogEntryLog.Level: String] = [
        .debug: "DEBUG",
        .info: "INFO",
        .notice: "NOTICE",
        .error: "ERROR",
        .fault: "FAULT"
    ]
    
    init(viewModel: LogViewModel) {
        self.viewModel = viewModel
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
            Button(action: viewModel.togglePause) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
            }
            .help(viewModel.isPaused ? "Resume logging" : "Pause logging")
            
            Button(action: viewModel.clearLogs) {
                Image(systemName: "trash")
            }
            .help("Clear logs")
            
            Button(action: { showFilters.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .help("Show filters")
            
            SearchBar(text: $viewModel.searchText)
        }
        .padding()
    }
    
    private var logList: some View {
        HSplitView {
            if showFilters {
                filterPanel
                    .frame(width: 250)
            }
            
            List(viewModel.logEntries) { entry in
                LogEntryRow(entry: entry)
            }
        }
    }
    
    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filters")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Log Levels")
                    .font(.subheadline)
                
                ForEach([OSLogEntryLog.Level.debug, .info, .notice, .error, .fault], id: \.self) { level in
                    Toggle(levelStrings[level] ?? "UNKNOWN", isOn: Binding(
                        get: { viewModel.selectedLevels.contains(level) },
                        set: { isSelected in
                            var levels = viewModel.selectedLevels
                            if isSelected {
                                levels.insert(level)
                            } else {
                                levels.remove(level)
                            }
                            viewModel.setSelectedLevels(levels)
                        }
                    ))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Categories")
                    .font(.subheadline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.selectedCategories.sorted()), id: \.self) { category in
                            Toggle(category, isOn: Binding(
                                get: { viewModel.selectedCategories.contains(category) },
                                set: { isSelected in
                                    var categories = viewModel.selectedCategories
                                    if isSelected {
                                        categories.insert(category)
                                    } else {
                                        categories.remove(category)
                                    }
                                    viewModel.setSelectedCategories(categories)
                                }
                            ))
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search logs...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.timestamp, style: .time)
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
    LogView(viewModel: LogViewModel(logService: LogService()))
} 