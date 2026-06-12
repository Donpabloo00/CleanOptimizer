// OptimizeView.swift
import SwiftUI
import ShellOut

struct OptimizationTask: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let command: String
}

struct OptimizeView: View {
    @State private var isRunning = false
    @State private var outputLog = "Terminal Output:\nReady to run system optimization tasks..."
    @State private var progressText = ""
    
    let tasks: [OptimizationTask] = [
        OptimizationTask(
            title: "Purge Inactive RAM",
            description: "Forces macOS to clear inactive memory caches, freeing up physical RAM.",
            icon: "memorychip",
            command: "purge"
        ),
        OptimizationTask(
            title: "Rebuild Spotlight Search Index",
            description: "Cleans and re-indexes the system Spotlight database for faster search.",
            icon: "magnifyingglass",
            command: "mdutil -E /"
        ),
        OptimizationTask(
            title: "Optimize System Standby Settings",
            description: "Adjusts macOS PM settings to delay standby mode and improve wake-up times.",
            icon: "battery.100.bolt",
            command: "pmset -a standbydelaylow 86400"
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Optimization")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Enhance your Mac's speed and efficiency using low-level tweaks.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Optimization Info Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: task.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                            
                            Text(task.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            
                            Text(task.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(width: 180, height: 140)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 150)
            
            // Output terminal console log
            VStack(alignment: .leading, spacing: 0) {
                // Console Header
                HStack {
                    Image(systemName: "terminal")
                        .foregroundColor(.green)
                    Text("Console Logs")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(height: 12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.85))
                
                // Terminal text
                ScrollView {
                    Text(outputLog)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                .background(Color.black)
            }
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
            
            // Main Button
            Button(action: runOptimization) {
                HStack(spacing: 10) {
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(isRunning ? "Executing Tweaks..." : "Run System Optimization")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private func runOptimization() {
        isRunning = true
        outputLog = "Requesting administrator privileges to run optimizations...\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Combine all the task commands with && so they execute sequentially
            let combinedCmd = tasks.map { $0.command }.joined(separator: " && ")
            let script = "osascript -e 'do shell script \"\(combinedCmd)\" with administrator privileges'"
            
            do {
                let result = try shellOut(to: script)
                DispatchQueue.main.async {
                    outputLog += "Optimizations completed successfully!\n\nDetails:\n\(result)\n"
                }
            } catch {
                DispatchQueue.main.async {
                    outputLog += "Optimization failed or cancelled.\nError details:\n\(error.localizedDescription)\n"
                }
            }
            DispatchQueue.main.async {
                isRunning = false
            }
        }
    }
}

struct OptimizeView_Previews: PreviewProvider {
    static var previews: some View {
        OptimizeView()
    }
}
