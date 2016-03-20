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
import BlocksKit

class EmulatorViewController: UIViewController, GLKViewDelegate {

    // MARK: - Attributes (View)

    private let mainView: GLKView = GLKView.newAutoLayoutView()
    private let promoLabel: UILabel = UILabel.newAutoLayoutView()
    private let startButton: UIButton = UIButton.newAutoLayoutView()
    private let menuButton: UIButton = UIButton.newAutoLayoutView()
    private let selectButton: UIButton = UIButton.newAutoLayoutView()
    private let aButton: UIButton = UIButton.newAutoLayoutView()
    private let bButton: UIButton = UIButton.newAutoLayoutView()
    private let xButton: UIButton = UIButton.newAutoLayoutView()
    private let yButton: UIButton = UIButton.newAutoLayoutView()
    private let lButton: UIButton = UIButton.newAutoLayoutView()
    private let rButton: UIButton = UIButton.newAutoLayoutView()
    private let leftButton: UIButton = UIButton.newAutoLayoutView()
    private let downButton: UIButton = UIButton.newAutoLayoutView()
    private let upButton: UIButton = UIButton.newAutoLayoutView()
    private let rightButton: UIButton = UIButton.newAutoLayoutView()


    // MARK: - Attributes (Instance)

    var emulator: EmulatorCore = EmulatorCore()
    var audioCore: OEGameAudio!
    private let effect: GLKBaseEffect = GLKBaseEffect()
    private var texture: GLuint = 0

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
        setupNotifications()
        setupGL()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Private Methods

    private func setupView() {
        view.backgroundColor = .blackColor()

        // Screens
        mainView.tag = 44
        mainView.delegate = self
        mainView.enableSetNeedsDisplay = false
        view.addSubview(mainView)
        mainView.autoPinEdgeToSuperviewEdge(.Left)
        mainView.autoPinEdgeToSuperviewEdge(.Top)
        mainView.autoPinEdgeToSuperviewEdge(.Right)
        let inset = view.bounds.height - ((view.bounds.width * emulator.aspectSize().height) / emulator.aspectSize().width)
        mainView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: inset)

        promoLabel.text = "#NitrogenEmu"
        promoLabel.textColor = UIColor(white: 1, alpha: 0.5)
        view.addSubview(promoLabel)
        promoLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 8)
        promoLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 8)

        // Buttons
        startButton.setBackgroundImage(UIImage(named: "start-button"), forState: .Normal)
        startButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Start)
        }, forControlEvents: .TouchDown)
        startButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Start)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(startButton)
        startButton.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 4)
        startButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 12)

        aButton.setBackgroundImage(UIImage(named: "a-button"), forState: .Normal)
        aButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.A)
        }, forControlEvents: .TouchDown)
        aButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.A)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(aButton)
        aButton.autoSetDimensionsToSize(CGSize(width: 48, height: 48))
        aButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 6)
        aButton.autoPinEdge(.Bottom, toEdge: .Top, ofView: startButton, withOffset: -8)

        bButton.setBackgroundImage(UIImage(named: "b-button"), forState: .Normal)
        bButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.B)
        }, forControlEvents: .TouchDown)
        bButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.B)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(bButton)
        bButton.autoSetDimensionsToSize(CGSize(width: 48, height: 48))
        bButton.autoPinEdge(.Right, toEdge: .Left, ofView: aButton, withOffset: -7)
        bButton.autoAlignAxis(.Horizontal, toSameAxisOfView: aButton)

        xButton.setBackgroundImage(UIImage(named: "x-button"), forState: .Normal)
        xButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.X)
        }, forControlEvents: .TouchDown)
        xButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.X)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(xButton)
        xButton.autoSetDimensionsToSize(CGSize(width: 48, height: 48))
        xButton.autoPinEdge(.Right, toEdge: .Left, ofView: bButton, withOffset: -7)
        xButton.autoAlignAxis(.Horizontal, toSameAxisOfView: aButton)

        yButton.setBackgroundImage(UIImage(named: "y-button"), forState: .Normal)
        yButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Y)
        }, forControlEvents: .TouchDown)
        yButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Y)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(yButton)
        yButton.autoSetDimensionsToSize(CGSize(width: 48, height: 48))
        yButton.autoAlignAxis(.Vertical, toSameAxisOfView: bButton)
        yButton.autoPinEdge(.Bottom, toEdge: .Top, ofView: bButton, withOffset: -7)

        lButton.setBackgroundImage(UIImage(named: "left-button"), forState: .Normal)
        lButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.L)
            }, forControlEvents: .TouchDown)
        lButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.L)
            }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(lButton)
        lButton.autoSetDimensionsToSize(CGSize(width: 37, height: 34))
        lButton.autoAlignAxis(.Horizontal, toSameAxisOfView: yButton)
        lButton.autoPinEdge(.Right, toEdge: .Left, ofView: yButton, withOffset: -2)

        rButton.setBackgroundImage(UIImage(named: "right-button"), forState: .Normal)
        rButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.R)
            }, forControlEvents: .TouchDown)
        rButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.R)
            }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(rButton)
        rButton.autoSetDimensionsToSize(CGSize(width: 37, height: 34))
        rButton.autoAlignAxis(.Horizontal, toSameAxisOfView: yButton)
        rButton.autoPinEdge(.Left, toEdge: .Right, ofView: yButton, withOffset: 2)

        menuButton.setBackgroundImage(UIImage(named: "menu-button"), forState: .Normal)
        menuButton.bk_addEventHandler({ [weak self] _ in
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let closeAction = UIAlertAction(title: "Close ROM", style: .Destructive) { [weak self] action in
                self?.emulator.stopEmulation()
                self?.dismissViewControllerAnimated(true, completion: nil)
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

            sheet.addAction(closeAction)
            sheet.addAction(cancelAction)
            self?.presentViewController(sheet, animated: true, completion: nil)
        }, forControlEvents: .TouchDown)
        view.addSubview(menuButton)
        menuButton.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 4)
        menuButton.autoAlignAxisToSuperviewAxis(.Vertical)

        selectButton.setBackgroundImage(UIImage(named: "select-button"), forState: .Normal)
        selectButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Select)
        }, forControlEvents: .TouchDown)
        selectButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Select)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(selectButton)
        selectButton.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 4)
        selectButton.autoPinEdgeToSuperviewEdge(.Left, withInset: 12)

        leftButton.setBackgroundImage(UIImage(named: "side-button"), forState: .Normal)
        leftButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Left)
        }, forControlEvents: [.TouchDown])
        leftButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Left)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(leftButton)
        leftButton.autoSetDimensionsToSize(CGSize(width: 48, height: 44))
        leftButton.autoPinEdgeToSuperviewEdge(.Left, withInset: 12)
        leftButton.autoPinEdge(.Bottom, toEdge: .Top, ofView: selectButton, withOffset: -8)

        downButton.setBackgroundImage(UIImage(named: "down-button"), forState: .Normal)
        downButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Down)
        }, forControlEvents: [.TouchDown])
        downButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Down)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(downButton)
        downButton.autoSetDimensionsToSize(CGSize(width: 48, height: 44))
        downButton.autoAlignAxis(.Horizontal, toSameAxisOfView: leftButton)
        downButton.autoPinEdge(.Left, toEdge: .Right, ofView: leftButton, withOffset: 7)

        rightButton.setBackgroundImage(UIImage(named: "side-button"), forState: .Normal)
        rightButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Right)
        }, forControlEvents: [.TouchDown])
        rightButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Right)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(rightButton)
        rightButton.autoSetDimensionsToSize(CGSize(width: 48, height: 44))
        rightButton.autoPinEdge(.Left, toEdge: .Right, ofView: downButton, withOffset: 7)
        rightButton.autoAlignAxis(.Horizontal, toSameAxisOfView: leftButton)

        upButton.setBackgroundImage(UIImage(named: "up-button"), forState: .Normal)
        upButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.pressedButton(.Up)
        }, forControlEvents: [.TouchDown])
        upButton.bk_addEventHandler({ [weak self] _ in
            self?.emulator.releasedButton(.Up)
        }, forControlEvents: [.TouchUpInside, .TouchDragExit, .TouchUpOutside])
        view.addSubview(upButton)
        upButton.autoSetDimensionsToSize(CGSize(width: 48, height: 44))
        upButton.autoPinEdge(.Bottom, toEdge: .Top, ofView: downButton, withOffset: -10)
        upButton.autoAlignAxis(.Vertical, toSameAxisOfView: downButton)
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
        let glContext = EAGLContext(API: .OpenGLES2)
        EAGLContext.setCurrentContext(glContext)
        mainView.context = glContext
        setupTexture()
        setupEmulator()
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

    private func setupEmulator() {
        let documentsDirectoryURL: NSURL! =  try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let ndsFile: NSURL! = documentsDirectoryURL.URLByAppendingPathComponent("pokemon.nds")

        audioCore = OEGameAudio(core: emulator)
        audioCore.volume = 1.0
        audioCore.outputDeviceID = 0
        audioCore.startAudio()

        emulator.loadROM(ndsFile.path)
        emulator.startEmulation()
        emulator.updateFrameBlock = { [weak self] in
            self?.mainView.display()
        }
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

        let vertexIndices = [
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

        if view.tag == 44 {
            glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(emulator.bufferSize().width), GLsizei(emulator.bufferSize().height), emulator.pixelFormat(), emulator.pixelType(), emulator.videoBuffer())
        } else {
            glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(emulator.bufferSize().width), GLsizei(emulator.bufferSize().height), emulator.pixelFormat(), emulator.pixelType(), emulator.videoBuffer() + 256*192*4)
        }

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


    // MARK: - UIView Methods

    private func transmitTouch(touch: UITouch) {
        let touchLocation = touch.locationInView(mainView)
        if touchLocation.y < (mainView.bounds.height / 2) || touchLocation.y > mainView.bounds.height { return }
        let adjustedTouchLocation = CGPoint(x: touchLocation.x, y: touchLocation.y - (mainView.bounds.height / 2))
        let mappedTouchLocation = CGPointApplyAffineTransform(
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
