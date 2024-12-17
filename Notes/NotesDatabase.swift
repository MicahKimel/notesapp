//
//  NotesDatabase.swift
//  Notes
//
//  Created by Micah Kimel on 12/17/24.
//
import SQLite3
import Foundation



class NotesDatabase: ObservableObject {
    let db: OpaquePointer?
    let path: String = "note.sqlite"

    init() {
        do {
            
            let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(path)
            var db: OpaquePointer? = nil
            if sqlite3_open_v2(filePath.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
                print("SQLITE: There is an error in creating db \(path)")
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
            }
            
            self.db = db
            
            createFolder()
            createNotes()
            createFolderMap()
        } catch {
            fatalError("Error initializing database: \(error)")
        }
    }
    
    // This could be used for backing up to the cloud
    func encodeDb(){
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(self.path)
        let fileContents = FileManager.default.contents(atPath: filePath.path)!
        let base64String = fileContents.base64EncodedString()
        let data = Data(base64Encoded: base64String)
    }
    
    func createNotes(){
        do{
            let query = "CREATE TABLE IF NOT EXISTS Notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT," +
            " content TEXT, lastModified TEXT);"
            var createTable: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &createTable, nil) == SQLITE_OK {
                if sqlite3_step(createTable) == SQLITE_DONE{
                    print("SQLITE: created Notes table or table exists")
                } else {
                    _ = String(cString: sqlite3_errmsg(db))
                    print("SQLITE: Notes table creation failed")
                }
                sqlite3_finalize(createTable)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: prep Notes table creation failed")
            }
        } catch {
            fatalError("Error initializing Notes: \(error)")
        }
    }
    
    
    func createFolderMap() {
        do {
            let query = "CREATE TABLE IF NOT EXISTS FolderMap(id INTEGER, subid INTEGER," +
            " lastModified TEXT);"
            var createTable: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &createTable, nil) == SQLITE_OK {
                if sqlite3_step(createTable) == SQLITE_DONE{
                    print("SQLITE: created FolderMap table or table exists")
                } else {
                    _ = String(cString: sqlite3_errmsg(db))
                    print("SQLITE: FolderMap table creation failed")
                }
                sqlite3_finalize(createTable)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: prep FolderMap table creation failed")
            }
        } catch {
            fatalError("Error initializing FolderMap: \(error)")
        }
    }
    
    func saveFolderMap(ParentFolder: Int, SubFolder: Int) {
        do {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss a"
            let now = df.string(from: Date())
            let query = "insert into FolderMap (id, subid, lastModified) VALUES " +
            " ('\(ParentFolder)', \(SubFolder), '\(now)');"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE{
                    print("SQLITE: FolderMap Data update success")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print(errorMessage)
                    print("SQLITE: FolderMap Data did not update in table")
                }
                sqlite3_finalize(statement)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: FolderMap prep update failed")
            }
        } catch {
            print("Error saving FolderMap: \(error)")
        }
    }
    
    func deleteFolderMap(ParentFolder: Int, SubFolder: Int) {
        do {
            let query = "DELETE FROM FolderMap WHERE id = \(ParentFolder) AND subid = \(SubFolder);"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE{
                    print("SQLITE: FolderMap Data DELETE success")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print(errorMessage)
                    print("SQLITE: FolderMap Data did not DELETE in table")
                }
                sqlite3_finalize(statement)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: FolderMap prep DELETE failed")
            }
        } catch {
            print("Error DELETE FolderMap: \(error)")
        }
    }
    
    func createFolder() {
        do {
            let query = "CREATE TABLE IF NOT EXISTS Folder(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT," +
            " lastModified TEXT);"
            var createTable: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &createTable, nil) == SQLITE_OK {
                if sqlite3_step(createTable) == SQLITE_DONE{
                    print("SQLITE: created Folder table or table exists")
                } else {
                    _ = String(cString: sqlite3_errmsg(db))
                    print("SQLITE: Folder table creation failed")
                }
                sqlite3_finalize(createTable)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: prep Folder table creation failed")
            }
        } catch {
            fatalError("Error initializing Folder: \(error)")
        }
    }
    
    func getAllFolder() -> [Folder] {
        do {
            var list: [Folder] = []
            let query = "SELECT id, title, lastModified FROM Folder order by lastModified desc;"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare(self.db, query, -1, &statement, nil) == SQLITE_OK{
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(statement, 0))
                    let title = String(cString: sqlite3_column_text(statement, 1))
                    let noteId = Int(sqlite3_column_int(statement, 2))
                    let lastModified = String(cString: sqlite3_column_text(statement, 3))
//                    let mynote = Note(id: id, title: title, content: content, lastModified: lastModified)
                    list.append(Folder(id: id, title: title, noteId: noteId, lastModified: lastModified))
                }
            }
            sqlite3_finalize(statement)
            return list
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }
    
    func saveFolder(folder: Folder) {
        do {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss a"
            let now = df.string(from: Date())
            let query = "insert into Folder (title, lastModified) VALUES " +
            " ('\(folder.title.replacingOccurrences(of: "'", with: "''"))', '\(now)');"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE{
                    print("SQLITE: Folder Data update success")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print(errorMessage)
                    print("SQLITE: Folder Data did not update in table")
                }
                sqlite3_finalize(statement)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: Folder prep update failed")
            }
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    func deleteFolder(folder: Folder) {
        do {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss a"
            let now = df.string(from: Date())
            let query = "DELETE FROM Folder WHERE id = \(folder.id);"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE{
                    print("SQLITE: Folder Data DELETE success")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print(errorMessage)
                    print("SQLITE: Folder Data did not DELETE in table")
                }
                sqlite3_finalize(statement)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: Folder prep DELETE failed")
            }
        } catch {
            print("Error DELETE Folder: \(error)")
        }
    }

    func getAllNotes() -> [Note] {
        do {
            var list: [Note] = []
            let query = "SELECT id, title, content, lastModified FROM Notes order by lastModified desc;"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare(self.db, query, -1, &statement, nil) == SQLITE_OK{
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(statement, 0))
                    let title = String(cString: sqlite3_column_text(statement, 1))
                    let content = String(cString: sqlite3_column_text(statement, 2))
                    let lastModified = String(cString: sqlite3_column_text(statement, 3))
//                    let mynote = Note(id: id, title: title, content: content, lastModified: lastModified)
                    list.append(Note(id: id, title: title, content: content, lastModified: lastModified))
                }
            }
            sqlite3_finalize(statement)
            return list
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }

    func saveNote(note: Note) {
        do {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss a"
            let now = df.string(from: Date())
            let query = "insert into Notes (title, content, lastModified) VALUES " +
            " ('\(note.title.replacingOccurrences(of: "'", with: "''"))', '\(note.content.replacingOccurrences(of: "'", with: "''"))', '\(now)');"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE{
                    print("SQLITE: Notes Data update success")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print(errorMessage)
                    print("SQLITE: Notes Data did not update in table")
                }
                sqlite3_finalize(statement)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: Notes prep update failed")
            }
        } catch {
            print("Error saving note: \(error)")
        }
    }

    func deleteNote(note: Note) {
        do {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss a"
            let now = df.string(from: Date())
            let query = "DELETE FROM Notes WHERE id = \(note.id);"
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE{
                    print("SQLITE: Notes Data DELETE success")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print(errorMessage)
                    print("SQLITE: Notes Data did not DELETE in table")
                }
                sqlite3_finalize(statement)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print(errorMessage)
                print("SQLITE: Notes prep DELETE failed")
            }
        } catch {
            print("Error DELETE note: \(error)")
        }
    }
}
