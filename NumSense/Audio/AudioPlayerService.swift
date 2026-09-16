import AVFoundation
import Foundation

final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var onFinish: (() -> Void)?
    private var playToken = UUID()
    private var lastSpoken: String?
    private var lastFileName: String?
    private var playInSilentMode = true
    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: SpeechFinishHook?

    var isPlaying = false
    var duration: TimeInterval { max(player?.duration ?? 0, 0) }

    func configureSession(playInSilentMode: Bool = true) {
        self.playInSilentMode = playInSilentMode
        activateSession()
    }

    func playBundled(fileName: String, spokenFallback: String, onFinish: @escaping () -> Void) {
        lastSpoken = spokenFallback
        lastFileName = fileName
        startPlayback(fileName: fileName, spokenFallback: spokenFallback, onFinish: onFinish)
    }

    func replay(onFinish: @escaping () -> Void = {}) {
        startPlayback(fileName: lastFileName, spokenFallback: lastSpoken ?? "", onFinish: onFinish)
    }

    func stop() {
        playToken = UUID()
        finishSpeechEngine()
        player?.delegate = nil
        player?.stop()
        player = nil
        isPlaying = false
        onFinish = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        complete()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        if let text = lastSpoken, !text.isEmpty {
            speak(text, onFinish: onFinish ?? {})
        } else {
            complete()
        }
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        let category: AVAudioSession.Category = playInSilentMode ? .playback : .ambient
        do {
            try session.setCategory(category, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
        }
    }

    private func startPlayback(fileName: String?, spokenFallback: String, onFinish: @escaping () -> Void) {
        let token = UUID()
        playToken = token
        self.onFinish = onFinish
        finishSpeechEngine()
        player?.delegate = nil
        player?.stop()
        player = nil
        activateSession()

        guard let fileName else {
            speak(spokenFallback, onFinish: onFinish)
            return
        }

        if let url = bundledAudioURL(fileName: fileName) {
            do {
                let loaded = try AVAudioPlayer(contentsOf: url)
                loaded.delegate = self
                loaded.volume = 1
                loaded.prepareToPlay()
                player = loaded
                if loaded.play() {
                    isPlaying = true
                    return
                }
            } catch {
                // Fall through to speech.
            }
        }

        player?.delegate = nil
        player?.stop()
        player = nil
        guard token == playToken else { return }
        speak(spokenFallback, onFinish: onFinish)
    }

    private func bundledAudioURL(fileName: String) -> URL? {
        let stem = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension.isEmpty ? "m4a" : (fileName as NSString).pathExtension
        let direct = [
            Bundle.main.url(forResource: stem, withExtension: ext),
            Bundle.main.url(forResource: stem, withExtension: ext, subdirectory: "Audio"),
            Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Audio"),
        ]
        if let url = direct.compactMap({ $0 }).first {
            return url
        }
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return nil
        }
        for case let url as URL in enumerator where url.pathExtension == ext {
            if url.deletingPathExtension().lastPathComponent == stem {
                return url
            }
        }
        return nil
    }

    private func complete() {
        let token = playToken
        let done = onFinish
        onFinish = nil
        isPlaying = false
        DispatchQueue.main.async { [weak self] in
            guard self?.playToken == token else { return }
            done?()
        }
    }

    private func finishSpeechEngine() {
        speechDelegate = nil
        synthesizer.delegate = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speak(_ text: String, onFinish: @escaping () -> Void) {
        guard !text.isEmpty else {
            complete()
            return
        }
        self.onFinish = onFinish
        activateSession()
        let hook = SpeechFinishHook { [weak self] in
            self?.isPlaying = false
            self?.complete()
        }
        speechDelegate = hook
        synthesizer.delegate = hook
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha")
        utterance.rate = 0.47
        utterance.volume = 1
        isPlaying = true
        synthesizer.speak(utterance)
    }
}

private final class SpeechFinishHook: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }
}
