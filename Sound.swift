import AVFoundation

class Sound {
    static func play(soundfile: String, volume: Float = 1) {
        guard
            let path = Bundle.main.path(forResource: soundfile, ofType: nil),
            let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        else { return }

        player.volume = volume
        player.play()
    }
}
