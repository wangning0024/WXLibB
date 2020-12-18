//
//  WXShare.swift
//  WechatShare
//
//  Created by 王铁山 on 2018/9/11.
//  Copyright © 2018年 wangtieshan. All rights reserved.
//

import Foundation

import UIKit

/// 微信分享控制器
open class WXShare: UIViewController {
    
    fileprivate var scrollView: UIScrollView!
    
    fileprivate var cancelBtn: UIButton!
    
    fileprivate var itemView: WXShareItem?
    
    fileprivate var contentView: UIView = UIView()
    
    fileprivate var dashLineView: DashView?
    
    public var config: WXShareConfig!
    
    public class func registApp(appid: String) {
        WXApi.registerApp(appid)
    }
    
    public init(config: WXShareConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        
        self.view.addSubview(self.contentView)
        
        if self.config.preview {
            let itemView = WXShareItem.itemView()
            self.itemView = itemView
            self.contentView.addSubview(itemView)
            
            self.dashLineView = DashView()
            self.contentView.addSubview(self.dashLineView!)
        }
        
        self.scrollView = getScrollView()
        self.contentView.addSubview(self.scrollView)
        
        self.cancelBtn = self.getCancelButton()
        self.contentView.addSubview(self.cancelBtn)
        
        self.layoutSubViews()
        
        self.showData()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.beginAnimation()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.layoutItemView()
    }
    
    /// 分享到朋友圈
    open func shareToWechatTimeLine() {
        if let req = getWechatReq(sence: WXShareTargetType.wxTimeLine) {
            WXApi.send(req)
            self.cancenAction()
        }
    }
    
    /// 分享到微信对话
    open func shareToWechatSession() {
        if let req = getWechatReq(sence: WXShareTargetType.wxSession) {
            WXApi.send(req)
            self.cancenAction()
        }
    }
    
    /// 分享到微信收藏
    open func shareToWechatFavorite() {
        if let req = getWechatReq(sence: WXShareTargetType.wxFavorite) {
            WXApi.send(req)
            self.cancenAction()
        }
    }
    
    /// 分享到剪切板
    open func shareToWechatClipBoard() {
        if self.config.messageType == .text {
            if let text = self.config.url {
                UIPasteboard.general.string = text
            }
        }
        if self.config.messageType == .url {
            if let text = self.config.url {
                UIPasteboard.general.string = text
            }
        }
        if self.config.messageType == .image {
            if let img = self.config.image?.image {
                UIPasteboard.general.image = img
            } else {
                let alertVC = UIAlertController.init(title: "请稍等", message: "正在加载分享的图片", preferredStyle: UIAlertControllerStyle.alert)
                alertVC.addAction(UIAlertAction.init(title: "知道了", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
                return;
            }
        }
        self.cancenAction()
    }
    
    /// 获取跳转微信请求对象
    open func getWechatReq(sence: WXShareTargetType) -> SendMessageToWXReq? {
        
        if self.config.messageType == .text {
            let req: SendMessageToWXReq = SendMessageToWXReq()
            req.bText = true
            req.text = self.config.text
            req.scene = 0
            return req
        }
        
        // 构建消息对象
        let message = WXMediaMessage.init()
        message.title = self.config.text
        message.description = self.config.content
        if let img = self.config.image?.thumbImage {
            message.setThumbImage(img)
        }
        
        // 构建消息中的媒体对象（图片）
        if self.config.messageType == .image {
            if let img = self.config.image?.image {
                let obj: WXImageObject = WXImageObject.init()
                obj.imageData = UIImageJPEGRepresentation(img, 1)
                message.mediaObject = obj
            } else {
                let alertVC = UIAlertController.init(title: "请稍等", message: "正在加载分享的图片", preferredStyle: UIAlertControllerStyle.alert)
                alertVC.addAction(UIAlertAction.init(title: "知道了", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
                return nil
            }
        }
        
        // 构建消息中的媒体对象（url）
        if self.config.messageType == .url {
            let obj: WXWebpageObject = WXWebpageObject()
            obj.webpageUrl = self.config.url
            message.mediaObject = obj
        }
        
        // 构建发送对象
        let req: SendMessageToWXReq = SendMessageToWXReq()
        req.bText = self.config.messageType == .text
        req.text = self.config.text
        req.message = message
        req.scene = sence.rawValue
        return req
    }
    
    /// 填充数据
    open func showData() {
        if let imgObj = self.config.image, imgObj.isValid() {
            imgObj.downloadImage(callBack: { [weak self] (img) in
                self?.itemView?.imageView.image = img
            })
        } else {
            self.itemView?.hiddenIcon()
        }
        self.itemView?.contentLabel.text = self.config.content
    }
    
    /// 开始动画
    open func beginAnimation() {
        let height: CGFloat = self.view.bounds.size.height
        self.contentView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: height), size: contentView.frame.size)
        UIView.animate(withDuration: 0.2) {
            self.contentView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: height - self.contentView.frame.size.height),
                                                 size: self.contentView.frame.size)
        }
    }
    
    /// 取消事件
    func cancenAction() {
        let height: CGFloat = self.view.bounds.size.height
        UIView.animate(withDuration: 0.2) {
            self.contentView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: height),
                                                 size: self.contentView.frame.size)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    /// 分享方式，滚动视图
    ///
    /// - Returns: scrollView
    open func getScrollView() -> UIScrollView {
        
        let sc: UIScrollView = UIScrollView.init()
        sc.bounds = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 80)
        sc.backgroundColor = UIColor.white
        sc.alwaysBounceHorizontal = true
        
        let label = UILabel.init(frame: CGRect.init(x: 15, y: (80 - 18) / 2.0, width: 80 - 15, height: 18))
        label.textColor = UIColor.init(red: 74/255.0, green: 74/255.0, blue: 74/255.0, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "分享到："
        sc.addSubview(label)
        
        var minxX: CGFloat = label.frame.maxX
        
        var itemViews: [UIButton] = []
        
        if self.config.targetType.contains(.all) {
            self.config.targetType = [.wxSession, .wxTimeLine, .wxFavorite, .clipboard]
        }
        
        if self.config.targetType.contains(.wxSession) {
            itemViews.append(getWechatSessionView())
        }
        if self.config.targetType.contains(.wxTimeLine) {
            itemViews.append(getWechatTimeLineView())
        }
        if self.config.targetType.contains(.wxFavorite) {
            itemViews.append(getWechaFavoriteView())
        }
        if self.config.targetType.contains(.clipboard) && self.config.messageType != .image {
            itemViews.append(getClipBoardView())
        }

        itemViews.enumerated().forEach { (index, btn) in
            btn.frame = CGRect.init(origin: CGPoint.init(x: minxX , y: 0), size: btn.bounds.size)
            minxX = btn.frame.maxX
            sc.addSubview(btn)
        }
        
        sc.contentSize = CGSize.init(width: minxX, height: 80)
        
        return sc
    }
    
    
    /// layout
    open func layoutSubViews() {
        
        let width: CGFloat = self.view.bounds.size.width
        let height: CGFloat = self.view.bounds.size.height
        
        var maxY: CGFloat = 0
        
        if let itemView = self.itemView {
            self.layoutItemView()
            maxY = itemView.frame.maxY
            self.dashLineView?.frame = CGRect.init(x: 0, y: maxY, width: width, height: 1)
            maxY = maxY + 1
        }
        
        self.scrollView.frame = CGRect.init(x: 0,
                                            y: maxY,
                                            width: width,
                                            height: 80)
        maxY = self.scrollView.frame.maxY
        
        self.cancelBtn.frame = CGRect.init(x: 0,
                                           y: maxY,
                                           width: width,
                                           height: 50)
        maxY = self.cancelBtn.frame.maxY
        
        self.contentView.frame = CGRect.init(x: 0,
                                             y: height,
                                             width: width,
                                             height: maxY)
    }
    
    open func layoutItemView() {
        let width: CGFloat = self.view.bounds.size.width
        self.itemView?.frame = CGRect.init(x: 0,
                                           y: 0,
                                           width: width,
                                           height: 116)
        self.itemView?.setNeedsLayout()
    }
    
    /// 获取微信条目
    ///
    /// - Returns: 按钮
    open func getWechatSessionView() -> UIButton {
        let btn = getItemView(title: "微信", image: getImage(name: "WXShareSession"))
        btn.addTarget(self, action: #selector(shareToWechatSession), for: UIControlEvents.touchUpInside)
        return btn
    }
    
    /// 获取朋友圈条目
    ///
    /// - Returns: 按钮
    open func getWechatTimeLineView() -> UIButton {
        let btn = getItemView(title: "朋友圈", image: getImage(name: "WXShareTimeLine"))
        btn.addTarget(self, action: #selector(shareToWechatTimeLine), for: UIControlEvents.touchUpInside)
        return btn
    }
    
    /// 获取朋友圈收藏
    ///
    /// - Returns: 按钮
    open func getWechaFavoriteView() -> UIButton {
        let btn = getItemView(title: "微信收藏", image: getImage(name: "WXShareFavorite"))
        btn.addTarget(self, action: #selector(shareToWechatFavorite), for: UIControlEvents.touchUpInside)
        return btn
    }
    
    /// 获取剪切板
    ///
    /// - Returns: 按钮
    open func getClipBoardView() -> UIButton {
        let btn = getItemView(title: "剪切板", image: getImage(name: "WXShareCopyLink"))
        btn.addTarget(self, action: #selector(shareToWechatClipBoard), for: UIControlEvents.touchUpInside)
        return btn
    }
    
    /// 创建条目(微信、朋友圈)
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - image: 图片
    /// - Returns: 条目
    open func getItemView(title: String, image: UIImage?) -> UIButton {
        let btn: UIButton = UIButton.init(type: UIButtonType.custom)
        btn.bounds = CGRect.init(x: 0, y: 0, width: 80, height: 80)
        
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 50, width: 80, height: 18))
        label.textColor = UIColor.init(red: 74/255.0, green: 74/255.0, blue: 74/255.0, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 11)
        label.textAlignment = .center
        label.text = title
        btn.addSubview(label)
        
        let imageView = UIImageView.init(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect.init(x: (80 - 35) / 2.0, y: 15, width: 35, height: 35)
        btn.addSubview(imageView)

        return btn
    }
    
    /// 创建取消按钮
    ///
    /// - Returns: 取消按钮
    open func getCancelButton() -> UIButton {
        let btn: UIButton = UIButton.init(type: UIButtonType.custom)
        btn.setTitle("取消", for: UIControlState.normal)
        btn.backgroundColor = UIColor.init(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1)
        btn.setTitleColor(UIColor.init(red: 74/255.0, green: 74/255.0, blue: 74/255.0, alpha: 1), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(cancenAction), for: UIControlEvents.touchUpInside)
        return btn
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
//        self.cancenAction()
    }
    
    /// 获取 bundle 图片
    ///
    /// - Parameter name: 名称
    /// - Returns: 图片
    private func getImage(name: String) -> UIImage {
        guard let path = Bundle.init(for: WXShare.self).path(forResource: "WXShare.bundle/".appending(name).appending("@").appending(String(describing: Int(UIScreen.main.scale))).appending("x"), ofType: "png") else {
            return UIImage.init(contentsOfFile: Bundle.init(for:  WXShare.self).path(forResource: "WXShare.bundle/".appending(name).appending("@3x"), ofType: "png")!)!
        }
        return UIImage.init(contentsOfFile: path) ?? UIImage.init(contentsOfFile: Bundle.init(for: WXShare.self).path(forResource: "WXShare.bundle/".appending(name).appending("@3x"), ofType: "png")!)!
    }
}

class DashView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineWidth(rect.size.height)
        context.setStrokeColor(UIColor.init(red: 74/255.0, green: 74/255.0, blue: 74/255.0, alpha: 1).cgColor)
        context.setLineDash(phase: 2, lengths: [4])
        context.move(to: CGPoint.init(x: 20, y: 0))
        context.addLine(to: CGPoint.init(x: rect.size.width - 20, y: 0))
        context.strokePath()
    }
    
}


