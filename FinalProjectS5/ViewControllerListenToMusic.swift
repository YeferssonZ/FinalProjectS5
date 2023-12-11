//
//  ViewControllerListenToMusic.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 9/12/23.
//

import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseAnalytics

class ViewControllerListenToMusic: UIViewController {

    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!

    var song: Song?
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configura tu interfaz de usuario según la canción seleccionada
        if let song = song {
            songNameLabel.text = song.cancion
            artistLabel.text = song.artista

            // Descargar y configurar la imagen del álbum
            if let imageUrl = song.imageUrl {
                loadImage(from: imageUrl) { image in
                    DispatchQueue.main.async {
                        self.albumImageView.image = image
                    }
                }
            }

            // Configura el reproductor de audio
            if let audioUrl = song.audioUrl {
                configureAudioPlayer(audioUrl: audioUrl)
            }
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        
        Analytics.logEvent("music_view_loaded", parameters: nil)
    }
    
    @objc func updateUI() {
        if let player = audioPlayer {
            // Actualizar el tiempo actual y la posición del control deslizante
            currentTimeLabel.text = formatTime(player.currentTime)
            timeSlider.value = Float(player.currentTime)
        }
    }

    deinit {
        // Detener el temporizador cuando la vista se destruye
        timer?.invalidate()
    }


    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }

    func configureAudioPlayer(audioUrl: String) {
        guard let url = URL(string: audioUrl) else {
            print("Error: URL de audio no válida")
            return
        }

        let storageRef = Storage.storage().reference(forURL: audioUrl)

        storageRef.getData(maxSize: 15 * 1024 * 1024) { data, error in
            guard let data = data, error == nil else {
                print("Error al obtener datos de audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()

                // Configura la duración total del audio
                if let duration = self.audioPlayer?.duration {
                    DispatchQueue.main.async {
                        self.totalTimeLabel.text = self.formatTime(duration)
                        self.timeSlider.maximumValue = Float(duration)
                    }
                }
            } catch {
                print("Error al configurar el reproductor de audio: \(error.localizedDescription)")
            }
        }
    }

    @IBAction func playPauseButtonTapped(_ sender: Any) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
            } else {
                player.play()
                playPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
                
                // Registra un evento cuando el usuario presiona el botón de reproducción/pausa
                Analytics.logEvent("play_pause_button_tapped", parameters: nil)
            }
        }
    }

    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        if let player = audioPlayer {
            player.currentTime = TimeInterval(sender.value)
            currentTimeLabel.text = formatTime(player.currentTime)
        }
    }

    // Función para formatear el tiempo en segundos a formato mm:ss
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Método para detener la reproducción del audio
    func stopAudio() {
        if let player = audioPlayer {
            player.stop()
            player.currentTime = 0
            playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudio()
        
        // Registra un evento cuando el usuario sale de la vista
        Analytics.logEvent("music_view_closed", parameters: nil)
    }

}

extension ViewControllerListenToMusic: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Actualiza la interfaz de usuario cuando la reproducción ha terminado
        playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
    }
}
