//
//  ChatState.swift
//  LLMChat
//

import Foundation
import MLCSwift

enum MessageRole {
    case user
    case bot
}

extension MessageRole {
    var isUser: Bool { self == .user }
}

struct MessageData: Hashable {
    let id = UUID()
    var role: MessageRole
    var message: String
}

final class ChatState: ObservableObject {
    fileprivate enum ModelChatState {
        case generating
        case resetting
        case reloading
        case terminating
        case ready
        case failed
        case pendingImageUpload
        case processingImage
    }
    
    @Published var messages = [MessageData]()
    @Published var infoText = ""
    @Published var displayName = ""
    @Published var useVision = false
    
    private let modelChatStateLock = NSLock()
    private var modelChatState: ModelChatState = .ready
    
    private let threadWorker = ThreadWorker()
    private let chatModule = ChatModule()
    private var modelLib = ""
    private var modelPath = ""
    var modelID = ""
    
    var modelLoadTime: TimeRecord?
    
    init() {
        threadWorker.qualityOfService = QualityOfService.userInteractive
        threadWorker.start()
        
        RestAwaitLib.requestPermission()
    }
    
    func getFileURLFromName(_ name: String) -> URL {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent(name)
        return destinationURL
    }
    
    // read input.json and return [[questions]] (conversation with questions)
    func readInputFile() -> [[String]] {
        
        let url = getFileURLFromName("input.json")
        do {
            // Load the data from the file into a Data object
            let data = try Data(contentsOf: url)
            
            // Decode the JSON data
            let jsonDecoder = JSONDecoder()
            let questions = try jsonDecoder.decode([[String]].self, from: data)
            
            return questions
            
        } catch {
            print("Error reading or decoding file: \(error)")
            return []
        }
    }
    
    var isInterruptible: Bool {
        return getModelChatState() == .ready
        || getModelChatState() == .generating
        || getModelChatState() == .failed
        || getModelChatState() == .pendingImageUpload
    }
    
    var isChattable: Bool {
        return getModelChatState() == .ready
    }
    
    var isUploadable: Bool {
        return getModelChatState() == .pendingImageUpload
    }
    
    var isResettable: Bool {
        return getModelChatState() == .ready
        || getModelChatState() == .generating
    }
    
    func requestResetChat() {
        assert(isResettable)
        interruptChat(prologue: {
            switchToResetting()
        }, epilogue: { [weak self] in
            self?.mainResetChat()
        })
    }
    
    func requestTerminateChat(callback: @escaping () -> Void) {
        assert(isInterruptible)
        interruptChat(prologue: {
            switchToTerminating()
        }, epilogue: { [weak self] in
            self?.mainTerminateChat(callback: callback)
        })
    }
    
    func requestReloadChat(modelID: String, modelLib: String, modelPath: String, estimatedVRAMReq: Int, displayName: String) {
        if (isCurrentModel(modelID: modelID)) {
            return
        }
        assert(isInterruptible)
        interruptChat(prologue: {
            switchToReloading()
        }, epilogue: { [weak self] in
            self?.mainReloadChat(modelID: modelID,
                                 modelLib: modelLib,
                                 modelPath: modelPath,
                                 estimatedVRAMReq: estimatedVRAMReq,
                                 displayName: displayName)
        })
    }
    
    func requestGenerate(prompt: String) {
        assert(isChattable)
        switchToGenerating()
        appendMessage(role: .user, message: prompt)
        appendMessage(role: .bot, message: "")
        threadWorker.push {[weak self] in
            guard let self else { return }
            chatModule.prefill(prompt)
            while !chatModule.stopped() {
                chatModule.decode()
                if let newText = chatModule.getMessage() {
                    DispatchQueue.main.async {
                        self.updateMessage(role: .bot, message: newText)
                    }
                }
                
                if getModelChatState() != .generating {
                    break
                }
            }
            if getModelChatState() == .generating {
                if let runtimeStats = chatModule.runtimeStatsText(useVision) {
                    DispatchQueue.main.async {
                        self.infoText = runtimeStats
                        self.switchToReady()
                    }
                }
            }
        }
    }
    
    func requestAutomation(measurementFilename: String) {
                
        let conversationsRecordManager = ConversationsRecordManager()
        let conversations = readInputFile()
        
        assert(isChattable)
        switchToGenerating()
        
        threadWorker.push {[self] in
            
            // per conversation
            for (c_idx, conversation) in conversations.enumerated() {
                
                var conversationRecord = ConversationRecord(modelName: self.displayName)
                conversationRecord.modelLoadTime = self.modelLoadTime
                
                for (q_idx, question) in conversation.enumerated() {
                    
                    DispatchQueue.main.async {
                        self.appendMessage(role: .user, message: "\(c_idx)_\(q_idx): \(question)")
                    }
                    
                    //print(question)
                    
                    let timeStart = Date()
                    
                    chatModule.prefill(question)
                    
                    while !chatModule.stopped() {
                        chatModule.decode()
                        if getModelChatState() != .generating {
                            break
                        }
                    }
                    
                    let runtimeStatsText = chatModule.runtimeStatsText(useVision)!
                    
                    let jsonResult = parseJSON(from: runtimeStatsText)!
                    let original_session_tokens = -1
                    let input_tokens = Int(jsonResult["prefill"]!["total tokens"]!.components(separatedBy: " ")[0])
                    let output_tokens = Int(jsonResult["decode"]!["total tokens"]!.components(separatedBy: " ")[0])
                    
                    //print(chatModule.getMessage()!)
                    let questionRecord = QuestionRecord.init(time: TimeRecord(start: timeStart, duration: -timeStart.timeIntervalSinceNow),
                                                             input: question,
                                                             output: chatModule.getMessage(),
                                                             original_session_tokens: original_session_tokens,
                                                             input_tokens: input_tokens!,
                                                             output_tokens: output_tokens!,
                                                             runtimeStats: runtimeStatsText)
                    conversationRecord.questionRecords.append(questionRecord)
                    
                    if let newText = chatModule.getMessage() {
                        DispatchQueue.main.async {
                            self.appendMessage(role: .bot, message: "\(c_idx)_\(q_idx): \(newText)")
                        }
                    }
                    
                    Thread.sleep(forTimeInterval: 5.0)
                }
                
                // Save energy events for particular session
                chatModule.saveEnergyEventsToCSV(withFilename: "\(measurementFilename)_conv\(c_idx).csv")
                
                // add metrics
                conversationsRecordManager.addConversationRecord(conversationRecord)
                
                // clear context
                chatModule.resetChat()
                chatModule.resetEnergyEvents()
                
                DispatchQueue.main.async {
                    self.appendMessage(role: .bot, message: "--sleep--")
                }
                Thread.sleep(forTimeInterval: 60.0)
            }
            
            // Add session and save
            conversationsRecordManager.saveToFile(withFileName: measurementFilename)
            
            // Notify BladeRunner that task is complete
            let restAwaitLib = RestAwaitLib(host: "192.168.1.42", port: 5100)
            restAwaitLib.continueExecution { response, error in
                if (response != nil) {
                    print(response!)
                }
                else {
                    print(error!)
                }
            }
            
            // Exit app
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  exit(0)
                 }
            }
        }
    }
    
    func parseJSON(from jsonString: String) -> [String: [String: String]]? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Error: Cannot create Data from JSON string")
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let dictionary = jsonObject as? [String: [String: String]] {
                return dictionary
            } else {
                print("Error: JSON is not in the expected format [String: [String: String]]")
                return nil
            }
            
        } catch {
            print("Error parsing JSON: \(error)")
            return nil
        }
    }

    func requestProcessImage(image: UIImage) {
        assert(getModelChatState() == .pendingImageUpload)
        switchToProcessingImage()
        threadWorker.push {[weak self] in
            guard let self else { return }
            assert(messages.count > 0)
            DispatchQueue.main.async {
                self.updateMessage(role: .bot, message: "[System] Processing image")
            }
            // step 1. resize image
            let new_image = resizeImage(image: image, width: 112, height: 112)
            // step 2. prefill image by chatModule.prefillImage()
            chatModule.prefillImage(new_image, prevPlaceholder: "<Img>", postPlaceholder: "</Img> ")
            DispatchQueue.main.async {
                self.updateMessage(role: .bot, message: "[System] Ready to chat")
                self.switchToReady()
            }
        }
    }

    func isCurrentModel(modelID: String) -> Bool {
        return self.modelID == modelID
    }
}

private extension ChatState {
    func getModelChatState() -> ModelChatState {
        modelChatStateLock.lock()
        defer { modelChatStateLock.unlock() }
        return modelChatState
    }

    func setModelChatState(_ newModelChatState: ModelChatState) {
        modelChatStateLock.lock()
        modelChatState = newModelChatState
        modelChatStateLock.unlock()
    }

    func appendMessage(role: MessageRole, message: String) {
        messages.append(MessageData(role: role, message: message))
    }

    func updateMessage(role: MessageRole, message: String) {
        messages[messages.count - 1] = MessageData(role: role, message: message)
    }

    func clearHistory() {
        messages.removeAll()
        infoText = ""
    }

    func switchToResetting() {
        setModelChatState(.resetting)
    }

    func switchToGenerating() {
        setModelChatState(.generating)
    }

    func switchToReloading() {
        setModelChatState(.reloading)
    }

    func switchToReady() {
        setModelChatState(.ready)
    }

    func switchToTerminating() {
        setModelChatState(.terminating)
    }

    func switchToFailed() {
        setModelChatState(.failed)
    }

    func switchToPendingImageUpload() {
        setModelChatState(.pendingImageUpload)
    }

    func switchToProcessingImage() {
        setModelChatState(.processingImage)
    }

    func interruptChat(prologue: () -> Void, epilogue: @escaping () -> Void) {
        assert(isInterruptible)
        if getModelChatState() == .ready 
            || getModelChatState() == .failed
            || getModelChatState() == .pendingImageUpload {
            prologue()
            epilogue()
        } else if getModelChatState() == .generating {
            prologue()
            threadWorker.push {
                DispatchQueue.main.async {
                    epilogue()
                }
            }
        } else {
            assert(false)
        }
    }

    func mainResetChat() {
        threadWorker.push {[weak self] in
            guard let self else { return }
            chatModule.resetChat()
            if useVision {
                chatModule.resetImageModule()
            }
            DispatchQueue.main.async {
                self.clearHistory()
                if self.useVision {
                    self.appendMessage(role: .bot, message: "[System] Upload an image to chat")
                    self.switchToPendingImageUpload()
                } else {
                    self.switchToReady()
                }
            }
        }
    }

    func mainTerminateChat(callback: @escaping () -> Void) {
        threadWorker.push {[weak self] in
            guard let self else { return }
            if useVision {
                chatModule.unloadImageModule()
            }
            chatModule.unload()
            DispatchQueue.main.async {
                self.clearHistory()
                self.modelID = ""
                self.modelLib = ""
                self.modelPath = ""
                self.displayName = ""
                self.useVision = false
                self.switchToReady()
                callback()
            }
        }
    }

    func mainReloadChat(modelID: String, modelLib: String, modelPath: String, estimatedVRAMReq: Int, displayName: String) {
        clearHistory()
        let prevUseVision = useVision
        self.modelID = modelID
        self.modelLib = modelLib
        self.modelPath = modelPath
        self.displayName = displayName
        self.useVision = displayName.hasPrefix("minigpt")
        threadWorker.push {[weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.appendMessage(role: .bot, message: "[System] Initalize...")
            }
            
            let modelTimeStart = Date()
            
            if prevUseVision {
                chatModule.unloadImageModule()
            }
            chatModule.unload()
            let vRAM = os_proc_available_memory()
            if (vRAM < estimatedVRAMReq) {
                let requiredMemory = String (
                    format: "%.1fMB", Double(estimatedVRAMReq) / Double(1 << 20)
                )
                let errorMessage = (
                    "Sorry, the system cannot provide \(requiredMemory) VRAM as requested to the app, " +
                    "so we cannot initialize this model on this device."
                )
                DispatchQueue.main.sync {
                    self.messages.append(MessageData(role: MessageRole.bot, message: errorMessage))
                    self.switchToFailed()
                }
                return
            }

            if useVision {
                // load vicuna model
                let dir = (modelPath as NSString).deletingLastPathComponent
                let vicunaModelLib = "vicuna-7b-v1.3-q3f16_0"
                let vicunaModelPath = dir + "/" + vicunaModelLib
                let appConfigJSONData = try? JSONSerialization.data(withJSONObject: ["conv_template": "minigpt"], options: [])
                let appConfigJSON = String(data: appConfigJSONData!, encoding: .utf8)
                chatModule.reload(vicunaModelLib, modelPath: vicunaModelPath, appConfigJson: appConfigJSON)
                // load image model
                chatModule.reloadImageModule(modelLib, modelPath: modelPath)
            } else {
                chatModule.reload(modelLib, modelPath: modelPath, appConfigJson: "")
            }
            
            let modelDuration = -modelTimeStart.timeIntervalSinceNow
            self.modelLoadTime = TimeRecord(start: modelTimeStart, duration: modelDuration)
            
            DispatchQueue.main.async {
                if self.useVision {
                    self.updateMessage(role: .bot, message: "[System] Upload an image to chat")
                    self.switchToPendingImageUpload()
                } else {
                    self.updateMessage(role: .bot, message: "[System] Ready to chat")
                    self.switchToReady()
                }
            }
        }
    }
}
