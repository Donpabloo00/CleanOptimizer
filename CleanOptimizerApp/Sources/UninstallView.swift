import SwiftUI
import AppKit

struct UninstallView: View {
    @State private var apps: [URL] = []
    @State private var selectedApp: URL? = nil
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showConfirmAlert = false
    @State private var appSizes: [URL: String] = [:]
    @State private var isScanning = false

    var filteredApps: [URL] {
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Search Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Uninstaller")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Find and uninstall system applications and clean their caches.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 12)

            // Content List
            if isScanning {
                VStack {
                    Spacer()
                    ProgressView("Scanning Applications...")
                    Spacer()
                }
            } else {
                List(filteredApps, id: \.self) { app in
                    HStack(spacing: 12) {
                        // Get native app icon from macOS workspace
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .cornerRadius(6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text(app.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // App Size
                        Text(appSizes[app] ?? "Calculating...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(6)
                    .background(selectedApp == app ? Color.accentColor.opacity(0.15) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedApp = app
                    }
                    .cornerRadius(8)
                }
                .listStyle(.inset)
                .frame(minHeight: 250)
            }

            // Bottom action panel
            HStack {
                Button(action: loadApps) {
                    Label("Refresh List", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isScanning)
                
                Spacer()
                
                Button(role: .destructive, action: {
                    showConfirmAlert = true
                }) {
                    Label("Uninstall Selected", systemImage: "trash")
                        .frame(minWidth: 140, minHeight: 24)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedApp == nil)
            }
            .padding()
            .background(Color.secondary.opacity(0.03))
        }
        .onAppear(perform: loadApps)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Are you sure you want to uninstall this app?", isPresented: $showConfirmAlert, titleVisibility: .visible) {
            Button("Uninstall \(selectedApp?.lastPathComponent ?? "Selected App")", role: .destructive) {
                uninstallSelected()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func loadApps() {
        isScanning = true
        let appsURL = URL(fileURLWithPath: "/Applications")
        let fileManager = FileManager.default
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let contents = try? fileManager.contentsOfDirectory(at: appsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                let sortedApps = contents.filter { $0.pathExtension == "app" }.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
                
                DispatchQueue.main.async {
                    self.apps = sortedApps
                    self.isScanning = false
                    // Start calculating sizes asynchronously
                    for app in sortedApps {
                        self.calculateSize(for: app)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            }
        }
    }

    func calculateSize(for url: URL) {
        DispatchQueue.global(qos: .utility).async {
            var size: UInt64 = 0
            let fileManager = FileManager.default
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles], errorHandler: nil) {
                for case let fileURL as URL in enumerator {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let fileSize = resourceValues.fileSize {
                        size += UInt64(fileSize)
                    }
                }
            }
            
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useAll]
            formatter.countStyle = .file
            let sizeString = formatter.string(fromByteCount: Int64(size))
            
            DispatchQueue.main.async {
                self.appSizes[url] = sizeString
            }
        }
    }

    func uninstallSelected() {
        guard let url = selectedApp else { return }
        let fileManager = FileManager.default
        var successes: [String] = []
        var failures: [String] = []
        
        do {
            // Move selected app to Trash
            try fileManager.trashItem(at: url, resultingItemURL: nil)
            successes.append(url.lastPathComponent)
            
            // Clean up typical app support files (~/Library/Application Support/AppName)
            let appName = url.lastPathComponent.replacingOccurrences(of: ".app", with: "")
            let supportDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support").appendingPathComponent(appName)
            if fileManager.fileExists(atPath: supportDir.path) {
                try fileManager.removeItem(at: supportDir)
                successes.append("Associated Application Support files")
            }
            
            // Clean up caches (~/Library/Caches/bundleIdentifier or AppName)
            let cacheDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches").appendingPathComponent(appName)
            if fileManager.fileExists(atPath: cacheDir.path) {
                try fileManager.removeItem(at: cacheDir)
                successes.append("Associated cache files")
            }
            
        } catch {
            failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
        }
        
        selectedApp = nil
        alertMessage = successes.isEmpty ? "No apps were removed." : "Removed:\n" + successes.map { "• \($0)" }.joined(separator: "\n") + (failures.isEmpty ? "" : "\n\nFailures:\n\(failures.joined(separator: "\n"))")
        showAlert = true
        loadApps()
    }
}

struct UninstallView_Previews: PreviewProvider {
    static var previews: some View {
        UninstallView()
    }
}
