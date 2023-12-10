//
//  ViewControllerSendUser.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 8/12/23.
//

import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class ViewControllerSendUser: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var imageURL: URL?
    var audioURL: URL?
    var songText: String?
    var artistText: String?
    var senderEmail: String?
    var availableUsers: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadAvailableUsers()
        loadSenderInfo()
    }

    func loadAvailableUsers() {
        let databaseRef = Database.database().reference().child("usuarios")

        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists(), let userSnapshots = snapshot.children.allObjects as? [DataSnapshot] else {
                print("No hay usuarios disponibles")
                return
            }

            self.availableUsers = userSnapshots.compactMap { snapshot in
                guard let userData = snapshot.value as? [String: Any] else {
                    return nil
                }

                let uid = snapshot.key
                let email = userData["email"] as? String

                return User(uid: uid, email: email!)
            }

            print("Usuarios disponibles: \(self.availableUsers.count)")
            self.tableView.reloadData()
        }
    }
    
    func loadSenderInfo() {
        if let currentUser = Auth.auth().currentUser {
            senderEmail = currentUser.email
        }
    }


    // MARK: - UITableView DataSource & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)

        let user = availableUsers[indexPath.row]
        cell.textLabel?.text = user.email

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = availableUsers[indexPath.row]

        // Presentar un controlador de alerta para confirmar la elección
        let alertController = UIAlertController(title: "Confirmar Envío", message: "¿Estás seguro de enviar los archivos a \(selectedUser.email)?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: "Enviar", style: .default) { _ in
            // Descargar la imagen y el audio del almacenamiento
            self.downloadImage(user: selectedUser) { image in
                self.downloadAudio(user: selectedUser) { audioPlayer in
                    // Subir el mensaje y el remitente al Database del usuario seleccionado
                    self.uploadMessageToUser(user: selectedUser)

                    // Realizar transición de nuevo a ViewControllerAddSongs
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)

        present(alertController, animated: true, completion: nil)
    }


    // MARK: - Descarga de Imagen y Audio

    func downloadImage(user: User, completion: @escaping (UIImage?) -> Void) {
        guard imageURL != nil else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("imagenes").child(user.uid + ".jpg")

        storageRef.downloadURL { (url, error) in
            if let url = url {
                URLSession.shared.dataTask(with: url) { (data, _, error) in
                    if let data = data, let image = UIImage(data: data) {
                        completion(image)
                    } else {
                        completion(nil)
                    }
                }.resume()
            } else {
                completion(nil)
            }
        }
    }

    func downloadAudio(user: User, completion: @escaping (AVAudioPlayer?) -> Void) {
        guard audioURL != nil else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("audio").child(user.uid + ".mp3")

        storageRef.downloadURL { (url, error) in
            if let url = url {
                URLSession.shared.dataTask(with: url) { (data, _, error) in
                    if let data = data {
                        do {
                            let audioPlayer = try AVAudioPlayer(data: data)
                            completion(audioPlayer)
                        } catch {
                            completion(nil)
                        }
                    } else {
                        completion(nil)
                    }
                }.resume()
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Subida de Mensaje al Database

    func uploadMessageToUser(user: User) {
        guard let songText = songText, let artistaText = artistText, let senderEmail = senderEmail else {
            return
        }

        let databaseRef = Database.database().reference().child("usuarios").child(user.uid)

        // Subir el mensaje, el remitente y la información adicional al Database
        let messageData: [String: Any] = [
            "remitente": senderEmail,
            "Cancion": songText,
            "Artista": artistaText,
            "imageUrl": self.imageURL?.absoluteString ?? "",
            "audioUrl": self.audioURL?.absoluteString ?? ""
        ]

        databaseRef.child("mensajes").childByAutoId().setValue(messageData) { (error, _) in
            if let error = error {
                print("Error al mandar la cancion al usuario: \(error.localizedDescription)")
            } else {
                print("Cancion enviada al usuario seleccionado exitosamente")
            }
        }
    }
}
