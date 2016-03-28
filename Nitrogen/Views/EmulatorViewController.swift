//
//  EmulatorViewController.swift
//  Nitrogen
//
//  Created by David Chavez on 19/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import UIKit
import GLKit
import PureLayout
import LRNotificationObserver
import RxSwift

class EmulatorViewController: UIViewController, GLKViewDelegate {

    // MARK: - IBOutlets

    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var mainView: GLKView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var aButton: UIButton!
    @IBOutlet weak var bButton: UIButton!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var yButton: UIButton!
    @IBOutlet weak var lButton: UIButton!
    @IBOutlet weak var rButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!


    // MARK: - Attributes (Instance)

    private var emulator: EmulatorCore = EmulatorCore()
    private var currentGame: Game!
    private var audioCore: OEGameAudio!
    private let effect: GLKBaseEffect = GLKBaseEffect()
    private var texture: GLuint = 0


    // MARK: - Attributes (Reactive)

    let hankeyBag: DisposeBag = DisposeBag()


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
        setupNotifications()
        setupGL()
    }


    // MARK: - Public Interface

    func startEmulator(game: Game) {
        let documentsDirectoryURL: NSURL! =  try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let ndsFile: NSURL! = documentsDirectoryURL.URLByAppendingPathComponent(game.path)

        currentGame = game

        audioCore = OEGameAudio(core: emulator)
        audioCore.volume = 1.0
        audioCore.outputDeviceID = 0
        audioCore.startAudio()

        emulator.loadROM(ndsFile.path)
        emulator.startEmulation()
        emulator.updateFrameBlock = { [weak self] in
            if let s = self {
                let fps = s.emulator.fps()

                dispatch_async(dispatch_get_main_queue()) {
                    s.fpsLabel.text = "\(fps) FPS"
                    s.mainView.display()
                }
            }
        }
    }


    // MARK: - Private Methods

    private func setupView() {
        startButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Start)
        }.addDisposableTo(hankeyBag)
        startButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Start)
        }.addDisposableTo(hankeyBag)

        aButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.A)
        }.addDisposableTo(hankeyBag)
        aButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.A)
        }.addDisposableTo(hankeyBag)

        bButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.B)
        }.addDisposableTo(hankeyBag)
        bButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.B)
        }.addDisposableTo(hankeyBag)

        xButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.X)
        }.addDisposableTo(hankeyBag)
        xButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.X)
        }.addDisposableTo(hankeyBag)

        yButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Y)
        }.addDisposableTo(hankeyBag)
        yButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Y)
        }.addDisposableTo(hankeyBag)

        lButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.L)
        }.addDisposableTo(hankeyBag)
        lButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.L)
        }.addDisposableTo(hankeyBag)

        rButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.R)
        }.addDisposableTo(hankeyBag)
        rButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.R)
        }.addDisposableTo(hankeyBag)

        menuButton.rx_touchdown.subscribeNext() { [weak self] in
            if let s = self {
                let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

                let toggleFPS = UIAlertAction(title: "Toggle FPS", style: .Default) { _ in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let s = self {
                            s.fpsLabel.hidden = !s.fpsLabel.hidden
                        }
                    }
                }

                let cheatAction = UIAlertAction(title: "Cheats (\(s.emulator.numberOfCheats()))", style: .Default) { action in
                    self?.performSegueWithIdentifier("showCheats", sender: self)
                }

                let closeAction = UIAlertAction(title: "Close ROM", style: .Destructive) { action in
                    self?.emulator.stopEmulation()
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }

                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

                sheet.addAction(toggleFPS)
                sheet.addAction(cheatAction)
                sheet.addAction(closeAction)
                sheet.addAction(cancelAction)
                self?.presentViewController(sheet, animated: true, completion: nil)
            }
        }.addDisposableTo(hankeyBag)

        selectButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Select)
        }.addDisposableTo(hankeyBag)
        selectButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Select)
        }.addDisposableTo(hankeyBag)

        leftButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Left)
        }.addDisposableTo(hankeyBag)
        leftButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Left)
        }.addDisposableTo(hankeyBag)

        downButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Down)
        }.addDisposableTo(hankeyBag)
        downButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Down)
        }.addDisposableTo(hankeyBag)

        rightButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Right)
        }.addDisposableTo(hankeyBag)
        rightButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Right)
        }.addDisposableTo(hankeyBag)

        upButton.rx_touchdown.subscribeNext() { [weak self] in
            self?.emulator.pressedButton(.Up)
        }.addDisposableTo(hankeyBag)
        upButton.rx_untap.subscribeNext() { [weak self] in
            self?.emulator.releasedButton(.Up)
        }.addDisposableTo(hankeyBag)
    }

    private func setupNotifications() {
        LRNotificationObserver.observeName(UIApplicationWillResignActiveNotification, object: nil, owner: self) { [weak self] note in
            self?.emulator.pauseEmulation()
        }

        LRNotificationObserver.observeName(UIApplicationDidBecomeActiveNotification, object: nil, owner: self) { [weak self] note in
            self?.emulator.resumeEmulation()
        }
    }

    private func setupGL() {
        let glContext: EAGLContext = EAGLContext(API: .OpenGLES2)
        EAGLContext.setCurrentContext(glContext)
        mainView.context = glContext
        setupTexture()
    }

    private func setupTexture() {
        glGenTextures(1, &texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, emulator.internalPixelFormat(), GLsizei(emulator.bufferSize().width), GLsizei(emulator.bufferSize().height), 0, emulator.pixelFormat(), emulator.pixelType(), emulator.videoBuffer())
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLfloat(GL_NEAREST))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLfloat(GL_NEAREST))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
    }


    // MARK: - GLKViewDelegate

    func glkView(view: GLKView, drawInRect rect: CGRect) {
        glClearColor(1.0, 1.0, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        let screenSize: CGSize = emulator.screenRect().size
        let bufferSize: CGSize = emulator.bufferSize()

        let texWidth: Float = Float(screenSize.width / bufferSize.width)
        let texHeight: Float = Float(screenSize.height / bufferSize.height)

        var vertices: [GLKVector3] = Array<GLKVector3>(count: 8, repeatedValue: GLKVector3())
        vertices[0] = GLKVector3(v: (-1.0, -1.0,  1.0)) // Left  bottom
        vertices[1] = GLKVector3(v: ( 1.0, -1.0,  1.0)) // Right  bottom
        vertices[2] = GLKVector3(v: ( 1.0,  1.0,  1.0)) // Right  top
        vertices[3] = GLKVector3(v: (-1.0,  1.0,  1.0)) // Left  top

        var textureCoordinates: [GLKVector2] = Array<GLKVector2>(count: 8, repeatedValue: GLKVector2())
        textureCoordinates[0] = GLKVector2(v: (0.0, texHeight)) // Left bottom
        textureCoordinates[1] = GLKVector2(v: (texWidth, texHeight)) // Right bottom
        textureCoordinates[2] = GLKVector2(v: (texWidth, 0.0)) // Right top
        textureCoordinates[3] = GLKVector2(v: (0.0, 0.0)) // Left top

        let vertexIndices: [Int] = [
            0, 1, 2,
            0, 2, 3
        ]

        var triangleVertices: [GLKVector3] = Array<GLKVector3>(count: 6, repeatedValue: GLKVector3())
        var triangleTexCoords: [GLKVector2] = Array<GLKVector2>(count: 6, repeatedValue: GLKVector2())
        for i in 0..<vertexIndices.count {
            triangleVertices[i] = vertices[vertexIndices[i]]
            triangleTexCoords[i] = textureCoordinates[vertexIndices[i]]
        }

        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(emulator.bufferSize().width), GLsizei(emulator.bufferSize().height), emulator.pixelFormat(), emulator.pixelType(), emulator.videoBuffer())

        if texture > 0 {
            effect.texture2d0.envMode = .Replace
            effect.texture2d0.target = .Target2D
            effect.texture2d0.name = texture
            effect.texture2d0.enabled = GLboolean(1)
            effect.useConstantColor = GLboolean(1)
        }

        effect.prepareToDraw()

        glDisable(GLenum(GL_DEPTH_TEST))
        glDisable(GLenum(GL_CULL_FACE))

        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(0), 0, triangleVertices)

        if texture > 0 {
            glEnableVertexAttribArray(GLuint(GLKVertexAttrib.TexCoord0.rawValue))
            glVertexAttribPointer(GLuint(GLKVertexAttrib.TexCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(0), 0, triangleTexCoords)
        }

        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)

        if texture > 0 {
            glDisableVertexAttribArray(GLuint(GLKVertexAttrib.TexCoord0.rawValue))
        }

        glDisableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! CheatsViewController
        vc.emulator = emulator
        vc.gameTitle = currentGame.title
    }


    // MARK: - UIView Methods

    private func transmitTouch(touch: UITouch) {
        let touchLocation: CGPoint = touch.locationInView(mainView)
        if touchLocation.y < (mainView.bounds.height / 2) || touchLocation.y > mainView.bounds.height { return }
        let adjustedTouchLocation: CGPoint = CGPoint(x: touchLocation.x, y: touchLocation.y - (mainView.bounds.height / 2))
        let mappedTouchLocation: CGPoint = CGPointApplyAffineTransform(
            adjustedTouchLocation,
            CGAffineTransformMakeScale(emulator.screenRect().width / mainView.bounds.width, (emulator.screenRect().height / 2) / (mainView.bounds.height / 2))
        )
        emulator.touchScreenAtPoint(mappedTouchLocation)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            transmitTouch(touch)
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            transmitTouch(touch)
        }
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        emulator.touchesEnded()
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        emulator.touchesEnded()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
