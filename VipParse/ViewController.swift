//
//  ViewController.swift
//  VipParse
//
//  Created by Tiny on 2018/11/23.
//  Copyright © 2018年 hxq. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    lazy var tableView: UITableView = { [unowned self] in
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    lazy var platformlist: Array<Any> = {
        let list = [Any]()
        return list
    }()
    
    lazy var parselist: Array<Any> = {
        let list = [Any]()
        return list
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "vip解析"
        
        navigationController?.navigationBar.isTranslucent = false
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view.safeAreaLayoutGuide.snp.edges)
        }
        
        //取出json数据
        if let path = Bundle.main.path(forResource: "parseList.json", ofType: nil){
            do{
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                //将Data转data
                if let dict = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String:Array<Any>]{
                    
                    platformlist = dict["platformlist"]!
                    parselist = dict["list"]!
                    tableView.reloadData()
                }
                
            }catch{
                print(error)
            }
        }
        
    }
}

extension ViewController: UITableViewDelegate,UITableViewDataSource{
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return platformlist.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil{
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        if let dict = platformlist[indexPath.row] as? [String:String]{
            cell?.textLabel?.text = dict["name"]
            cell?.detailTextLabel?.text = dict["url"]
        }
        return cell!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //拿到dictionary
        if let dict = platformlist[indexPath.row] as? [String:String]{
            let url = dict["url"]
            let title = dict["name"]
            let videoVc = VideoController()
            videoVc.title = title
            videoVc.parselist = parselist
            videoVc.url = url ?? ""
            navigationController?.pushViewController(videoVc, animated: true)
        }
    }
}

