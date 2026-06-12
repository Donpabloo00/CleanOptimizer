// CleanView.swift
import SwiftUI

struct CleanView: View {
    @StateObject private var cleaner = CacheCleaner()
    @State private var resultMessage = ""
    @State private var showResultAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Cleanup")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Select elements to scan and safely clean system caches and logs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Total Junk Found Indicator
                VStack(alignment: .trailing) {
                    Text("Junk Found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cleaner.totalJunkSizeString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // List of Cleanup items
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<cleaner.items.count, id: \.self) { index in
                        HStack(spacing: 16) {
                            // Checkbox
                            Button(action: {
                                cleaner.items[index].isSelected.toggle()
                            }) {
                                Image(systemName: cleaner.items[index].isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(cleaner.items[index].isSelected ? .accentColor : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            // Item Detail
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cleaner.items[index].name)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                Text(cleaner.items[index].description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Computed Size
                            Text(cleaner.formatBytes(cleaner.items[index].size))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Actions panel
            HStack(spacing: 16) {
                // Scan Button
                Button(action: {
                    cleaner.scan()
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text(cleaner.isScanning ? "Scanning..." : "Scan System")
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.bordered)
                .disabled(cleaner.isScanning || cleaner.isCleaning)
                
                // Clean Button
                Button(action: {
                    cleaner.clean { message in
                        resultMessage = message
                        showResultAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text(cleaner.isCleaning ? "Cleaning..." : "Clean Junk")
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(cleaner.isScanning || cleaner.isCleaning)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .onAppear {
            cleaner.scan()
        }
        .alert(isPresented: $showResultAlert) {
            Alert(title: Text("Cleanup Complete"),
                  message: Text(resultMessage),
                  dismissButton: .default(Text("Done")))
        }
    }
}

struct CleanView_Previews: PreviewProvider {
    static var previews: some View {
        CleanView()
    }
}
