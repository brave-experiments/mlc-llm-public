//
//  PerformanceMetrics.swift
//  MLCChat
//
//  Created by Kleomenis Katevas on 07/06/2023.
//

import Foundation


struct ConversationRecord: Codable {
    let modelName: String
    var modelLoadTime: TimeRecord?
    var questionRecords: [QuestionRecord] = []
    
    init(modelName: String) {
        self.modelName = modelName
    }
}

struct QuestionRecord: Codable {
    let time: TimeRecord
    let input, output: String
    let original_session_tokens, input_tokens, output_tokens: Int
    let runtimeStats: String
}

struct TimeRecord: Codable {
    let start: Date
    let duration: TimeInterval
}

class ConversationsRecordManager: ObservableObject {
    @Published private var conversations: [ConversationRecord] = []

    func addConversationRecord(_ conversation: ConversationRecord) {
        conversations.append(conversation)
    }

    func saveToFile(withFileName fileName: String) {
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = directoryURL.appendingPathComponent("\(fileName).json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .custom { (date, encoder) in
            var container = encoder.singleValueContainer()
            let timestamp = date.timeIntervalSince1970
            try container.encode(timestamp)
        }
        
        do {
            let data = try encoder.encode(conversations)
            try data.write(to: fileURL)
            print("Energy measurements JSON file successfully saved at \(fileURL)")
        } catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
    }
}
