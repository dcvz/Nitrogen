//
//  LibraryViewController.swift
//  Nitrogen
//
//  Created by David Chavez on 20/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import RealmSwift
import SQLite
import DirectoryObserver
import GrandSugarDispatch

class LibraryViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!


    // MARK: - Attributes

    private var openVGDB = try! Connection(NSBundle.mainBundle().pathForResource("openvgdb", ofType: "sqlite")!)
    private var gamesUpdateToken = NotificationToken()
    private var games: Variable<[Game]> = Variable([])
    private var listener: DirectoryObserver!


    // MARK: - Attributes (Reactive)

    private let hankeyBag = DisposeBag()


    // MARK: - UIView Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm()
        gamesUpdateToken = realm.objects(Game).addNotificationBlock() { [weak self] results, error in
            if let results = results {
                self?.games.value = Array(results)
            }
        }

        updateStore()
        processRootDirectory()

        let documentsDirectoryURL = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        listener = DirectoryObserver(pathToWatch: documentsDirectoryURL) { [weak self] in
            self?.updateStore()
            self?.processRootDirectory()
        }

        _ = try? listener.startObserving()

        games
            .asObservable()
            .bindTo(collectionView.rx_itemsWithCellIdentifier("gameCell", cellType: LibraryCell.self)) { row, element, cell in
                if let artworkURL = element.artworkURL {
                    cell.artworkImageView.kf_setImageWithURL(NSURL(string: artworkURL)!)
                }

                cell.titleLabel.text = element.title
            }.addDisposableTo(hankeyBag)
    }


    // MARK: - Private Methods

    private func updateStore() {
        let realm = try! Realm()
        let store = Array(realm.objects(Game))
        let fileManager = NSFileManager.defaultManager()

        for game in store {
            let documentsDirectoryURL = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            let ndsFile = documentsDirectoryURL.URLByAppendingPathComponent(game.path)

            if !fileManager.fileExistsAtPath(ndsFile.path!) {
                try! realm.write() {
                    realm.delete(game)
                }
            }
        }

        games.value = Array(realm.objects(Game))
    }

    private func processRootDirectory() {
        let realm = try! Realm()
        let documentsDirectoryURL = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let fileManager = NSFileManager.defaultManager()
        let files = try! fileManager.contentsOfDirectoryAtURL(documentsDirectoryURL, includingPropertiesForKeys: nil, options: [])

        for file in files {
            let fileExtension = file.pathExtension!
            if fileExtension.lowercaseString == "nds" {
                let title = file.URLByDeletingPathExtension!.lastPathComponent!

                let games = realm.objects(Game).filter("path == '\(file.lastPathComponent!)'")
                if games.count > 0 {
                    if games.first!.processed { continue }
                    processGame(games.first!)
                } else {
                    let game = Game()
                    game.title = title
                    game.serial = serialForFile(file)!
                    game.path = file.lastPathComponent!
                    try! realm.write() { realm.add(game) }
                    processGame(game)
                }
            }
        }
    }

    private func processGame(game: Game) {
        let realm = try! Realm()

        let roms = Table("ROMs")
        let releases = Table("RELEASES")

        let gameTitle = Expression<String>("releaseTitleName")
        let serial = Expression<String>("romSerial")
        let boxImageURL = Expression<String>("releaseCoverFront")
        let romID = Expression<String>("romID")

        let query = roms.select(distinct: [gameTitle, serial, boxImageURL])
                        .join(.LeftOuter, releases, on: roms[romID] == releases[romID])
                        .filter(serial == game.serial.uppercaseString)

        let results = try! openVGDB.prepare(query)
        if let result = results.generate().next() {
            try! realm.write() {
                game.title = result[gameTitle] ?? game.title
                game.artworkURL = result[boxImageURL]
                game.processed = true
            }
        } else {
            try! realm.write() {
                game.processed = true
            }
        }
    }

    private func serialForFile(file: NSURL) -> String? {
        if let dataFile = enclose({ try NSFileHandle(forReadingFromURL: file) }) {
            dataFile.seekToFileOffset(0xC)
            let dataBuffer = dataFile.readDataOfLength(4)
            let serial = String(data: dataBuffer, encoding: NSUTF8StringEncoding)
            dataFile.closeFile()

            return serial
        }

        return nil
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let index = collectionView.indexPathsForSelectedItems()!.first!
        let game = self.games.value[index.item]
        let vc = segue.destinationViewController as! EmulatorViewController

        dispatch(queue: .main, execution: .delay(seconds: 0.3)) {
            vc.startEmulator(game)
        }
    }
}
