//  ViewControllerProfile.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 11/12/23.

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ViewControllerProfile: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var editNameButton: UIButton!
    @IBOutlet weak var guardarCambiosButton: UIButton!

    var currentUser: UserProfile?
    var editedName: String?
    var editedImage: UIImage?

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserProfile()
        configureTapGesture()
        configureButtons()
    }

    // MARK: - UI Configuration

    func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
    }

    func configureButtons() {
        guardarCambiosButton.isEnabled = false
    }

    // MARK: - Actions

    @objc func imageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func editNameButtonTapped(_ sender: Any) {
        showEditNameAlert()
    }

    func showEditNameAlert() {
        let alertController = UIAlertController(title: "Editar Nombre", message: nil, preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Nuevo Nombre"
        }

        let saveAction = UIAlertAction(title: "Cambiar Nombre", style: .default) { [weak self] _ in
            guard let newName = alertController.textFields?.first?.text else { return }
            self?.editedName = newName
            self?.displayNameLabel.text = newName
            self?.guardarCambiosButton.isEnabled = true
        }

        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    @IBAction func guardarCambiosTapped(_ sender: Any) {
        if let newName = editedName, let newImage = editedImage {
            updateUserProfile(displayName: newName, photoImage: newImage)
            guardarCambiosButton.isEnabled = false
            showAlert("Cambios Guardados", message: "Los cambios han sido guardados exitosamente.")
        } else {
            showAlert("Sin Cambios", message: "No hay cambios para guardar.")
        }
    }

    // MARK: - Image Picker

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            profileImageView.image = pickedImage
            editedImage = pickedImage
            guardarCambiosButton.isEnabled = true
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // MARK: - Firebase Operations

    func updateUserProfile(displayName: String? = nil, photoImage: UIImage? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        let databaseRef = Database.database().reference().child("usuarios").child(uid)

        var userData: [String: Any] = [:]

        if let displayName = displayName {
            userData["displayName"] = displayName
        }

        if let email = currentUser?.email {
            userData["email"] = email
        }

        uploadImageToStorage(image: photoImage, uid: uid) { imageURL in
            userData["photoURL"] = imageURL
            databaseRef.updateChildValues(userData) { (error, ref) in
                if let error = error {
                    print("Error al actualizar el perfil del usuario: \(error.localizedDescription)")
                } else {
                    print("Perfil del usuario actualizado correctamente")
                }
            }
        }
    }

    func uploadImageToStorage(image: UIImage?, uid: String, completion: @escaping (String?) -> Void) {
        guard let image = image else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")

        if let imageData = image.jpegData(compressionQuality: 0.5) {
            storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error al subir la imagen al almacenamiento: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    storageRef.downloadURL { (url, error) in
                        if let url = url {
                            print("URL de la imagen en el Storage: \(url.absoluteString)")
                            completion(url.absoluteString)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
        } else {
            completion(nil)
        }
    }

    // MARK: - User Profile Loading

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        let databaseRef = Database.database().reference().child("usuarios").child(uid)

        databaseRef.observeSingleEvent(of: .value) { (snapshot) in
            if let userData = snapshot.value as? [String: Any],
               let displayName = userData["displayName"] as? String,
               let email = userData["email"] as? String,
               let photoURL = userData["photoURL"] as? String {

                self.currentUser = UserProfile(uid: uid, displayName: displayName, email: email, photoURL: photoURL)
            } else {
                self.currentUser = UserProfile(uid: uid, displayName: "User login", email: Auth.auth().currentUser?.email ?? "", photoURL: nil)
            }

            self.updateUI()
        }
    }

    // MARK: - UI Update

    func updateUI() {
        displayNameLabel.text = currentUser?.displayName
        emailLabel.text = currentUser?.email

        if let photoURLString = currentUser?.photoURL, let photoURL = URL(string: photoURLString) {
            loadImage(from: photoURL) { image in
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            }
        } else {
            self.profileImageView.image = UIImage(named: "user")
        }
    }

    // MARK: - Image Loading

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }

    // MARK: - Alert

    func showAlert(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
