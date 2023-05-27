//
//  SidebarViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class SidebarViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collectionView.collectionViewLayout = layout

//        let dataSource = UICollectionViewDiffableDataSource<String, UUID>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
//            
//        }
    }

}

extension SidebarViewController: UICollectionViewDelegate {

}
