 /*
  * Copyright (c) 2017  STMicroelectronics – All rights reserved
  * The STMicroelectronics corporate logo is a trademark of STMicroelectronics
  *
  * Redistribution and use in source and binary forms, with or without modification,
  * are permitted provided that the following conditions are met:
  *
  * - Redistributions of source code must retain the above copyright notice, this list of conditions
  *   and the following disclaimer.
  *
  * - Redistributions in binary form must reproduce the above copyright notice, this list of
  *   conditions and the following disclaimer in the documentation and/or other materials provided
  *   with the distribution.
  *
  * - Neither the name nor trademarks of STMicroelectronics International N.V. nor any other
  *   STMicroelectronics company nor the names of its contributors may be used to endorse or
  *   promote products derived from this software without specific prior written permission.
  *
  * - All of the icons, pictures, logos and other images that are provided with the source code
  *   in a directory whose title begins with st_images may only be used for internal purposes and
  *   shall not be redistributed to any third party or modified in any way.
  *
  * - Any redistributions in binary form shall not include the capability to display any of the
  *   icons, pictures, logos and other images that are provided with the source code in a directory
  *   whose title begins with st_images.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
  * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
  * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
  * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
  * OF SUCH DAMAGE.
  */
//

import Foundation
import BlueSTSDK

 public protocol BlueSTSDKNodeListViewControllerDelegate{
 
 /**
  *  Filter to use for decide if we have to display the node.
  *
  *  @param node node to filter.
  *
  *  @return true for display the node, false otherwise.
  */
  func display(node:BlueSTSDKNode)->Bool
 
 /**
  *  Call before connecting the node
  *
  *  @param node node seleceted by the user.
  */
  func prepareToConnect(node : BlueSTSDKNode)
 
 /**
  *  Get the view controller to display when the node is selected.
  *
  *  @param node node seleceted by the user.
  *
  *  @return view controller to display after the seleciton.
  */
  func demoViewController( with node: BlueSTSDKNode, menuManager:BlueSTSDKViewControllerMenuDelegate)->UIViewController;
    
  var advertiseFilters:[BlueSTSDKAdvertiseFilter] {get}

 }
 
 public extension BlueSTSDKNodeListViewControllerDelegate{
    public var advertiseFilters:[BlueSTSDKAdvertiseFilter] {
        get {
            return BlueSTSDKManager.DEFAULT_ADVERTISE_FILTER;
        }
    }
 }
 
 public class BlueSTSDKNodeListViewCell : UITableViewCell{
    
    @IBOutlet weak var boardName: UILabel!
    @IBOutlet weak var boardDetails: UILabel!
    @IBOutlet weak var boardIsSleepingImage: UIImageView!
    @IBOutlet weak var boardHasExtensionImage: UIImageView!
    @IBOutlet weak var boardImage: UIImageView!
    
 }
 
 public class BlueSTSDKNodeListViewController : UITableViewController{
    private static let SEGUE_DEMO_VIEW = "showDemoView"
    //stop the discovery after 10s
    private static let DISCOVERY_TIMEOUT_MS = 10*1000
    
    private static let CONNECTIONG:String = {
        let bundle = Bundle(for: BlueSTSDKNodeListViewController.self);
        return NSLocalizedString("Connecting", tableName: nil,
                                 bundle: bundle,
                                 value: "Connecting",
                                 comment: "Connecting");
    }();

    /**
     *  class used for start/stop the discovery process
     */
    private var mManager:BlueSTSDKManager!
    /**
     *  list of discovered nodes
     */
    fileprivate var mNodes:[BlueSTSDKNode] = []

    /**
     *  view to show while the iphone is connecting to the node
     */
    private var networkCheckConnHud:MBProgressHUD? = nil

    private var mConnectedNode:BlueSTSDKNode?=nil
  
    public var delegate:BlueSTSDKNodeListViewControllerDelegate!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        mManager = BlueSTSDKManager.sharedInstance
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mNodes.removeAll()
        mManager.nodes.forEach{ node in
            if(node.isConnected()){
                node.disconnect()
            }//if
        }//for each
        mManager.resetDiscovery()
        self.tableView.reloadData()
    }
  
    
    
    /**
     *  start the discovery process, when the view is shown,
     *  we close the connection with all the previous discovered nodes
     */
    public override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mManager.addDelegate(self)
        //if some node are already discovered show it, and we disconnect
        mManager.discoveryStart(BlueSTSDKNodeListViewController.DISCOVERY_TIMEOUT_MS,
                                advertiseFilters: delegate.advertiseFilters)
        #if targetEnvironment(simulator)
            mManager.addVirtualNode()
        #endif
        
        setNavigationDiscoveryButton();
    }
    

    /**
     *  when the view change we stop the discovering process
     *
     *  @param animated <#animated description#>
     */
    public override func viewWillDisappear(_ animated: Bool) {
        mManager.removeDelegate(self)
        mManager.discoveryStop()
        super.viewWillDisappear(animated)
    }
    
    /**
     *  function called each time the user click in the uibarbutton,
     * it change the status of the discovery
     */
    @objc public func manageDiscoveryButton(){
        if(mManager.isDiscovering){
            mManager.discoveryStop()
        }else{
            mManager.resetDiscovery()
            mNodes.removeAll()
            mNodes.append(contentsOf: mManager.nodes)
            tableView.reloadData()
            mManager.discoveryStart(BlueSTSDKNodeListViewController.DISCOVERY_TIMEOUT_MS,
                                    advertiseFilters: delegate.advertiseFilters)
        }
    }
    
    /**
     *  add the view a bar button for enable/disable the discovery the button will
     * have a search icon if the manager is NOT searching for new nodes, or an X othewise
     */
    private func setNavigationDiscoveryButton() {
        let icon:UIBarButtonItem.SystemItem = mManager.isDiscovering ? .stop : .search
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: icon, target: self, action: #selector(manageDiscoveryButton))
    }
    
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mNodes.count
    }
    
    
    private static let CELL_NAME = "BlueSTSDKNetworkTableViewCell"
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellView = tableView.dequeueReusableCell(withIdentifier: BlueSTSDKNodeListViewController.CELL_NAME) as? BlueSTSDKNodeListViewCell
        
        let node = mNodes[indexPath.row]
        
        cellView?.boardName.text = node.name
        cellView?.boardDetails.text = node.addressEx()
        cellView?.boardIsSleepingImage.isHidden = !node.isSleeping
        cellView?.boardHasExtensionImage.isHidden = !node.hasExtension
        cellView?.boardImage.image = node.getTypeImage()
        return cellView!
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = mNodes[indexPath.row]
        node.addStatusDelegate(self)
        showConncetionProgress(node: node)
    }
  
    /**
     *  display the activity indicator view while we wait that the connection is done
     *
     *  @param node node selecte by the user
     */
    
    private func showConncetionProgress(node:BlueSTSDKNode){
        guard !node.isConnected() else{
            return
        }
        
        networkCheckConnHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        networkCheckConnHud?.mode = .indeterminate
        networkCheckConnHud?.removeFromSuperViewOnHide = true
        networkCheckConnHud?.label.text = BlueSTSDKNodeListViewController.CONNECTIONG
        networkCheckConnHud?.show(animated: true)
        
        delegate.prepareToConnect(node: node)
        node.connect()
    }
    
    /**
     *  pass the deleage to the next view controler
     *
     *  @param segue  storyboard segue
     *  @param sender view that start the change
     */
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BlueSTSDKNodeListViewController.SEGUE_DEMO_VIEW,
            let node = sender as? BlueSTSDKNode,
            let demoView = segue.destination as? BlueSTSDKDemoViewController{
                let demoController = delegate.demoViewController(with: node, menuManager: demoView)
                demoView.demoViewController=demoController;
                demoView.node=node;
        }//if
    }

    
 }
 
 extension BlueSTSDKNodeListViewController : BlueSTSDKManagerDelegate{
    
    public func manager(_ manager: BlueSTSDKManager, didDiscoverNode node: BlueSTSDKNode) {
        if(self.delegate.display(node: node)){
            DispatchQueue.main.async {
                self.mNodes.append(node)
                self.tableView.reloadData()
            }//async
        }//if display
    }
    
    public func manager(_ manager: BlueSTSDKManager, didChangeDiscovery enable: Bool) {
        DispatchQueue.main.async {
            self.setNavigationDiscoveryButton()
        }
    }
 }
 
 extension BlueSTSDKNodeListViewController : BlueSTSDKNodeStateDelegate{
    private static let ERROR_MSG_TIMEOUT = 3.0
    private static let ERROR_MSG_FORMAT:String = {
        let bundle = Bundle(for: BlueSTSDKNodeListViewController.self);
        return NSLocalizedString("Cannot connect with the device: %@", tableName: nil,
                                 bundle: bundle,
                                 value: "Cannot connect with the device: %@",
                                 comment: "Cannot connect with the device: %@");
    }();
    
    public func node(_ node: BlueSTSDKNode, didChange newState: BlueSTSDKNodeState, prevState: BlueSTSDKNodeState) {
        if(newState == .connected){
            DispatchQueue.main.async {
                self.onNodeConnected(node)
            }
        }else if (newState == .dead || newState == .unreachable){
            DispatchQueue.main.async {
                self.onNodeError(node)
            }
        }// if-else
    }// didChange
    
    private func onNodeConnected(_ node:BlueSTSDKNode){
        networkCheckConnHud?.hide(animated: true)
        networkCheckConnHud=nil
        performSegue(withIdentifier: BlueSTSDKNodeListViewController.SEGUE_DEMO_VIEW, sender: node)
    }
    
    private func onNodeError(_ node:BlueSTSDKNode){
        let str = String(format: BlueSTSDKNodeListViewController.ERROR_MSG_FORMAT, node.name)
        networkCheckConnHud?.hide(animated: true)
        networkCheckConnHud=nil
        networkCheckConnHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        networkCheckConnHud?.label.text = str;
        networkCheckConnHud?.show(animated: true)
        networkCheckConnHud?.hide(animated: true, afterDelay: BlueSTSDKNodeListViewController.ERROR_MSG_TIMEOUT)
    }
}
