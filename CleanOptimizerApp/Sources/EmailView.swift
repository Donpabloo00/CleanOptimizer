// EmailView.swift
import SwiftUI

struct EmailView: View {
    @StateObject private var emailCleaner = EmailCleaner()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mailbox Cleaner")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Choose your Gmail or other accounts to clean up.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { emailCleaner.fetchAccountsAndInbox() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.bordered)
                .disabled(emailCleaner.isLoading)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Selector row
            if !emailCleaner.accounts.isEmpty {
                HStack(spacing: 16) {
                    // Account Dropdown
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Picker("", selection: $emailCleaner.selectedAccountName) {
                            ForEach(emailCleaner.accounts) { acc in
                                Text(acc.name).tag(acc.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .onChange(of: emailCleaner.selectedAccountName) { newAccount in
                            if let accObj = emailCleaner.accounts.first(where: { $0.name == newAccount }) {
                                emailCleaner.selectedMailboxName = accObj.mailboxes.first(where: { $0.localizedCaseInsensitiveContains("INBOX") }) ?? accObj.mailboxes.first ?? ""
                                emailCleaner.fetchInbox()
                            }
                        }
                    }
                    
                    // Mailbox Dropdown
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mailbox")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Picker("", selection: $emailCleaner.selectedMailboxName) {
                            if let selectedAcc = emailCleaner.accounts.first(where: { $0.name == emailCleaner.selectedAccountName }) {
                                ForEach(selectedAcc.mailboxes, id: \.self) { box in
                                    Text(box).tag(box)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .onChange(of: emailCleaner.selectedMailboxName) { _ in
                            emailCleaner.fetchInbox()
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.04))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
            
            if emailCleaner.isLoading {
                VStack {
                    Spacer()
                    ProgressView(emailCleaner.statusMessage)
                    Spacer()
                }
            } else if emailCleaner.messages.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 64))
                        .foregroundColor(.green.opacity(0.8))
                    Text("Mailbox is Clean!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(emailCleaner.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                // Show top card
                let currentMessage = emailCleaner.messages[0]
                
                VStack(spacing: 16) {
                    // Queue length indicator
                    Text("Reviewing \(emailCleaner.messages.count) emails in \(emailCleaner.selectedMailboxName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Email Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.accentColor)
                            Text("Sender:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentMessage.sender)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            Spacer()
                        }
                        
                        Divider()
                        
                        Text(currentMessage.subject)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)
                            .frame(minHeight: 80, alignment: .topLeading)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons (Red and Green)
                    HStack(spacing: 40) {
                        // Delete Button (Red)
                        Button(action: {
                            withAnimation(.spring()) {
                                emailCleaner.deleteMessage(id: currentMessage.id)
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 3)
                                Text("Delete")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .bold()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Keep / Read Button (Green)
                        Button(action: {
                            withAnimation(.spring()) {
                                emailCleaner.markAsRead(id: currentMessage.id)
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                                Text("Keep")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .bold()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 10)
                }
                
                // Upcoming Preview
                if emailCleaner.messages.count > 1 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next in Queue:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.secondary)
                            Text(emailCleaner.messages[1].subject)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.03))
                        .cornerRadius(6)
                        .padding(.horizontal)
                    }
                }
            }
            Spacer()
        }
        .onAppear {
            emailCleaner.fetchAccountsAndInbox()
        }
    }
}

struct EmailView_Previews: PreviewProvider {
    static var previews: some View {
        EmailView()
    }
}
