//
//  ViewControllerSignIn.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 5/12/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseAnalytics

class ViewControllerSignIn: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Configuración adicional si es necesaria
    }

    @IBAction func VolverTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Crear Usuario Tapped
    @IBAction func crearUsuarioTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty
        else {
            mostrarAlerta(titulo: "Campos Vacíos", mensaje: "Por favor, completa todos los campos.", accion: "Aceptar")
            return
        }

        guard password == confirmPassword else {
            mostrarAlerta(titulo: "Contraseñas no Coinciden", mensaje: "Las contraseñas no coinciden. Por favor, inténtalo de nuevo.", accion: "Aceptar")
            return
        }

        // Validar formato de correo electrónico
        guard isValidEmail(email) else {
            mostrarAlerta(titulo: "Formato de Correo Inválido", mensaje: "Por favor, ingresa un correo electrónico válido.", accion: "Aceptar")
            return
        }

        // Validar longitud de contraseña
        guard isPasswordValid(password) else {
            mostrarAlerta(titulo: "Contraseña Débil", mensaje: "La contraseña debe tener al menos 6 caracteres.", accion: "Aceptar")
            return
        }

        // Intentar crear un nuevo usuario
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            print("Intentando crear un usuario")
            if let error = error {
                print("Se presentó el siguiente error al crear el usuario: \(error.localizedDescription)")
                self.mostrarAlerta(titulo: "Error al Crear Usuario", mensaje: "Ocurrió un error al crear el usuario. Verifica tu conexión a Internet y vuelve a intentarlo.", accion: "Aceptar")

                // Registra un evento de creación de usuario fallido
                Analytics.logEvent("registro_fallido", parameters: ["error": error.localizedDescription])
            } else {
                // Usuario creado exitosamente
                print("El usuario fue creado exitosamente")

                // Guardar información adicional del usuario en la base de datos
                if let uid = user?.user.uid, let email = user?.user.email {
                    self.saveAdditionalUserInfo(uid: uid, email: email)

                    // Registra un evento de creación de usuario exitoso
                    Analytics.logEvent("registro_exitoso", parameters: nil)
                }

                // Mostrar un mensaje de éxito con la opción de ir a la lista de músicas
                let alerta = UIAlertController(title: "Registro Exitoso", message: "¡El usuario se registró con éxito!", preferredStyle: .alert)
                let btnAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
                let btnIrALista = UIAlertAction(title: "Ir a Lista de Músicas", style: .default) { (action) in
                    self.irAListaDeMusicas()
                }

                alerta.addAction(btnAceptar)
                alerta.addAction(btnIrALista)
                self.present(alerta, animated: true, completion: nil)
            }
        }
    }

    func irAListaDeMusicas() {
        // Realizar el segue a la lista de músicas (asegúrate de tener un identificador adecuado)
        self.performSegue(withIdentifier: "registrocompletosegue", sender: self)
    }

    func mostrarAlerta(titulo: String, mensaje: String, accion: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        let btnOK = UIAlertAction(title: accion, style: .default, handler: nil)
        alerta.addAction(btnOK)
        present(alerta, animated: true, completion: nil)
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func isPasswordValid(_ password: String) -> Bool {
        return password.count >= 6
    }

    // Función para guardar información adicional del usuario en la base de datos
    func saveAdditionalUserInfo(uid: String, email: String) {
        let userData = ["email": email]
        Database.database().reference().child("usuarios").child(uid).setValue(userData)

        // Registra un evento de almacenamiento exitoso de información adicional del usuario
        Analytics.logEvent("informacion_adicional_guardada", parameters: nil)
    }
}
