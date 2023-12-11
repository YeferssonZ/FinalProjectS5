//
//  UserProfile.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 11/12/23.
//

import Foundation

class UserProfile {
    var uid: String
    var displayName: String?
    var email: String
    var photoURL: String?

    init(uid: String, displayName: String?, email: String, photoURL: String?) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
    }
}
