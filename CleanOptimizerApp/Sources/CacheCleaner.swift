// CacheCleaner.swift
import Foundation

struct CleanupItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let paths: [URL]
    var size: UInt64 = 0
    var isSelected: Bool = true
}

final class CacheCleaner: ObservableObject {
    @Published var items: [CleanupItem] = [
        CleanupItem(
            name: "User Caches",
            description: "Temporary files created by applications.",
            paths: [FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!]
        ),
        CleanupItem(
            name: "System Logs",
            description: "Diagnostic records and crash reports.",
            paths: [FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")]
        ),
        CleanupItem(
            name: "Safari Caches",
            description: "Websites cache files and cookies.",
            paths: [FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Safari/Cache")]
        ),
        CleanupItem(
            name: "Temporary Files",
            description: "Temporary system files generated during operations.",
            paths: [URL(fileURLWithPath: NSTemporaryDirectory())]
        )
    ]
    
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var totalJunkSizeString = "0 KB"
    
    func scan() {
        guard !isScanning else { return }
        isScanning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var updatedItems = self.items
            var grandTotal: UInt64 = 0
            
            for i in 0..<updatedItems.count {
                var size: UInt64 = 0
                for path in updatedItems[i].paths {
                    size += self.getDirectorySize(at: path)
                }
                updatedItems[i].size = size
                grandTotal += size
            }
            
            DispatchQueue.main.async {
                self.items = updatedItems
                self.totalJunkSizeString = self.formatBytes(grandTotal)
                self.isScanning = false
            }
        }
    }
    
    func clean(completion: @escaping (String) -> Void) {
        guard !isCleaning else { return }
        isCleaning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var clearedCount = 0
            var clearedBytes: UInt64 = 0
            
            for i in 0..<self.items.count {
                let item = self.items[i]
                guard item.isSelected else { continue }
                
                for path in item.paths {
                    let (count, bytes) = self.clearDirectory(at: path)
                    clearedCount += count
                    clearedBytes += bytes
                }
            }
            
            // Re-calculate size after clean
            var updatedItems = self.items
            for j in 0..<updatedItems.count {
                var size: UInt64 = 0
                for path in updatedItems[j].paths {
                    size += self.getDirectorySize(at: path)
                }
                updatedItems[j].size = size
            }
            
            DispatchQueue.main.async {
                self.items = updatedItems
                self.totalJunkSizeString = "0 KB"
                self.isCleaning = false
                completion("Cleaned \(clearedCount) items (\(self.formatBytes(clearedBytes))) successfully.")
            }
        }
    }
    
    private func getDirectorySize(at url: URL) -> UInt64 {
        var size: UInt64 = 0
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles], errorHandler: nil) else {
            return 0
        }
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    size += UInt64(fileSize)
                }
            } catch {
                continue
            }
        }
        return size
    }
    
    private func clearDirectory(at url: URL) -> (Int, UInt64) {
        var count = 0
        var bytes: UInt64 = 0
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return (0, 0) }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [])
            for itemURL in contents {
                do {
                    let resourceValues = try itemURL.resourceValues(forKeys: [.fileSizeKey])
                    let size = UInt64(resourceValues.fileSize ?? 0)
                    try fileManager.removeItem(at: itemURL)
                    count += 1
                    bytes += size
                } catch {
                    continue
                }
            }
        } catch {
            // ignore
        }
        return (count, bytes)
    }
    
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
