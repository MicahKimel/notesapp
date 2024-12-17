//
//  ContentView.swift
//  Notes
//
//  Created by Micah Kimel on 12/17/24.
//

import SwiftUI
import MarkdownUI
import Splash


struct ContentView: View {
    @StateObject var db = NotesDatabase()
    @State private var isEditing = false
    @State private var selectedNote: Note = Note()
    @State private var showNoteEditor = false
    @State private var NoteList: [Note] = []

    var body: some View {
        NavigationView{
            VStack {
                Text("Notes")
                    .font(.title)
                NavigationLink("Add Item", destination: NoteEditorView(note: Note(), db: db))
                List {
                    ForEach(NoteList) { note in
                        Button(action: {
                            selectedNote = note
                            showNoteEditor = true
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(note.title).font(.headline)
                                    Text("Last Modified: \(note.lastModified)").font(.caption)
                                }
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .onAppear(){
                    NoteList = db.getAllNotes()
                }
                .fullScreenCover(isPresented: $showNoteEditor) {
                    NoteEditorView(note: selectedNote, db: db)
                        .onDisappear(){
                            selectedNote = Note()
                            NoteList = db.getAllNotes()
                        }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

        private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let notesToDelete = offsets.map { db.getAllNotes()[$0] }
            for note in notesToDelete {
                db.deleteNote(note: note)
            }
        }
    }
}

struct NoteEditorView: View {
    @State var note: Note = Note()
    @Environment(\.dismiss) var dismiss
    @ObservedObject var db: NotesDatabase
    @State private var showMarkdown = false
    @FocusState var isInputActive: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: Binding(
                    get: { note.title },
                    set: { note.title = $0 }
                ))
                .focused($isInputActive)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Done") {
                            isInputActive = false
                        }
                    }
                }
                .padding()
                TextEditor(text: Binding(
                    get: { note.content },
                    set: { note.content = $0 }
                ))
                .padding()
                if showMarkdown {
                    ScrollView {
                        Markdown(note.content)
                                .markdownBlockStyle(\.codeBlock) {
                                  codeBlock($0)
                                }
                                .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                            }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showMarkdown.toggle()
                        }) {
                            Text(showMarkdown ? "Edit" : "Preview")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let noteToSave = note
                            db.saveNote(note: noteToSave)
                            dismiss()
                        }
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
@ViewBuilder
  private func codeBlock(_ configuration: CodeBlockConfiguration) -> some View {
    VStack(spacing: 0) {
      HStack {
        Text(configuration.language ?? "plain text")
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.semibold)
          .foregroundColor(Color(theme.plainTextColor))
        Spacer()

        Image(systemName: "clipboard")
          .onTapGesture {
            copyToClipboard(configuration.content)
          }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .background {
        Color(theme.backgroundColor)
      }

      Divider()

      ScrollView(.horizontal) {
        configuration.label
          .relativeLineSpacing(.em(0.25))
          .markdownTextStyle {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
          }
          .padding()
      }
    }
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .markdownMargin(top: .zero, bottom: .em(0.8))
  }

  private var theme: Splash.Theme {
    // NOTE: We are ignoring the Splash theme font
    switch self.colorScheme {
    case .dark:
      return .wwdc17(withFont: .init(size: 16))
    default:
      return .sunset(withFont: .init(size: 16))
    }
  }

  private func copyToClipboard(_ string: String) {
    #if os(macOS)
      if let pasteboard = NSPasteboard.general {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
      }
    #elseif os(iOS)
      UIPasteboard.general.string = string
    #endif
  }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()



#Preview {
    ContentView()
}
