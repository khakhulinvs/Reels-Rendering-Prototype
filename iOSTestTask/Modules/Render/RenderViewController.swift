//
//  RenderViewController.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import UIKit
import MetalKit

final class RenderViewController: UIViewController, RenderViewProtocol {
    var presenter: RenderPresenter!
    
    private(set) var mtkView = MTKView()
    private var renderButton = UIButton()
    private var activityView = UIActivityIndicatorView()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[RenderViewController] Metal is not supported")
            return
        }

        mtkView.device = device
        mtkView.framebufferOnly = false
        mtkView.translatesAutoresizingMaskIntoConstraints = false

        renderButton.setTitle("RENDER", for: .normal)
        renderButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        renderButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        renderButton.layer.cornerRadius = 8
        renderButton.layer.borderWidth = 2
        renderButton.layer.borderColor = UIColor.white.cgColor
        renderButton.translatesAutoresizingMaskIntoConstraints = false
        renderButton.addTarget(self, action: #selector(renderButtonTapped), for: .touchUpInside)
        
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        activityView.style = .large
        activityView.startAnimating()
        activityView.isHidden = true
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()

        view.addSubview(mtkView)

        let renderSize = presenter.renderSize
        let renderAspect = renderSize.width / renderSize.height
        
        view.addConstraints([
            NSLayoutConstraint(item: mtkView, attribute: .width, relatedBy: .equal,
                               toItem: mtkView, attribute: .height, multiplier: renderAspect, constant: 0),
            NSLayoutConstraint(item: mtkView, attribute: .centerX, relatedBy: .equal,
                               toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: mtkView, attribute: .centerY, relatedBy: .equal,
                               toItem: view, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: mtkView, attribute: .leading, relatedBy: .equal,
                               toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        ])
        
        view.addSubview(renderButton)
        view.addConstraints([
            NSLayoutConstraint(item: renderButton, attribute: .centerX, relatedBy: .equal,
                               toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderButton, attribute: .bottom, relatedBy: .equal,
                               toItem: view, attribute: .bottom, multiplier: 1, constant: -50)
        ])
        
        view.addSubview(activityView)
        view.addConstraints([
            NSLayoutConstraint(item: activityView, attribute: .leading, relatedBy: .equal,
                               toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: activityView, attribute: .trailing, relatedBy: .equal,
                               toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: activityView, attribute: .top, relatedBy: .equal,
                               toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: activityView, attribute: .bottom, relatedBy: .equal,
                               toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // To fit Metal drawable resoultion to image
        let scale = presenter.renderSize.width / mtkView.frame.width
        mtkView.contentScaleFactor = scale
    }
    
    @objc func renderButtonTapped() {
        presenter.renderButtonTapped()
    }
        
    func shareVideo(url: URL) {
        DispatchQueue.main.async { [weak self] in
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // For iPad support
            activityVC.popoverPresentationController?.sourceView = self?.view
            self?.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Activity
    
    func showActivity() {
        DispatchQueue.main.async { [weak self] in
            self?.activityView.isHidden = false
        }
    }
    
    func hideActivity() {
        DispatchQueue.main.async { [weak self] in
            self?.activityView.isHidden = true
        }
    }
    
    // MARK: - Activity
    
    func setMtkViewFixedTime() {
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
    }
    
    func setMtkViewRealTime() {
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
    }
    
    func setMtkViewNeedDisplay() {
        mtkView.setNeedsDisplay()
    }
}
