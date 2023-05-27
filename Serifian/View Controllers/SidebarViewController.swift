//
//  SidebarViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class SidebarViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var dataSource: UICollectionViewDiffableDataSource<String, SidebarItemViewModel>!
    private unowned var referencedDocument: SerifianDocument!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self.dataSource

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

        self.dataSource.apply(contentSnapshot(), to: "Files")
        self.view.backgroundColor = .secondarySystemBackground
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

    func populateSidebar(for document: SerifianDocument) {
        self.referencedDocument = document
    }
}

extension SidebarViewController: UICollectionViewDelegate {

}
