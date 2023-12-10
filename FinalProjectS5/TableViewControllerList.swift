//
//  TableViewControllerList.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 8/12/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class TableViewControllerList: UITableViewController {

    var songs: [Song] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        loadUserSongs()
    }

    @IBAction func CerrarSesionTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    func loadUserSongs() {
        guard let currentUser = Auth.auth().currentUser else {
            // Manejar el caso en el que el usuario no esté autenticado
            return
        }

        let userId = currentUser.uid
        let databaseRef = Database.database().reference().child("usuarios").child(userId).child("mensajes")

        databaseRef.observe(.value) { snapshot in
            self.songs.removeAll()

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let songData = childSnapshot.value as? [String: Any] {
                    let song = Song(
                        remitente: songData["remitente"] as? String,
                        cancion: songData["Cancion"] as? String,
                        artista: songData["Artista"] as? String,
                        imageUrl: songData["imageUrl"] as? String,
                        audioUrl: songData["audioUrl"] as? String
                    )

                    self.songs.append(song)
                }

                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(songs.count, 1) // Devuelve al menos 1 para mostrar el mensaje
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if songs.isEmpty {
            // Si no hay canciones, muestra un mensaje
            let cell = tableView.dequeueReusableCell(withIdentifier: "noSongsCell", for: indexPath)
            cell.textLabel?.text = "No dispones de canciones"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath)
            let song = songs[indexPath.row]
            cell.textLabel?.text = song.cancion
            cell.detailTextLabel?.text = song.artista

            if let imageUrl = song.imageUrl {
                // Descargar la imagen y mostrarla en la celda
                downloadImage(from: imageUrl) { image in
                    DispatchQueue.main.async {
                        cell.imageView?.image = image
                        cell.setNeedsLayout()
                    }
                }
            }

            return cell
        }
    }
    
    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let image = UIImage(data: data)
            completion(image)
        }

        task.resume()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !songs.isEmpty {
            let selectedSong = songs[indexPath.row]
            performSegue(withIdentifier: "listenSegue", sender: selectedSong)
        }
    }

    // Función para eliminar una canción
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if !songs.isEmpty {
                let songToDelete = songs[indexPath.row]
                deleteSong(song: songToDelete, at: indexPath)
            }
        }
    }

    // Función para confirmar la eliminación y ejecutarla
    func deleteSong(song: Song, at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Eliminar Canción", message: "¿Estás seguro de eliminar esta canción?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Eliminar", style: .destructive) { _ in
            self.performDeletion(for: song, at: indexPath)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)

        present(alertController, animated: true, completion: nil)
    }

    // Función para realizar la eliminación de la canción
    func performDeletion(for song: Song, at indexPath: IndexPath) {
        // Eliminar la canción del Storage
        deleteFromStorage(imageUrl: song.imageUrl, audioUrl: song.audioUrl)

        // Eliminar la canción del Database
        deleteFromDatabase(song: song)

        // Eliminar la canción de la lista local
        songs.remove(at: indexPath.row)

        // Actualizar la tabla
        tableView.reloadData()
        // Si necesitas animación al eliminar, usa el siguiente código en lugar de `tableView.reloadData()`:
        // tableView.deleteRows(at: [indexPath], with: .automatic)
    }


    // Función para eliminar del Storage
    func deleteFromStorage(imageUrl: String?, audioUrl: String?) {
        if let imageUrl = imageUrl {
            let imageRef = Storage.storage().reference(forURL: imageUrl)
            imageRef.delete { error in
                if let error = error {
                    print("Error al eliminar la imagen del Storage: \(error.localizedDescription)")
                }
            }
        }

        if let audioUrl = audioUrl {
            let audioRef = Storage.storage().reference(forURL: audioUrl)
            audioRef.delete { error in
                if let error = error {
                    print("Error al eliminar el audio del Storage: \(error.localizedDescription)")
                }
            }
        }
    }

    // Función para eliminar del Database
    func deleteFromDatabase(song: Song) {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }

        let userId = currentUser.uid
        let databaseRef = Database.database().reference().child("usuarios").child(userId).child("mensajes")

        databaseRef.observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let songData = childSnapshot.value as? [String: Any] {
                    if let audioUrl = songData["audioUrl"] as? String,
                       audioUrl == song.audioUrl {
                        // Encontramos la canción en el Database, eliminémosla
                        let songId = childSnapshot.key
                        let songRef = databaseRef.child(songId)
                        songRef.removeValue { _, _ in
                            print("Canción eliminada del Database")
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "listenSegue",
            let viewControllerListen = segue.destination as? ViewControllerListenToMusic,
            let selectedSong = sender as? Song {
            viewControllerListen.song = selectedSong
        }
    }
}
