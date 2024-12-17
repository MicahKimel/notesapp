//
//  Models.swift
//  Notes
//
//  Created by Micah Kimel on 12/17/24.
//


struct Note: Identifiable {
    let id: Int
    var title: String
    var content: String
    let lastModified: String

    init(id: Int, title: String, content: String, lastModified: String) {
        self.id = id
        self.title = title
        self.content = content
        self.lastModified = lastModified
    }
    
    init(){
        self.id = 0
        self.title = ""
        self.content = ""
        self.lastModified = ""
    }
}

struct Folder: Identifiable{
    let id: Int
    var title: String
    let lastModified: String

    init(id: Int, title: String, lastModified: String) {
        self.id = id
        self.title = title
        self.lastModified = lastModified
    }
    
    init(){
        self.id = 0
        self.title = ""
        self.lastModified = ""
    }
}
