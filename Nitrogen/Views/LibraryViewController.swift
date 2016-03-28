//
//  LibraryViewController.swift
//  Nitrogen
//
//  Created by David Chavez on 20/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import RxCocoa
import Kingfisher

class LibraryViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!


    // MARK: - Attributes

    private var openVGDB: OESQLiteDatabase = try! OESQLiteDatabase(URL: NSBundle.mainBundle().URLForResource("openvgdb", withExtension: "sqlite"))
    private var gamesUpdateToken: NotificationToken = NotificationToken()
    private var games: Variable<[Game]> = Variable([])
    private var listener: DirectoryWatcher!


    // MARK: - Attributes (Reactive)

    let hankeyBag: DisposeBag = DisposeBag()


    // MARK: - UIView Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let realm: Realm = try! Realm()
        gamesUpdateToken = realm.objects(Game).addNotificationBlock() { [weak self] results, error in
            if let results = results {
                self?.games.value = Array(results)
            }
        }

        updateStore()
        processRootDirectory()

        let documentsDirectoryURL: NSURL! = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        listener = DirectoryWatcher(pathToWatch: documentsDirectoryURL) { [weak self] in
            self?.updateStore()
            self?.processRootDirectory()
        }
        listener.startWatching()

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
        let realm: Realm = try! Realm()
        let store: [Game] = Array(realm.objects(Game))
        let fm: NSFileManager = NSFileManager.defaultManager()

        for game in store {
            let documentsDirectoryURL: NSURL! = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            let ndsFile: NSURL! = documentsDirectoryURL.URLByAppendingPathComponent(game.path)

            if !fm.fileExistsAtPath(ndsFile.path!) {
                try! realm.write() {
                    realm.delete(game)
                }
            }
        }

        games.value = Array(realm.objects(Game))
    }

    private func processRootDirectory() {
        let realm: Realm = try! Realm()
        let documentsDirectoryURL: NSURL! = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let files: [NSURL] = try! fileManager.contentsOfDirectoryAtURL(documentsDirectoryURL, includingPropertiesForKeys: nil, options: [])

        for file in files {
            let fileExtension: String = file.pathExtension!
            if fileExtension.lowercaseString == "nds" {
                let title: String! = file.URLByDeletingPathExtension?.lastPathComponent

                let games: Results<Game> = realm.objects(Game).filter("path == '\(file.lastPathComponent!)'")
                if games.count > 0 {
                    if games.first!.processed { continue }
                    processGame(games.first!)
                } else {
                    let game: Game = Game()
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
        let query: String = "SELECT DISTINCT releaseTitleName as 'gameTitle', romSerial as 'serial', releaseCoverFront as 'boxImageURL', releaseDescription as 'gameDescription', regionName as 'region' FROM ROMs rom LEFT JOIN RELEASES release USING (romID) LEFT JOIN REGIONS region on (regionLocalizedID=region.regionID) WHERE serial = '\(game.serial.uppercaseString)'"
        let results: [[String : String]] = try! openVGDB.executeQuery(query) as! [[String: String]]
        let realm: Realm = try! Realm()
        if results.count > 0 {
            try! realm.write() {
                game.title = results.last?["gameTitle"] ?? game.title
                game.artworkURL = results.last?["boxImageURL"]
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
            let dataBuffer: NSData = dataFile.readDataOfLength(4)
            let serial: String? = String(data: dataBuffer, encoding: NSUTF8StringEncoding)
            dataFile.closeFile()

            return serial
        }

        return nil
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let index: NSIndexPath! = collectionView.indexPathsForSelectedItems()?.first
        let game: Game = self.games.value[index.item]
        let vc: EmulatorViewController = segue.destinationViewController as! EmulatorViewController
        vc.startEmulator(game)
    }
}
