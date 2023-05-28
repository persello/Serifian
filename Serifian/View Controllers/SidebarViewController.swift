//
//  SidebarViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class SidebarViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var dataSource: UICollectionViewDiffableDataSource<String, SidebarItemViewModel>?
    private unowned var referencedDocument: SerifianDocument!
    private var sourceChangeCallback: ((any SourceProtocol) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        self.collectionView.collectionViewLayout = layout
        self.collectionView.dataSource = self.dataSource

        let cell = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItemViewModel> { (cell, indexPath, item) in

            var contentConfiguration = UIListContentConfiguration.sidebarCell()
            contentConfiguration.image = item.image
            contentConfiguration.text = item.referencedSource.name

            cell.contentConfiguration = contentConfiguration
            if item.children != nil {
                cell.accessories = [.outlineDisclosure()]
            }
        }

        self.dataSource = UICollectionViewDiffableDataSource<String, SidebarItemViewModel>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell in

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
        snapshot.append([model], to: parent)

        if let children = model.children {
            for child in children {
                apply(model: child, to: model, in: &snapshot)
            }
        }
    }

    private func contentSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItemViewModel>()

        for item in self.referencedDocument.contents {
            apply(model: SidebarItemViewModel(referencedSource: item), to: nil, in: &snapshot)
        }

        return snapshot
    }

    private func updateSidebar() {
        self.dataSource?.apply(contentSnapshot(), to: "Files")
        self.navigationItem.title = referencedDocument.title
    }

    func setReferencedDocument(_ document: SerifianDocument) {
        self.referencedDocument = document
        self.updateSidebar()
    }

    func attachSourceSelectionCallback(_ callback: @escaping (any SourceProtocol) -> ()) {
        self.sourceChangeCallback = callback
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        if let item = dataSource?.itemIdentifier(for: indexPath) {
            if item.children == nil {
                return true
            }
        }

        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource?.itemIdentifier(for: indexPath) {
            self.sourceChangeCallback?(item.referencedSource)
        }
    }
}
