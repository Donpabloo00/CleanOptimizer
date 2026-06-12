// EmailCleaner.swift
import Foundation
import ShellOut

struct MailMessage: Identifiable, Equatable {
    let id: String
    let sender: String
    let subject: String
    var isRead: Bool
}

struct MailAccount: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let mailboxes: [String]
}

final class EmailCleaner: ObservableObject {
    @Published var messages: [MailMessage] = []
    @Published var accounts: [MailAccount] = []
    @Published var selectedAccountName = ""
    @Published var selectedMailboxName = ""
    @Published var isLoading = false
    @Published var statusMessage = ""
    
    func fetchAccountsAndInbox() {
        guard !isLoading else { return }
        isLoading = true
        statusMessage = "Loading mail accounts..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let accountsScript = """
            tell application "Mail"
                set output to ""
                try
                    set accList to every account
                    repeat with acc in accList
                        set accName to name of acc
                        set output to output & accName & "||"
                        set boxList to mailboxes of acc
                        set boxNames to {}
                        repeat with box in boxList
                            set end of boxNames to name of box
                        end repeat
                        set oldDelims to AppleScript's text item delimiters
                        set AppleScript's text item delimiters to ","
                        set boxString to boxNames as string
                        set AppleScript's text item delimiters to oldDelims
                        set output to output & boxString & "\\n"
                    end repeat
                on error err
                    set output to "error: " & err
                end try
                return output
            end tell
            """
            
            let tempFile = NSTemporaryDirectory() + "fetch_accounts.scpt"
            do {
                try accountsScript.write(toFile: tempFile, atomically: true, encoding: .utf8)
                let rawOutput = try shellOut(to: "osascript", arguments: [tempFile])
                
                var parsedAccounts: [MailAccount] = []
                let lines = rawOutput.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.components(separatedBy: "||")
                    if parts.count == 2 {
                        let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let mailboxesStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let mailboxes = mailboxesStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        
                        if !name.isEmpty {
                            parsedAccounts.append(MailAccount(name: name, mailboxes: mailboxes))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.accounts = parsedAccounts
                    if !parsedAccounts.isEmpty {
                        // Pre-select Google or first account
                        if self.selectedAccountName.isEmpty {
                            if let googleAcc = parsedAccounts.first(where: { $0.name.localizedCaseInsensitiveContains("Google") || $0.name.localizedCaseInsensitiveContains("Gmail") }) {
                                self.selectedAccountName = googleAcc.name
                                self.selectedMailboxName = googleAcc.mailboxes.first(where: { $0.localizedCaseInsensitiveContains("INBOX") }) ?? googleAcc.mailboxes.first ?? ""
                            } else {
                                self.selectedAccountName = parsedAccounts[0].name
                                self.selectedMailboxName = parsedAccounts[0].mailboxes.first(where: { $0.localizedCaseInsensitiveContains("INBOX") }) ?? parsedAccounts[0].mailboxes.first ?? ""
                            }
                        }
                    }
                    self.isLoading = false
                    self.fetchInbox()
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Error fetching accounts: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchInbox() {
        guard !selectedAccountName.isEmpty && !selectedMailboxName.isEmpty else {
            statusMessage = "Select an account and mailbox first."
            return
        }
        
        isLoading = true
        statusMessage = "Fetching messages..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "Mail"
                set output to ""
                try
                    set msgList to messages of mailbox "\(self.selectedMailboxName)" of account "\(self.selectedAccountName)"
                    set msgCount to count of msgList
                    set limit to 30
                    if msgCount < limit then
                        set limit to msgCount
                    end if
                    repeat with i from 1 to limit
                        set msg to item i of msgList
                        set msgSubject to subject of msg
                        set msgSender to sender of msg
                        set msgId to id of msg
                        set msgRead to read status of msg
                        set output to output & msgId & "||" & msgSender & "||" & msgSubject & "||" & msgRead & "\\n"
                    end repeat
                on error err
                    set output to "error: " & err
                end try
                return output
            end tell
            """
            
            let tempFile = NSTemporaryDirectory() + "fetch_emails.scpt"
            do {
                try script.write(toFile: tempFile, atomically: true, encoding: .utf8)
                let rawOutput = try shellOut(to: "osascript", arguments: [tempFile])
                
                var parsedMessages: [MailMessage] = []
                let lines = rawOutput.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.components(separatedBy: "||")
                    if parts.count == 4 {
                        let id = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let sender = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let subject = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
                        let isRead = parts[3].trimmingCharacters(in: .whitespacesAndNewlines) == "true"
                        
                        if !id.isEmpty {
                            parsedMessages.append(MailMessage(id: id, sender: sender, subject: subject, isRead: isRead))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.messages = parsedMessages
                    self.isLoading = false
                    self.statusMessage = parsedMessages.isEmpty ? "No messages found in \(self.selectedMailboxName)." : "Successfully fetched \(parsedMessages.count) messages."
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.statusMessage = "Error fetching inbox: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteMessage(id: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages.remove(at: index)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "Mail"
                try
                    set msg to first message of mailbox "\(self.selectedMailboxName)" of account "\(self.selectedAccountName)" whose id is \(id)
                    delete msg
                    return "success"
                on error err
                    return "error: " & err
                end try
            end tell
            """
            
            let tempFile = NSTemporaryDirectory() + "delete_email.scpt"
            _ = try? script.write(toFile: tempFile, atomically: true, encoding: .utf8)
            _ = try? shellOut(to: "osascript", arguments: [tempFile])
        }
    }
    
    func markAsRead(id: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages.remove(at: index)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "Mail"
                try
                    set msg to first message of mailbox "\(self.selectedMailboxName)" of account "\(self.selectedAccountName)" whose id is \(id)
                    set read status of msg to true
                    return "success"
                on error err
                    return "error: " & err
                end try
            end tell
            """
            
            let tempFile = NSTemporaryDirectory() + "read_email.scpt"
            _ = try? script.write(toFile: tempFile, atomically: true, encoding: .utf8)
            _ = try? shellOut(to: "osascript", arguments: [tempFile])
        }
    }
}
