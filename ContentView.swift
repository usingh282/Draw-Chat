import SwiftUI
import AVKit
import AVFoundation

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var username = ""
    @State private var showDrawingBoard = false
    @State private var recordingAudio = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var lineColor: Color = .blue
    @State private var lineWidth: CGFloat = 5.0
    @State private var currentLines: [CGPoint] = []
    @State private var allLines: [[CGPoint]] = []
    
    var body: some View {
        if !isSignedIn {
            // Sign-in Screen
            VStack {
                Text("Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                TextField("Enter Username or Email", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                
                Button(action: {
                    if !username.isEmpty {
                        isSignedIn.toggle()
                    }
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(username.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(username.isEmpty)
            }
            .padding()
        } else {
            // Main Tile View
            ScrollView {
                VStack(spacing: 20) {
                    // Tile for "Learn" (Audio Feature)
                    TileView(title: "Talk", iconName: "mic.circle.fill", color: .blue) {
                        recordingAudio.toggle()
                        if recordingAudio {
                            startRecording()
                        } else {
                            stopRecording()
                        }
                    }
                    
                    // Tile for "Draw"
                    TileView(title: "Draw", iconName: "pencil.circle.fill", color: .orange) {
                        showDrawingBoard.toggle()
                    }
                    .sheet(isPresented: $showDrawingBoard) {
                        DrawingBoard(lineColor: $lineColor, lineWidth: $lineWidth, currentLines: $currentLines, allLines: $allLines)
                    }
                    
                    // Tile for "Settings"
                    TileView(title: "Settings", iconName: "gear.circle.fill", color: .green) {
                        // Future settings can go here
                    }
                    
                    // Logout Button
                    Button(action: {
                        isSignedIn = false
                    }) {
                        Text("Logout")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
    }
    
    // Functions to start and stop audio recording
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let url = getRecordingURL()
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Failed to record audio: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
    }
    
    func getRecordingURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("recording.m4a")
    }
}

// Tile View to create consistent UI tiles
struct TileView: View {
    let title: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .padding(.horizontal)
    }
}

// Drawing Board with Color Picker
struct DrawingBoard: View {
    @Binding var lineColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var currentLines: [CGPoint]
    @Binding var allLines: [[CGPoint]]
    
    @State private var selectedColor: Color = .blue
    
    var body: some View {
        VStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                // Drawing Area
                ForEach(allLines, id: \.self) { line in
                    Path { path in
                        for (i, point) in line.enumerated() {
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(lineColor, lineWidth: lineWidth)
                }
                
                Path { path in
                    for (i, point) in currentLines.enumerated() {
                        if i == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(lineColor, lineWidth: lineWidth)
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentLines.append(value.location)
                    }
                    .onEnded { _ in
                        allLines.append(currentLines)
                        currentLines.removeAll()
                    }
                )
            }
            .overlay(
                VStack {
                    HStack {
                        // Button to select colors
                        ColorPicker("Line Color", selection: $lineColor)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        
                        // Erase All Button
                        Button(action: {
                            allLines.removeAll()
                        }) {
                            Text("Erase All")
                                .font(.headline)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        // Clear Current Line Button
                        Button(action: {
                            currentLines.removeAll()
                        }) {
                            Text("Clear Line")
                                .font(.headline)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }, alignment: .top
                
            )
        }
    }
}

// Preview for SwiftUI Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
