import Foundation

func logToStandardError(_ message: String) {
    let datedMessage = Date().formatted(.iso8601) + " " + message + "\n"
    let datedMessageData = Data(datedMessage.utf8)
    try? FileHandle.standardError.write(contentsOf: datedMessageData)
}
