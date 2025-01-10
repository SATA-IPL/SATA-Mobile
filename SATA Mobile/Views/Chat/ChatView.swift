//
//  ChatView.swift
//  SATA Mobile
//
//  Created by João Franco on 01/01/2025.
//

import SwiftUI
import GoogleGenerativeAI

// MARK: - View Modifiers
/// Custom view modifiers for enhanced visual effects
extension View {
    /// Adds a glowing effect to the view
    /// - Parameters:
    ///   - color: The color of the glow effect
    ///   - radius: The radius of the blur effect
    func intelligenceGlow(color: Color = .blue, radius: CGFloat = 15) -> some View {
        self.overlay(
            self
                .blur(radius: radius)
                .opacity(0.3)
                .blendMode(.plusLighter)
        )
    }
    
    /// Adds a shimmering animation effect to the view
    func shimmerEffect() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Triggers haptic feedback
    /// - Parameter style: The style of haptic feedback to generate
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Background Views
/// Animated background view with moving gradients
struct IntelligenceBackground: View {
    @State private var animate = false
    @State private var phase = 0.0
    
    let blueGreenGradient1 = Gradient(colors: [
        Color.blue.opacity(0.2),
        Color.green.opacity(0.1),
        Color.clear
    ])
    
    let blueGreenGradient2 = Gradient(colors: [
        Color.green.opacity(0.2),
        Color.blue.opacity(0.1)
    ])
    
    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: blueGreenGradient1,
                    startPoint: animate ? .topLeading : .bottomLeading,
                    endPoint: animate ? .bottomTrailing : .topTrailing
                )
                
                // Animated orbs
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: blueGreenGradient2,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: animate ? 50 : -50, y: animate ? -30 : 30)
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: blueGreenGradient2,
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: animate ? -50 : 50, y: animate ? 50 : -50)
                    .blur(radius: 60)
            }
            .opacity(0.7)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true)
                ) {
                    animate.toggle()
                }
            }
        }
    }
}

// MARK: - Custom Modifiers
/// Adds a shimmer effect to any view
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .white.opacity(0.2), location: 0.5),
                            .init(color: .white.opacity(0.1), location: 0.7),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width)
                    .offset(x: geometry.size.width * phase)
                    .blendMode(.plusLighter)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Main Chat View
/// Main view for the chat interface with the AI assistant
struct ChatView: View {
    // MARK: Properties
    // View Model and Game Data
    let game: Game
    let model: GenerativeModel
    @StateObject private var viewModel = GameDetailViewModel()
    
    // UI State
    @Binding var isPresented: Bool
    @State private var messageText = ""
    @State private var messages: [(text: String, isUser: Bool)] = []
    @State private var isLoading = false
    @State private var isKeyboardVisible = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingClearConfirmation = false
    @State private var shouldScroll = true
    @State private var contentHeight: CGFloat = 0
    @State private var chatHistory: [String] = []
    
    // Layout Constants
    private let inputOverlayHeight: CGFloat = 110
    private let scrollPadding: CGFloat = 20
    
    // MARK: Initialization
    /// Initialize the chat view with game data and AI model
    init(game: Game, model: GenerativeModel, isPresented: Binding<Bool>) {
        self.game = game
        self.model = model
        self._isPresented = isPresented
        self._messages = State(initialValue: [
            ("Hi! I'm your game assistant. Feel free to ask me anything about the match between \(game.homeTeam.name) and \(game.awayTeam.name)!", false)
        ])

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0)
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    // MARK: Body
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ZStack {
                    IntelligenceBackground()
                        .ignoresSafeArea()
                    
                    ZStack(alignment: .bottom) {
                        // Messages Area (now at bottom of ZStack)
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(messages.indices, id: \.self) { index in
                                        MessageBubble(text: messages[index].text, isUser: messages[index].isUser)
                                            .transition(.asymmetric(
                                                insertion: .scale.combined(with: .slide),
                                                removal: .opacity
                                            ))
                                            .id(index)
                                    }
                                    if isLoading {
                                        TypingIndicator()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id("loading")
                                    }
                                }
                                .padding()
                                .padding(.bottom, inputOverlayHeight) // Add space for suggestions and input
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: ViewHeightKey.self,
                                            value: geo.frame(in: .local).height
                                        )
                                    }
                                )
                            }
                            .onPreferenceChange(ViewHeightKey.self) { height in
                                contentHeight = height
                            }
                            .onChange(of: isLoading) { _ in
                                if isLoading || contentHeight > UIScreen.main.bounds.height {
                                    scrollToMessage(proxy: proxy)
                                }
                            }
                            .onAppear {
                                scrollProxy = proxy
                            }
                            .simultaneousGesture(
                                DragGesture().onChanged { _ in
                                    shouldScroll = false
                                }
                            )
                        }
                        
                        // Fixed overlay at bottom
                        VStack(spacing: 0) {
                            // Suggestion buttons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    SuggestionButton(text: "Show me game stats") {
                                        messageText = "What are the current game statistics?"
                                        sendMessage() // Auto-send when suggestion is tapped
                                    }
                                    SuggestionButton(text: "Who scored?") {
                                        messageText = "Who scored in this game?"
                                        sendMessage()
                                    }
                                    SuggestionButton(text: "Game highlights") {
                                        messageText = "What were the key moments of the game?"
                                        sendMessage()
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 8)
                            
                            // Input Area
                            HStack(spacing: 12) {
                                TextField("Ask me a Question...", text: $messageText)
                                    .padding(12)
                                    .background(.thinMaterial)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                Material.ultraThin,
                                                lineWidth: 0.5
                                            )
                                    )
                                    .intelligenceGlow(color: .blue.opacity(0.5), radius: 5)
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    .onSubmit {
                                        if (!messageText.isEmpty) {
                                            sendMessage()
                                        }
                                    }
                                
                                Button(action: sendMessage) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(
                                            messageText.isEmpty ?
                                            Color(uiColor: UIColor.systemGray3) :
                                            Color.accentColor
                                        )
                                        .scaleEffect(messageText.isEmpty ? 0.9 : 1.0)
                                        .animation(
                                            .spring(response: 0.3, dampingFraction: 0.7),
                                            value: messageText.isEmpty
                                        )
                                }
                                .disabled(messageText.isEmpty)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .background(
                            VariableBlurView(direction: .blurredBottomClearTop)
                                .ignoresSafeArea()
                        )
                    }
                    
                    VStack {
                        VariableBlurView(maxBlurRadius: 20, direction: .blurredTopClearBottom)
                            .frame(height: proxy.safeAreaInsets.top + 44) // Include toolbar height
                            .ignoresSafeArea()
                        Spacer()
                    }
                    
                    .navigationTitle("Coach Assistant")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { 
                                withAnimation(.spring()) {
                                    isPresented = false 
                                }
                            }) {
                                Image(systemName: "xmark")
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { showingClearConfirmation = true }) {
                                Image(systemName: "trash")
                                    .disabled(messages.count <= 1)
                                    .foregroundStyle(messages.count <= 1 ? .gray : .red)
                            }
                            .disabled(messages.count <= 1)
                        }
                    }
                    .confirmationDialog(
                        "Clear Chat History",
                        isPresented: $showingClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Clear", role: .destructive) {
                            withAnimation {
                                messages = [messages[0]] // Keep only the welcome message
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to clear the chat history?")
                    }
                    .onAppear {
                        NotificationCenter.default.addObserver(
                            forName: UIResponder.keyboardWillShowNotification,
                            object: nil,
                            queue: .main
                        ) { _ in
                            withAnimation { isKeyboardVisible = true }
                        }
                        
                        NotificationCenter.default.addObserver(
                            forName: UIResponder.keyboardWillHideNotification,
                            object: nil,
                            queue: .main
                        ) { _ in
                            withAnimation { isKeyboardVisible = false }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Private Methods
    /// Scrolls to the latest message or loading indicator
    private func scrollToMessage(proxy: ScrollViewProxy) {
        let id = isLoading ? "loading" : String(messages.count - 1)
        
        // Smooth scroll with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
        
        shouldScroll = true
    }
    
    /// Sends a message to the AI and processes the response
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        hapticFeedback(.medium)
        let userMessage = messageText
        messageText = ""
        
        withAnimation {
            messages.append((userMessage, true))
            chatHistory.append("User: \(userMessage)")
            isLoading = true
        }
        
        Task {
            do {
                // Create context with chat history
                let historyContext = chatHistory.joined(separator: "\n")
                let prompt = """
                    \(await viewModel.generateContext(game: game))
                    
                    Previous conversation:
                    \(historyContext)
                    
                    User Question: \(userMessage)
                    
                    Please provide a natural, conversational response based on the game information and conversation history above.
                    """
                
                print("Prompt: \(prompt)")
                
                let result = try await model.generateContent(prompt)
                withAnimation {
                    isLoading = false
                    if let response = result.text {
                        messages.append((response, false))
                        chatHistory.append("Assistant: \(response)")
                        if let proxy = scrollProxy {
                            scrollToMessage(proxy: proxy)
                        }
                    }
                }
            } catch {
                withAnimation {
                    messages.append((error.localizedDescription, false))
                    if let proxy = scrollProxy {
                        scrollToMessage(proxy: proxy)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
/// Button for quick chat suggestions
struct SuggestionButton: View {
    let text: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
                action()
            }
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }) {
            Text(text)
                .font(.footnote)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Material.ultraThin)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Material.ultraThin,
                            lineWidth: 0.5
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(.plain)
    }
}

/// Animated typing indicator for AI responses
struct TypingIndicator: View {
    @State private var phase = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == Double(index) ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.4), value: phase)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1.0).truncatingRemainder(dividingBy: 3)
            }
        }
    }
}

/// Custom chat bubble view for messages
struct MessageBubble: View {
    let text: String
    let isUser: Bool
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    isUser ?
                    AnyView(
                        LinearGradient(
                            colors: [
                                Color.accent.opacity(0.3),
                                Color.accent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .background(.ultraThinMaterial)
                    ) :
                    AnyView(
                        Rectangle()
                            .fill(.thinMaterial)
                    )
                )
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .intelligenceGlow(
                    color: isUser ? .accent : .gray,
                    radius: isUser ? 15 : 10
                )
                .shadow(
                    color: isUser ? .accent.opacity(0.2) : .black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isUser ?
                            Color.white.opacity(0.2) :
                            Color.gray.opacity(0.1),
                            lineWidth: 0.5
                        )
                )
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : (isUser ? 50 : -50))
                .offset(y: isAnimating ? 0 : 10)
            if !isUser { Spacer() }
        }
        .onAppear {
            withAnimation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.8,
                    blendDuration: 0.2
                )
                .delay(isUser ? 0 : 0.3)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preference Keys
/// Tracks the height of the scroll view content
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
