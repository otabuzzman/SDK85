import AVFoundation

class Sound {
    // https://www.hackingwithswift.com/example-code/media/how-to-play-sounds-using-avaudioplayer
    private static var player: AVAudioPlayer?
    
    static func play(soundfile: String, volume: Float = 1) {
        guard
            let path = Bundle.main.path(forResource: soundfile, ofType: nil),
            let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        else { return }

        Self.player = player
        
        player.volume = volume
        player.play()
    }
}
