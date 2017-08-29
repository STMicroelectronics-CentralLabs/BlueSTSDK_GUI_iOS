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

#import <BlueSTSDK/BlueSTSDK_LocalizeUtil.h>

#import "BlueSTSDKNodeListViewController.h"

#import "MBProgressHUD.h"

#import "BlueSTSDKNodeListViewCell.h"
#import "BlueSTSDKDemoViewController.h"

#define SEGUE_DEMO_VIEW @"showDemoView"
//stop the discovery after 10s
#define DISCOVERY_TIMEOUT (10*1000)
#define ERROR_MSG_TIMEOUT (3.0)

@interface BlueSTSDKNodeListViewController () <BlueSTSDKManagerDelegate,
    BlueSTSDKNodeStateDelegate>

@end

@implementation BlueSTSDKNodeListViewController{
    /**
     *  class used for start/stop the discovery process
     */
    BlueSTSDKManager *mManager;
    /**
     *  list of discovered nodes
     */
    NSMutableArray *mNodes;
    
    /**
     *  view to show while the iphone is connecting to the node
     */
    MBProgressHUD *networkCheckConnHud;
    
    BlueSTSDKNode *mConnectedNode;
}

/**
 *  retreive the manager object
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    mManager = [BlueSTSDKManager sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    mNodes = [NSMutableArray array];
    //close the connection and remove knows nodes
    if(mManager.nodes.count!=0){
        for( BlueSTSDKNode *node in mManager.nodes){
            if([node isConnected]){
                [node disconnect];
            }
        }
        [mManager resetDiscovery]; // remove know nodes
        [self.tableView reloadData];
    }
}

/**
 *  start the discovery process, when the view is shown,
 *  we close the connection with all the previous discovered nodes
 *
 */
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    assert(mManager != nil);
    [mManager addDelegate:self];

    //if some node are already discovered show it, and we disconnect
    [mManager discoveryStart:DISCOVERY_TIMEOUT];
    
#if TARGET_IPHONE_SIMULATOR
    [mManager addVirtualNode];
#endif
    
    [self setNavigationDiscoveryButton];
}


/**
 *  when the view change we stop the discovering process
 *
 *  @param animated <#animated description#>
 */
- (void)viewWillDisappear:(BOOL)animated {
    assert(mManager != nil);
    [mManager removeDelegate:self];
    [mManager discoveryStop];
    [super viewWillDisappear:animated];
}

/**
 *  function called each time the user click in the uibarbutton,
 * it change the status of the discovery
 */
-(void) manageDiscoveryButton {
    if([mManager isDiscovering]){
        [mManager discoveryStop];
    }else{
        //remove old data
        [mManager resetDiscovery];
        [mNodes removeAllObjects];
        [mNodes addObjectsFromArray:mManager.nodes];
        [self.tableView reloadData];
        //start to discovery new data
        [mManager discoveryStart:DISCOVERY_TIMEOUT];
    }
}

/**
 *  add the view a bar button for enable/disable the discovery the button will
 * have a search icon if the manager is NOT searching for new nodes, or an X othewise
 */
-(void)setNavigationDiscoveryButton {
    if(mManager.isDiscovering) {
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                       target:self
                                                       action:@selector(manageDiscoveryButton)];
    }else{
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                       target:self
                                                       action:@selector(manageDiscoveryButton)];
    }//if-else
}


#pragma mark - BlueSTSDKManagerDelegate

/**
 * change the button state when the manager start/stop a discovery
 */
-(void)manager:(BlueSTSDKManager *)manager  didChangeDiscovery:(BOOL)enable {
    dispatch_sync(dispatch_get_main_queue(),^{
        [self setNavigationDiscoveryButton];
    });
    

}

/**
 *  when a new node is discover reload the table
 */
-(void)manager:(BlueSTSDKManager *)manager didDiscoverNode:(BlueSTSDKNode *)node{
    if(_delegate!=nil && [_delegate displayNode:node])
        dispatch_sync(dispatch_get_main_queue(),^{
            [mNodes addObject:node];
            [self.tableView reloadData];
        });
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return mNodes.count;
}


-(UIImage*) getBoardImage:(BlueSTSDKNodeType) type{
    NSBundle *currentBundle = [NSBundle bundleForClass: self.class];
    switch (type){

        case BlueSTSDKNodeTypeSTEVAL_WESU1:
            return [UIImage imageNamed:@"logo_steval_wesu1"
                              inBundle:currentBundle compatibleWithTraitCollection:nil];;
        case BlueSTSDKNodeTypeSensor_Tile:
            return [UIImage imageNamed:@"logo_sensorTile"
                              inBundle:currentBundle compatibleWithTraitCollection:nil];;
        case BlueSTSDKNodeTypeBlue_Coin:
            return [UIImage imageNamed:@"logo_blueCoin"
                              inBundle:currentBundle compatibleWithTraitCollection:nil];;
        case BlueSTSDKNodeTypeNucleo:
            return [UIImage imageNamed:@"logo_nucleo"
                              inBundle:currentBundle compatibleWithTraitCollection:nil];
        case BlueSTSDKNodeTypeGeneric:
        default:
            return [UIImage imageNamed:@"board_generic.png"
                              inBundle:currentBundle compatibleWithTraitCollection:nil];;
    }
}

/*
*
* build a castom row for the device,the icon depends from the board type
*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellTableIdentifier = @"BlueSTSDKNetworkTableViewCell";
    BlueSTSDKNodeListViewCell *cell = (BlueSTSDKNodeListViewCell *)[tableView dequeueReusableCellWithIdentifier:cellTableIdentifier];
    
    if (cell == nil) {
        cell = [[BlueSTSDKNodeListViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:cellTableIdentifier];
    }
    
    //get node index row
    BlueSTSDKNode *node = mNodes[indexPath.row];
    cell.boardName.text = node.name;
    cell.boardDetails.text = (node.address == nil) ? node.tag : node.address;
    cell.boardIsSleepingImage.hidden=!node.isSleeping;
    cell.boardHasExtensionImage.hidden=!node.hasExtension;
    cell.boardImage.image = [self getBoardImage:node.type];
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BlueSTSDKNode *node = mNodes[indexPath.row];
    [node addNodeStatusDelegate:self];
    [self showConnectionProgress:node];
}

#pragma mark - BlueSTSDKNodeStatusDelegate

/*
 * when the node complete the connection hide the view and do the segue for the demo
 */
- (void) node:(BlueSTSDKNode *)node didChangeState:(BlueSTSDKNodeState)newState
    prevState:(BlueSTSDKNodeState)prevState{
    if(newState == BlueSTSDKNodeStateConnected)
        dispatch_sync(dispatch_get_main_queue(),^{
            [networkCheckConnHud hideAnimated:true];
            networkCheckConnHud=nil;
            if(_delegate!=nil){
                mConnectedNode=node;
                [self performSegueWithIdentifier:SEGUE_DEMO_VIEW sender:self];
                
            }//if
        });
    else if (newState == BlueSTSDKNodeStateDead || newState == BlueSTSDKNodeStateUnreachable){
        NSString *str = [NSString stringWithFormat:BLUESTSDK_LOCALIZE(@"Cannot connect with the device: %@",nil), node.name ];
        dispatch_sync(dispatch_get_main_queue(),^{
            [networkCheckConnHud hideAnimated:true];
            networkCheckConnHud=nil;
            networkCheckConnHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            networkCheckConnHud.mode=MBProgressHUDModeText;
            networkCheckConnHud.label.text=str;
            [networkCheckConnHud showAnimated:YES];
            [networkCheckConnHud hideAnimated:true afterDelay:ERROR_MSG_TIMEOUT];
        });
    }//if-else
}

/**
 *  display the activity indicator view while we wait that the connection is done
 *
 *  @param node node selecte by the user
 */
- (void)showConnectionProgress:(BlueSTSDKNode *)node {
    if (!node.isConnected) { //we have to connect to the node
        
        networkCheckConnHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        networkCheckConnHud.mode = MBProgressHUDModeIndeterminate;
        networkCheckConnHud.removeFromSuperViewOnHide = YES;
        networkCheckConnHud.label.text = BLUESTSDK_LOCALIZE(@"Connecting",nil);
        
        [networkCheckConnHud showAnimated:YES];
        [node connect];
    }
}



/**
 *  pass the deleage to the next view controler
 *
 *  @param segue  storyboard segue
 *  @param sender view that start the change
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:SEGUE_DEMO_VIEW] && sender==self){
        BlueSTSDKDemoViewController* demoView = segue.destinationViewController;
        UIViewController *demoContent = [_delegate demoViewControllerWithNode:mConnectedNode
                                         menuManager:demoView];
        
        demoView.demoViewController=demoContent;
        demoView.node=mConnectedNode;

    }//if
    
}//prepareForSegue

@end
