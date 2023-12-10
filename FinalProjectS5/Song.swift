//
//  Song.swift
//  FinalProjectS5
//
//  Created by Yefersson Guillermo Zuñiga Justo on 9/12/23.
//

import Foundation

class Song {
    var remitente: String?
    var cancion: String?
    var artista: String?
    var imageUrl: String?
    var audioUrl: String?

    init(remitente: String?, cancion: String?, artista: String?, imageUrl: String?, audioUrl: String?) {
        self.remitente = remitente
        self.cancion = cancion
        self.artista = artista
        self.imageUrl = imageUrl
        self.audioUrl = audioUrl
    }
}
