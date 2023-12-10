//
//  ViewControllerAddSongs.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 8/12/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import FirebaseStorage
import FirebaseDatabase

class ViewControllerAddSongs: UIViewController, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var songNameTextField: UITextField!
    @IBOutlet weak var artistNameTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    var audioPlayer: AVAudioPlayer?
    var selectedAudioURL: URL?
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configuración adicional si es necesaria
    }

    // MARK: - Document Picker
    @IBAction func uploadAudioTapped(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeAudio)], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let audioURL = urls.first {
            selectedAudioURL = audioURL
            fileNameLabel.text = audioURL.lastPathComponent

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error al cargar el archivo de audio: \(error.localizedDescription)")
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // El usuario canceló la selección de documentos
    }

    // MARK: - Audio Playback
    @IBAction func playPauseTapped(_ sender: Any) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
                playPauseButton.setTitle(" REPRODUCIR", for: .normal)
            } else {
                player.play()
                playPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
                playPauseButton.setTitle(" PAUSAR", for: .normal)
            }
        }
    }

    // MARK: - Image Picker
    @IBAction func uploadImageTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.selectedImage = selectedImage
            imageView.image = selectedImage
        }

        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Send Action
    @IBAction func sendButtonTapped(_ sender: Any) {
        // Mostrar una alerta con un controlador de progreso
        let progressAlert = UIAlertController(title: "Enviando", message: "Cargando...", preferredStyle: .alert)
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
        progressAlert.view.addSubview(progressView)
        
        // Presentar la alerta
        present(progressAlert, animated: true, completion: nil)

        uploadImage { imageUrl in
            self.uploadAudio { audioUrl in
                // Asegúrate de que imageUrl y audioUrl no sean nil
                guard let imageUrl = imageUrl, let audioUrl = audioUrl else {
                    // Manejar el caso donde uno o ambos son nulos
                    print("Error: imageUrl o audioUrl es nulo.")
                    // Puedes mostrar un mensaje al usuario o realizar otra acción apropiada
                    return
                }

                // Cerrar la alerta después de completar la carga
                progressAlert.dismiss(animated: true) {
                    // Luego de la subida de audio, realizar la transición a ViewControllerSendUser
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "sendUserSegue", sender: ["imageUrl": imageUrl, "audioUrl": audioUrl])
                    }
                }
            }
        }
    }


    func uploadImage(completion: @escaping (URL?) -> Void) {
        guard let selectedImage = selectedImage else {
            completion(nil)
            return
        }

        guard let imageData = selectedImage.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("imagenes").child(UUID().uuidString + ".jpg")

        storageRef.putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                print("Error al subir la imagen: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Imagen subida exitosamente")
                storageRef.downloadURL { (url, error) in
                    completion(url)
                }
            }
        }
    }

    func uploadAudio(completion: @escaping (URL?) -> Void) {
        guard let selectedAudioURL = selectedAudioURL else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("audio").child(UUID().uuidString + ".mp3")

        storageRef.putFile(from: selectedAudioURL, metadata: nil) { (_, error) in
            if let error = error {
                print("Error al subir el archivo de audio: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Archivo de audio subido exitosamente")
                storageRef.downloadURL { (url, error) in
                    completion(url)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendUserSegue",
            let viewControllerSendUser = segue.destination as? ViewControllerSendUser,
            let data = sender as? [String: Any] {
            viewControllerSendUser.imageURL = data["imageUrl"] as? URL
            viewControllerSendUser.audioURL = data["audioUrl"] as? URL
            viewControllerSendUser.songText = songNameTextField.text
            viewControllerSendUser.artistText = artistNameTextField.text
            viewControllerSendUser.senderEmail = ""
        }
    }

}
