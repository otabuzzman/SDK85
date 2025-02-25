import AVFoundation

class Sound {
    private static var audioPlayer: AVAudioPlayer?

    static func play(soundfile: String) {
        guard
            let path = Bundle.main.path(forResource: soundfile, ofType: nil)
        else {
            return
        }
        audioPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        audioPlayer?.play()
    }
}
