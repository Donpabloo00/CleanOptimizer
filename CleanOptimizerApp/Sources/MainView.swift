// MainView.swift
import SwiftUI
import AppKit

struct MainView: View {
    @State private var selectedTab: TabType = .clean
    
    enum TabType {
        case clean, optimize, uninstall, email
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            VStack(alignment: .leading, spacing: 16) {
                // App Logo
                HStack(spacing: 10) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CleanOptimizer")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("v1.0")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                .padding(.top, 10)
                
                // Sidebar Buttons
                SidebarButton(title: "Cleaner", icon: "trash", isSelected: selectedTab == .clean) {
                    selectedTab = .clean
                }
                
                SidebarButton(title: "Optimizer", icon: "speedometer", isSelected: selectedTab == .optimize) {
                    selectedTab = .optimize
                }
                
                SidebarButton(title: "Uninstaller", icon: "xmark.bin", isSelected: selectedTab == .uninstall) {
                    selectedTab = .uninstall
                }
                
                SidebarButton(title: "Mailbox", icon: "envelope", isSelected: selectedTab == .email) {
                    selectedTab = .email
                }
                
                Spacer()
                
                // Footer
                Text("AppConsultDeck")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(width: 170)
            .background(Color.secondary.opacity(0.03))
            
            Divider()
            
            // Content Pane
            ZStack {
                switch selectedTab {
                case .clean:
                    CleanView()
                case .optimize:
                    OptimizeView()
                case .uninstall:
                    UninstallView()
                case .email:
                    EmailView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 750, minHeight: 480)
        .background(BlurView()) // glassmorphism effect
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : (isHovering ? Color.secondary.opacity(0.06) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovering = hover
        }
    }
}

// Simple blur view for glassmorphism
struct BlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .hudWindow
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualEffect)
        NSLayoutConstraint.activate([
            visualEffect.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visualEffect.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
