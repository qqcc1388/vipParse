//
//  VideoController.swift
//  VipParse
//
//  Created by Tiny on 2018/11/23.
//  Copyright © 2018年 hxq. All rights reserved.
//

import UIKit
import WebKit
import FTPopOverMenu_Swift


class VideoController: UIViewController {

    /// 主流网站链接
    public var url: String = ""
    
    /// 解析器列表
    public var parselist = [Any]()
    
    /// 广告黑名单
    lazy var blacklist: [String] = {
        let path = Bundle.main.path(forResource: "blacklist.json", ofType: nil)
        do{
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            if let array = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String]{
                return array
            }
        }
        catch{
            print(error)
        }
        return [String]()
    }()
    
    lazy var webView: WKWebView = { [unowned self] in
        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.tintColor = RGB(22, 126, 251)
        progressView.trackTintColor = .clear
        return progressView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    func setup(){
        if url.count == 0 {
            return
        }
        
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(progressView)
        progressView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
            make.top.equalToSuperview()
        }
        view.insertSubview(progressView, aboveSubview: webView)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        guard let requestUrl = URL(string: url) else{
            return
        }
        let request = URLRequest(url: requestUrl)
        webView.load(request)
        
        /// vip按钮
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        btn.setImage(UIImage(named: "VIP"), for: .normal)
        btn.imageView?.contentMode = .scaleToFill
        btn.addTarget(self, action: #selector(changeAction(_:)), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 点击vip按钮列出所有解析器列表
    @objc func changeAction(_ item: UIButton){
        FTConfiguration.shared.menuWidth = 150
        var titles = [String]()
        for md in parselist {
            if let dict = md as? [String:String]{
                titles.append(dict["name"] ?? "")
            }
        }
        FTPopOverMenu.showForSender(sender: item, with: titles, menuImageArray: nil, done: {[unowned self] (selectIndex) in
            //根据选取index拿到对于的dict
            if let dict = self.parselist[selectIndex] as? [String:String]{
                let url = dict["url"] ?? ""
                self.changeUrl(url: url)
            }
        }) {
           print("获取失败")
        }
    }
    
    /// 点击解析器 将视频链接传递到解析器
    func changeUrl(url: String){
        webView.evaluateJavaScript("document.location.href") { [unowned self](obj, _) in
            guard let originUrl = (obj as? String)?.components(separatedBy: "url=").last else{
                return
            }
            if !originUrl.hasPrefix("http"){
                return
            }
            //根据当前选中vip url 组合成一个完整的url
            let requestUrl = url + originUrl
            self.webView.load(URLRequest(url: URL(string: requestUrl)!))
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? WKWebView {
            if obj == webView && keyPath == "estimatedProgress"{
                if let newprogress = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue {
                    if newprogress == 1 {
                        progressView.isHidden = true
                        progressView.setProgress(0, animated: false)
                    }else{
                        progressView.isHidden = false
                        progressView.setProgress(newprogress, animated: true)
                    }
                }
            }
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        print("wkWebView dealloc")
    }
    
//MARK:- Private 工具类
    fileprivate func fetchHost(url: String?) -> String?{
        if  url == nil {
            return nil
        }
        if let host = URL(string: url!)?.host{
            if host.contains("www."){
                return host.components(separatedBy: "www.").last ?? ""
            }
            return host
        }
        return nil
    }
    
    fileprivate func RGB(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat,_ a: CGFloat = 1.0) -> UIColor {
        return UIColor.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
}

extension VideoController: WKUIDelegate,WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.title = "加载中..."
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.title") { [unowned self](title, _)  in
            self.title = title as? String ?? ""
        }
        //获取HTML
        webView.evaluateJavaScript("document.body.outerHTML") { (source, _) in
            if source != nil{
//                print("-------------------------------------------\n\(source!)\n---------------------------------------------")
            }
        }
//        webView.evaluateJavaScript("document.getElementsByClassName('pxkplv')[0].style.display = 'none'"){
//            (source, error) in
//        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.evaluateJavaScript("document.title") { [unowned self](title, _)  in
            self.title = ( title as? String ) ?? "加载失败"
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if  navigationAction.targetFrame?.isMainFrame == nil{
                webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let requestUrl = navigationAction.request.url?.absoluteString{
            if let host = fetchHost(url: requestUrl){
                if blacklist.contains(host) {
                    print("url被拦截: \(requestUrl)")
                    decisionHandler(.cancel)
                    return
                }
            }
            print(requestUrl)
        }
        decisionHandler(.allow);
    }
}


