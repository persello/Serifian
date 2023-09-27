//
//  SidebarViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import os

class SidebarViewController: UIViewController {

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private weak var rootSplitViewController: RootSplitViewController!
    
    private var dataSource: UICollectionViewDiffableDataSource<String, SidebarItemViewModel>?
    private unowned var referencedDocument: SerifianDocument!
    private var sourceChangeCallback: ((any SourceProtocol) -> ())?
    
    private var endRenamingCallback: ((String?) -> ())?
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SidebarViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.rootSplitViewController = self.parent?.parent as? RootSplitViewController
        
        Self.logger.trace("Configuring add button.")
        self.addButton.menu = UIMenu(
            children: [
                UIAction(title: "New Typst file...", image: UIImage(named: "custom.t.square.badge.plus"), handler: { _ in
                    let source = TypstSourceFile(preferredName: "untitled", content: "", in: nil, partOf: self.referencedDocument)
                    self.referencedDocument.addSource(source)
                    self.updateSidebar()
                }),
                UIAction(title: "Import existing...", image: UIImage(systemName: "square.and.arrow.down.on.square"), handler: { _ in
                    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.png, .jpeg, .gif, .svg, .plainText, .text])
                    
                    picker.allowsMultipleSelection = true
                    picker.shouldShowFileExtensions = true
                    picker.delegate = self
                    
                    self.present(picker, animated: true)
                })
            ]
        )
        
        Self.logger.trace("Configuring sidebar.")

        // Do any additional setup after loading the view.
        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        self.collectionView.collectionViewLayout = layout
        self.collectionView.dataSource = self.dataSource
        self.collectionView.backgroundColor = .clear
        
        let cell = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItemViewModel> { (cell, indexPath, item) in

            Self.logger.trace("Building cell for \(item.referencedSource.name).")
                        
            let textField = UITextField()
            textField.delegate = self
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.tintColor = .systemBlue
            
            let image = UIImageView(image: item.image)
            
            let sc = image.widthAnchor.constraint(equalTo: image.heightAnchor)
            sc.isActive = true
            
            let wc = image.widthAnchor.constraint(equalToConstant: 24)
            wc.isActive = true
            
            let container = UIStackView(arrangedSubviews: [image, textField])
            container.alignment = .center
            container.axis = .horizontal
            container.spacing = 8.0
                                            
            cell.accessories = [
                .customView(
                    configuration: .init(
                        customView: container,
                        placement: .leading(displayed: .always),
                        reservedLayoutWidth: .actual
                    )
                ),
            ]

            if item.children != nil {
                cell.accessories += [.outlineDisclosure()]
            }

            cell.configurationUpdateHandler = { cell, state in
                Self.logger.trace("Updating cell for \(item.referencedSource.name).")
                
                // Update cell data.
                textField.text = item.referencedSource.name
                
                // Manage selection color.
                if cell.isSelected {
                    image.image = item.image.withConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))
                    textField.textColor = .white
                } else {
                    image.image = item.image
                    textField.textColor = .label
                }
                
                // Manage renaming style.
                if item.isRenaming {
                    cell.tintColor = .systemBackground
                    image.image = item.image
                    textField.textColor = .label
                    textField.isEnabled = true
                    textField.becomeFirstResponder()
                    textField.selectAll(nil)
                } else {
                    cell.tintColor = .tintColor
                    textField.isEnabled = false
                }
            }
        }

        self.dataSource = UICollectionViewDiffableDataSource<String, SidebarItemViewModel>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell in
            
            Self.logger.trace("Dequeuing cell for \(item.referencedSource.name).")

            return collectionView.dequeueConfiguredReusableCell(using: cell, for: indexPath, item: item)
        }

        self.view.backgroundColor = .secondarySystemBackground
        self.updateSidebar()
    }

    private func append(
        model: SidebarItemViewModel,
        to parent: SidebarItemViewModel?,
        in snapshot: inout NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel>
    ) {
        
        Self.logger.trace("Applying \(model.referencedSource.name) to \(parent?.referencedSource.name ?? "root model").")
        
        snapshot.append([model], to: parent)

        if let children = model.children {
            for child in children {
                append(model: child, to: model, in: &snapshot)
            }
        }
    }

    private func contentSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel> {
        
        Self.logger.trace("Creating content snapshot.")
        
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel>()

        for item in self.referencedDocument.getSources().sorted(by: {$0.name.compare($1.name) == .orderedAscending}) {
            append(model: SidebarItemViewModel(referencedSource: item), to: nil, in: &snapshot)
        }

        return snapshot
    }

    private func updateSidebar() {
        Self.logger.info("Updating sidebar.")
        
        self.dataSource?.apply(contentSnapshot(), to: "Files")
        self.navigationItem.title = referencedDocument.title
    }

    func setReferencedDocument(_ document: SerifianDocument) {
        Self.logger.info(#"Setting referenced document to "\#(document.title)"."#)
        
        self.referencedDocument = document
        self.updateSidebar()
    }

    func attachSourceSelectionCallback(_ callback: @escaping (any SourceProtocol) -> ()) {
        Self.logger.info("Attaching change selection callback.")
        
        self.sourceChangeCallback = callback
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let item = dataSource?.itemIdentifier(for: indexPath) {
            if item.children == nil {
                return true
            }
        }

        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource?.itemIdentifier(for: indexPath) {
            
            Self.logger.info("Selecting item at \(indexPath): \(item.referencedSource.name).")
            
            self.sourceChangeCallback?(item.referencedSource)
        } else {
            Self.logger.info("Trying to select item at \(indexPath), but there is no associated model.")
        }
        
        if self.rootSplitViewController.splitBehavior == .overlay {
            UIView.animate {
                self.rootSplitViewController.preferredDisplayMode = .secondaryOnly
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        let items = indexPaths.compactMap({dataSource?.itemIdentifier(for: $0)})
        
        guard let item = items.first else { return nil }
        
        var actions: [UIMenuElement] = []
        let renameAction = UIAction(
            title: "Rename",
            image: UIImage(systemName: "pencil"),
            handler: { _ in
                // End the previous renaming.
                self.endRenamingCallback?(nil)
                
                // Begin the current renaming.
                item.isRenaming = true
                self.endRenamingCallback = { newName in
                    item.isRenaming = false
                    
                    if let newName {
                        do {
                            try item.referencedSource.rename(to: newName)
                        } catch let error as SourceError {
                            let alert = UIAlertController(title: error.errorDescription, message: error.failureReason, preferredStyle: .alert)
                            
                            alert.addAction(.init(title: "OK", style: .default, handler: { _ in
                                alert.dismiss(animated: true)
                            }))
                            
                            self.present(alert, animated: true)
                        } catch {
                            fatalError(error.localizedDescription)
                        }
                    }
                }
            }
        )
        
        actions += [renameAction]
        
        if let source = item.referencedSource as? TypstSourceFile,
           !source.isMain {
            let mainSourceAction = UIAction(
                title: "Set as main source",
                image: UIImage(systemName: "checkmark.seal.fill"),
                handler: { _ in
                    source.setAsMain()
                    self.updateSidebar()
                }
            )
            
            actions += [mainSourceAction]
        }
        
        let configuration = UIContextMenuConfiguration(actionProvider: { _ in
            UIMenu(children: actions)
        })
        
        return configuration
    }
}

extension SidebarViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.endRenamingCallback?(textField.text)
    }
}

extension SidebarViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            if let wrapper = try? FileWrapper(url: url),
               let source = sourceProtocolObjectFrom(fileWrapper: wrapper, in: nil, partOf: self.referencedDocument) {
                self.referencedDocument.addSource(source)
            }
        }
        
        self.updateSidebar()
    }
}

#Preview {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(identifier: "RootSplitViewController") as! RootSplitViewController
    
    let documentURL = Bundle.main.url(forResource: "Empty", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    try! vc.setDocument(document)
    
    vc.preferredDisplayMode = .oneBesideSecondary
    
    return vc
}
