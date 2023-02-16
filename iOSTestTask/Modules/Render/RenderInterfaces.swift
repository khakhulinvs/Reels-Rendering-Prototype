//
//  RenderInterfaces.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import MetalKit

protocol RenderViewProtocol: AnyObject {
    var mtkView: MTKView { get }
    
    func shareVideo(url: URL)
    
    func showActivity()
    func hideActivity()
    
    func setMtkViewFixedTime()
    func setMtkViewRealTime()
    func setMtkViewNeedDisplay()
}

protocol RenderPresenterProtocol: AnyObject {
    var renderSize: CGSize { get }
    func renderButtonTapped()
}
