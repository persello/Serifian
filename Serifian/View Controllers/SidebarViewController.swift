//
//  SidebarViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import os

class SidebarViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var dataSource: UICollectionViewDiffableDataSource<String, SidebarItemViewModel>?
    private unowned var referencedDocument: SerifianDocument!
    private var sourceChangeCallback: ((any SourceProtocol) -> ())?
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SidebarViewController")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Self.logger.info("Configuring sidebar.")

        // Do any additional setup after loading the view.
        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        self.collectionView.collectionViewLayout = layout
        self.collectionView.dataSource = self.dataSource
        self.collectionView.backgroundColor = .clear
        
        let cell = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItemViewModel> { (cell, indexPath, item) in

            Self.logger.trace("Building cell for \(item.referencedSource.name).")
            
            var contentConfiguration = UIListContentConfiguration.sidebarCell()
            contentConfiguration.image = item.image
            contentConfiguration.text = item.referencedSource.name

            cell.contentConfiguration = contentConfiguration
            if item.children != nil {
                cell.accessories = [.outlineDisclosure()]
            }

            cell.configurationUpdateHandler = { cell, state in
                
                Self.logger.trace("Updating cell for \(item.referencedSource.name).")
                
                var contentConfiguration = cell.contentConfiguration as! UIListContentConfiguration

                if cell.isSelected {
                    contentConfiguration.image = item.image.withConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))
                } else {
                    contentConfiguration.image = item.image
                }

                cell.contentConfiguration = contentConfiguration
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

    private func apply(
        model: SidebarItemViewModel,
        to parent: SidebarItemViewModel?,
        in snapshot: inout NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel>
    ) {
        
        Self.logger.trace("Applying \(model.referencedSource.name) to \(parent?.referencedSource.name ?? "root model").")
        
        snapshot.append([model], to: parent)

        if let children = model.children {
            for child in children {
                apply(model: child, to: model, in: &snapshot)
            }
        }
    }

    private func contentSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel> {
        
        Self.logger.trace("Creating content snapshot.")
        
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel>()

        for item in self.referencedDocument.getSources() {
            apply(model: SidebarItemViewModel(referencedSource: item), to: nil, in: &snapshot)
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
    }
}
