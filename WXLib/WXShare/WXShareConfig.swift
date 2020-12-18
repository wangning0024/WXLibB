//
//  WXShareConfig.swift
//  Pods
//
//  Created by 王铁山 on 2018/9/14.
//
//

import Foundation

import UIKit

/// 微信分享类型
public enum WXShareTargetType: Int32 {
    
    /// 全部
    case all = 4
    
    /// 聊天界面
    case wxSession = 0
    
    /// 朋友圈
    case wxTimeLine = 1
    
    /// 收藏
    case wxFavorite = 2
    
    /// 剪切板
    case clipboard = 3
}

/// 分享的消息类型
public enum WXShareMessageType {
    
    /// 文本分享
    case text
    
    /// url 分享
    case url
    
    /// 图片分享
    case image
}

/// 分享配置类
public class WXShareConfig: NSObject {
    
    /**
     * 是否显示预览信息
     */
    public var preview: Bool = true
    
    /*
     * 分享标题
     * 必须字段
     * 当 messageType 为 text 时，分享的文本内容取该字段
     */
    public var text: String?
    
    /**
     * 分享内容 必须字段
     */
    public var content: String?
    
    /*
     * 分享的URL。当 messageType 为 url 时，该字段必须有值
     */
    public var url: String?
    
    /*
     * 分享的图片或者 icon
     */
    public var image: WXShareImageConfig?
    
    /*
     * 分享目标
     * default: 默认全部，只要含有此类型，则按全部处理
     * wxSession: 微信会话
     * wxTimeLine: 微信朋友圈
     * wxFavorite: 微信收藏
     * clipboard: 复制到剪切板
     */
    public var targetType: [WXShareTargetType]
    
    /**
     * 分享的内容类型 text: 文本; image: 图片; url: 连接
     */
    public var messageType: WXShareMessageType
    
    /// 构造方法
    /// 构建文本分享
    /// - Parameters:
    ///   - text: 文本内容
    ///   - targetType: 分享目标
    public init(text: String, targetType: [WXShareTargetType]) {
        self.targetType = targetType
        self.messageType = .text
        super.init()
        self.text = text
    }
    
    /// 构造方法
    /// 构建图片分享
    /// - Parameters:
    ///   - title: 标题
    ///   - description: 描述
    ///   - image: 图片
    ///   - targetType: 分享目标
    ///   - needCompress: 缩略图是否需要压缩
    public init(title: String, description: String, image: WXShareImageConfig, targetType: [WXShareTargetType]) {
        self.targetType = targetType
        self.messageType = .image
        super.init()
        self.image = image
        self.text = title
        self.content = description
    }
    
    /// 构造方法
    /// 构建URL分享
    /// - Parameters:
    ///   - title: 标题
    ///   - description: 描述
    ///   - url: 分享的URL路径
    ///   - icon: 分享的图片，此图片不会压缩
    ///   - targetType: 分享目标
    public init(title: String, description: String, url: String, icon: WXShareImageConfig?, targetType: [WXShareTargetType]) {
        self.targetType = targetType
        self.messageType = .url
        super.init()
        self.url = url
        self.text = title
        self.content = description
        self.image = icon
    }
}

/// 分享图片配置类
open class WXShareImageConfig: NSObject {
    
    /// 文件全路径
    open var filePath: String?
    
    /// 图片路径
    open var url: String?
    
    /// 图片资源
    open var image: UIImage?
    
    /// 缩略图
    open var thumbImage: UIImage?
    
    private var downloading: Bool = false
    
    public init(image: UIImage) {
        super.init()
        self.image = image
    }
    
    public init(filePath: String) {
        super.init()
        self.filePath = filePath
    }
    
    public init(url: String) {
        super.init()
        self.url = url
    }
    
    /// 是否包含图片资源
    public func isValid() -> Bool {
        return filePath != nil || url != nil || image != nil
    }
    
    /// 下载图片
    open func downloadImage(callBack: @escaping (UIImage?)->Void) {
        if let img = self.image {
            self.thumbImage = self.compressAspectFitThumbileImage(img, size: CGSize.init(width: 90, height: 90))
            callBack(self.thumbImage)
        } else if let path = self.filePath {
            if let img = UIImage.init(contentsOfFile: path) {
                self.image = img
                self.thumbImage = self.compressAspectFitThumbileImage(img, size: CGSize.init(width: 90, height: 90))
                callBack(self.thumbImage)
            }
        } else if let u = self.url, let uri = URL.init(string: u) {
            let cachePath = self.dealImageURLString(url: u)
            if let cacheImage = self.getCacheImg(path: cachePath) {
                self.image = cacheImage
                self.thumbImage = self.compressAspectFitThumbileImage(cacheImage, size: CGSize.init(width: 90, height: 90))
                callBack(self.thumbImage)
                return
            }
            if self.downloading {
                return
            }
            self.downloading = true
            DispatchQueue.global().async {
                var request = URLRequest.init(url: uri)
                request.setValue("https://refer.shenmajr.com", forHTTPHeaderField: "Referer")
                let task = URLSession.shared.downloadTask(with: request, completionHandler: { [weak self] (local, response, error) in
                    guard let localUri = local else {
                        self?.downloading = false
                        return
                    }
                    do {
                        let imageData = try Data.init(contentsOf: localUri)
                        if let img = UIImage.init(data: imageData) {
                            self?.cacheImage(data: imageData, path: cachePath)
                            self?.image = img
                            self?.thumbImage = self?.compressAspectFitThumbileImage(img, size: CGSize.init(width: 90, height: 90))
                            DispatchQueue.main.async {
                                callBack(img)
                            }
                        }
                        self?.downloading = false
                    } catch {
                        self?.downloading = false
                    }
                })
                task.resume()
            }
        }
    }
    /// content model aspect fit compress
    func compressAspectFitThumbileImage(_ image: UIImage, size: CGSize) -> UIImage {
        
        
        let imgSize = image.size
        
        var newSize: CGSize = CGSize.zero
        
        if imgSize.width / imgSize.height > size.width / size.height {
            newSize.width = size.width
            newSize.height = newSize.width * (imgSize.height / imgSize.width)
        } else {
            newSize.height = size.height
            newSize.width = newSize.height * (imgSize.width / imgSize.height)
        }
        
        return self.compressImage(image, size: newSize)
    }
    
    /// 压缩图片
    func compressImage(_ image: UIImage, size: CGSize) -> UIImage {
        
        if #available(iOS 10.0, *) {
            
            let bounds = CGRect.init(origin: CGPoint(), size: size)
            
            let render = UIGraphicsImageRenderer.init(size: bounds.size)
            
            return render.image(actions: { (context) in
                
                image.draw(in: bounds)
            })
            
        } else {
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            image.draw(in: CGRect.init(origin: CGPoint.zero, size: size))
            
            let result = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            return result ?? image
        }
    }
    
    
    /// 处理图片 URL，删除特殊字符
    private func dealImageURLString(url: String) -> String {
        
        let pridate = NSPredicate.init(format: "SELF MATCHES %@", "^[A-Za-z0-9]+$")
        
        let result = url.characters.filter { (Character) -> Bool in
            return pridate.evaluate(with: String.init(Character))
        }
        
        return String.init(result)
    }
    
    /// 缓存图片
    private func cacheImage(data: Data, path: String) {
        let _ = try? data.write(to: URL.init(fileURLWithPath: path))
    }
    
    /// 获取缓存图片
    private func getCacheImg(path: String) -> UIImage? {
        if !FileManager.default.fileExists(atPath: path) {
            return nil
        }
        
        return UIImage.init(contentsOfFile: path)
    }
    
    /// 获取缓存全路径
    private func getFullCachePath(fileName: String) -> String {
        
        let cachePath = self.cachePath()
        
        if !FileManager.default.fileExists(atPath: cachePath) {
            let _ = try? FileManager.default.createDirectory(at: URL.init(fileURLWithPath: cachePath), withIntermediateDirectories: true, attributes: nil)
        }
        
        return cachePath.appending("/\(fileName)")
    }
    
    private func cachePath() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        guard let first = paths.first else {
            return NSHomeDirectory() + "/Library/Caches/KKAutoScrollViewImgCache"
        }
        return first.appending("/KKAutoScrollViewImgCache")
    }
}
