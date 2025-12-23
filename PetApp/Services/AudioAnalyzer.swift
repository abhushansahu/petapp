import AVFoundation
import Accelerate
import Combine

class AudioAnalyzer: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isAnalyzing: Bool = false
    
    @Published var isMusicDetected: Bool = false
    @Published var beatIntensity: Double = 0.0
    @Published var hasPermission: Bool = false
    
    var onBeatDetected: ((Double) -> Void)?
    var onMusicDetected: ((Bool) -> Void)?
    
    // Audio processing parameters - optimized for performance
    private let sampleRate: Double = 44100.0
    private let bufferSize: UInt32 = 2048 // Reduced for lower latency
    private let fftSize: Int = 1024 // Reduced for performance
    
    // Beat detection parameters
    private var energyHistory: [Double] = []
    private let energyHistorySize = 22 // Reduced for performance (~0.5 second)
    private var lastBeatTime: Date = Date()
    private let minBeatInterval: TimeInterval = 0.2
    
    // Performance: Skip some processing cycles
    private var processingSkipCounter: Int = 0
    private let processingSkipInterval: Int = 2 // Process every 2nd buffer
    
    init() {
        checkPermissions()
    }
    
    // MARK: - Permissions
    private func checkPermissions() {
        // Check screen recording permission (required for system audio on macOS)
        // Note: This is a simplified check - actual permission request happens at runtime
        hasPermission = true // Will be updated when we try to start
    }
    
    // MARK: - Audio Analysis
    func startAnalysis() {
        guard !isAnalyzing else { return }
        
        // On macOS, we can try to start directly
        // Permission will be requested by the system if needed
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        do {
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let inputFormat = inputNode.inputFormat(forBus: 0)
            
            // Install tap on input node
            let bufferSize: AVAudioFrameCount = 4096
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer)
            }
            
            try engine.start()
            
            self.audioEngine = engine
            self.inputNode = inputNode
            self.isAnalyzing = true
            self.hasPermission = true
            
        } catch {
            print("Failed to setup audio engine: \(error)")
            hasPermission = false
            isAnalyzing = false
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        // Performance: Skip some buffers to reduce CPU usage
        processingSkipCounter += 1
        if processingSkipCounter % processingSkipInterval != 0 {
            return
        }
        
        let frameLength = Int(buffer.frameLength)
        
        // Convert to mono and calculate RMS energy (optimized)
        var floatEnergy: Float = 0.0
        vDSP_measqv(channelData[0], 1, &floatEnergy, vDSP_Length(frameLength))
        let energy = Double(sqrt(floatEnergy / Float(frameLength)))
        
        // Update energy history
        energyHistory.append(energy)
        if energyHistory.count > energyHistorySize {
            energyHistory.removeFirst()
        }
        
        // Calculate frequency content for music detection
        let musicDetected = detectMusic(in: buffer)
        DispatchQueue.main.async {
            if self.isMusicDetected != musicDetected {
                self.isMusicDetected = musicDetected
                self.onMusicDetected?(musicDetected)
            }
        }
        
        // Beat detection
        if energyHistory.count >= energyHistorySize {
            let beatDetected = detectBeat(energy: energy)
            if beatDetected {
                let now = Date()
                if now.timeIntervalSince(lastBeatTime) >= minBeatInterval {
                    lastBeatTime = now
                    
                    let intensity = min(1.0, energy * 10.0) // Normalize intensity
                    DispatchQueue.main.async {
                        self.beatIntensity = intensity
                        self.onBeatDetected?(intensity)
                    }
                }
            }
        }
    }
    
    private func detectMusic(in buffer: AVAudioPCMBuffer) -> Bool {
        guard let channelData = buffer.floatChannelData else { return false }
        let frameLength = Int(buffer.frameLength)
        
        // Simple frequency analysis - check for significant energy in music frequency ranges
        // Music typically has energy in 80Hz - 15kHz range
        
        // Calculate FFT (simplified - using vDSP for performance)
        let log2n = UInt(round(log2(Double(frameLength))))
        let fftSize = 1 << log2n
        
        var realp = [Float](repeating: 0, count: Int(fftSize / 2))
        var imagp = [Float](repeating: 0, count: Int(fftSize / 2))
        
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return false
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        // Convert interleaved complex to split complex
        return realp.withUnsafeMutableBufferPointer { realBuffer in
            imagp.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!, imagp: imagBuffer.baseAddress!)
                channelData[0].withMemoryRebound(to: DSPComplex.self, capacity: frameLength) { complexBuffer in
                    vDSP_ctoz(complexBuffer, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                }
                
                // Perform FFT
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                
                // Analyze frequency bands
                let sampleRate = buffer.format.sampleRate
                let nyquist = sampleRate / 2.0
                let frequencyResolution = nyquist / Double(fftSize / 2)
                
                // Check energy in music frequency ranges (80Hz - 15kHz)
                var musicEnergy: Float = 0.0
                let lowFreqIndex = Int(80.0 / frequencyResolution)
                let highFreqIndex = min(Int(15000.0 / frequencyResolution), Int(fftSize / 2) - 1)
                
                // Calculate magnitude and sum energy in music range
                for i in lowFreqIndex...highFreqIndex {
                    let real = realBuffer[i]
                    let imag = imagBuffer[i]
                    let magnitude = sqrt(real * real + imag * imag)
                    musicEnergy += magnitude
                }
                
                // Music detected if significant energy in music frequency range
                let threshold: Float = 0.1
                return musicEnergy > threshold
            }
        }
    }
    
    private func detectBeat(energy: Double) -> Bool {
        guard energyHistory.count >= energyHistorySize else { return false }
        
        // Calculate average energy
        let avgEnergy = energyHistory.reduce(0, +) / Double(energyHistory.count)
        
        // Calculate variance
        let variance = energyHistory.map { pow($0 - avgEnergy, 2) }.reduce(0, +) / Double(energyHistory.count)
        let stdDev = sqrt(variance)
        
        // Beat detected if current energy is significantly above average
        let threshold = avgEnergy + (stdDev * 1.5)
        return energy > threshold && energy > 0.01
    }
    
    func stopAnalysis() {
        guard isAnalyzing else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isAnalyzing = false
        
        // Reset state
        energyHistory.removeAll()
        beatIntensity = 0.0
    }
    
    deinit {
        stopAnalysis()
    }
}
