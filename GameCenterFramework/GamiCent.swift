//
//  GamiCent.swift
//  GameCenterFramework
//
//  Created by Jiang Sheng on 29/3/15.
//  Copyright (c) 2015 Gison. All rights reserved.
//

import Foundation
import GameKit
import SystemConfiguration

class GamiCent : NSObject, GKGameCenterControllerDelegate {
    
    private var delegateViewController:UIViewController?
    
    struct Static {
        static var instance: GamiCent? = nil
    }
    
    class var delegate : UIViewController? {
        get {
            return GamiCent.sharedInstance.delegateViewController
        }
        set {
            GamiCent.sharedInstance.delegateViewController = newValue
        }
    }

    // Singleton: Shared instance
    class var sharedInstance: GamiCent {
        // check if we have initilized the singleton
        if Static.instance == nil {
            // have not yet, initilize and login
            Static.instance = GamiCent()
            GamiCent.loginToGameCenter(nil)
        }

        return Static.instance!
    }
    
    // Shared singleton with completion handler
    class func sharedInstance(#completion:((isAuthentified:Bool)-> Void)?) -> GamiCent {
        if Static.instance == nil {
            // have not yet, initilize and login
            Static.instance = GamiCent()
            GamiCent.loginToGameCenter({
                (result) in
                if completion != nil {
                    completion!(isAuthentified: result)
                }
            })
        } else {
            if completion != nil {
                completion!(isAuthentified: GamiCent.isAuthenticatedGameCenter())
            }
        }
        
        return Static.instance!
    }
    
    /**
        Attempt to login to the Game center
    */
    class func loginToGameCenter(#completion: ((result:Bool) -> Void)?)  {
        // First check if there is available Internet connection
        if !GamiCent.isConnectedToNetwork() {
            if completion != nil {
                completion!(result:false) // fail
            }
        } else {
            GKLocalPlayer.localPlayer().authenticateHandler = {
                (var gameCenterVC:UIViewController!, var error:NSError!) -> Void in
                /* Error */
                if error != nil {
                    println(error)
                    if completion != nil {
                        completion!(result: false)
                    }
                } else {
                    /* open the game center login view */
                    if gameCenterVC != nil {
                        if let delegateVC = GamiCent.delegate {
                            delegateVC.presentViewController(gameCenterVC, animated: true, completion: nil)
                        } else {
                            println("Error : Delegate for Easy Game Center not set.")
                            if completion != nil {
                                completion!(result: false)
                            }
                        }
                    } else if GamiCent.isAuthenticatedGameCenter() {
                        if completion != nil {
                            completion!(result: GamiCent.isAuthenticatedGameCenter())
                        }
                    } else  {
                        if completion != nil {
                            completion!(result: false)
                        }
                    }
                }
            }
        }
    }
    
    class func showLeaderboard(#leaderboardID: String, completion: ((isShow:Bool) -> Void)?) {
        if (leaderboardID == "") {
            println("Invalid leaderboard ID")
            if completion != nil {
                completion!(isShow:false)
            }
        }
        
        if GamiCent.isGameCenterAccessible() {
            if let delegateVC = GamiCent.delegate {
                var gc = GKGameCenterViewController()
                gc.gameCenterDelegate = GamiCent.sharedInstance
                gc.viewState = GKGameCenterViewControllerState.Leaderboards
                
                delegateVC.presentViewController(gc, animated: true, completion: {
                    if completion != nil {
                        completion!(isShow:true)
                    }
                })
            } else {
                println("Delegate is not set")
                if completion != nil {
                    completion!(isShow:false)
                }
            }
        } else {
            if completion != nil {
                completion!(isShow:false)
            }
        }
    }
    
    class func showAchievements(#completion: ((isShow:Bool) -> Void)?) {
        
        if GamiCent.isGameCenterAccessible() {
            
            if let delegateVC = GamiCent.delegate {
                var gc = GKGameCenterViewController()
                gc.gameCenterDelegate = GamiCent.sharedInstance
                gc.viewState = GKGameCenterViewControllerState.Achievements
                
                delegateVC.presentViewController(gc, animated: true, completion: {
                    if completion != nil {
                        completion!(isShow:true)
                    }
                })
            } else {
                println("Delegate is not set")
                if completion != nil {
                    completion!(isShow:false)
                }
            }
        } else {
            if completion != nil {
                completion!(isShow:false)
            }
        }
    }
    
    
    // MARKS: Leaderboard Operations
    
    /**
        Get all leaderboard informations
    */
    class func getLeaderboards(#completion: (resultArrayGKLeaderboard:[GKLeaderboard]?, error:NSError?) -> Void) {
        
        if GamiCent.isGameCenterAccessible() {
            
            GKLeaderboard.loadLeaderboardsWithCompletionHandler {
                (var leaderboards:[AnyObject]!, error:NSError!) -> Void in
                
                if error != nil {
                    println(error)
                    completion(resultArrayGKLeaderboard: nil, error: error)
                }
                
                if let leaderboardsIsArrayGKLeaderboard = leaderboards as? [GKLeaderboard] {
                    completion(resultArrayGKLeaderboard: leaderboardsIsArrayGKLeaderboard, error: nil)
                } else {
                    completion(resultArrayGKLeaderboard: nil, error: nil)
                }
            }
        } else {
            println("Fail to get leaderboards")
        }
    }
    
    /**
        Get single leaderboard informations
    */
    class func getLeaderboardWithID(#leaderboardID:String,
                        completion: (scoreList:[GKScore]?, localScore: GKScore?, error:NSError?) -> Void) {
                            
        if GamiCent.isGameCenterAccessible() {
            let request = GKLeaderboard()
            request.identifier = leaderboardID
            request.loadScoresWithCompletionHandler {(result, error) -> Void in
                if error != nil {
                    completion(scoreList: nil, localScore: nil, error: error)
                }
                if result == nil {
                    completion(scoreList: nil, localScore: nil, error: nil)
                } else  {
                    // return the score
                    completion(scoreList: result as? [GKScore],
                                localScore: request.localPlayerScore,
                                error: nil)
                }
            }
        } else {
            println("Fail to get leaderboards")
        }
    }
    
    /**
        Report score to leaderboard
        Currently only Integer type score can be sent
    */
    class func reportScoreLeaderboard(#leaderboardID:String, score: Int,
                                        completion: ((isSuccessful: Bool, error:NSError?) -> Void)?) {
            
        if GamiCent.isGameCenterAccessible() {
            let newScore = GKScore(leaderboardIdentifier: leaderboardID,
                                    player: GamiCent.getPlayer())
            newScore.value = Int64(score)
            newScore.shouldSetDefaultLeaderboard = false
            
            GKScore.reportScores([newScore], withCompletionHandler: { (error) -> Void in
                if error != nil {
                    if completion != nil {
                        completion!(isSuccessful: false, error: error)
                    }
                } else {
                    if completion != nil {
                        completion!(isSuccessful: true, error: nil)
                    }
                }
            })
        } else {
            println("Fail to report scores")
        }
    }
    
    // MARKS: Achievement operations
    
    // Get all achievements
    // better cache the achievements for better performance
    class func getAllAchievements(#completion: (result:[GKAchievement]?, error:NSError?) -> Void){
        if GamiCent.isGameCenterAccessible() {
            GKAchievement.loadAchievementsWithCompletionHandler({
                (var achievements:[AnyObject]!, error:NSError!) -> Void in
                if error != nil {
                    println("Game Center: could not load achievements, error: \(error)")
                    completion(result: nil, error: error)
                } else {
                    completion(result: achievements as? [GKAchievement], error: nil)
                }
            })
        } else {
            println("Fail to load")
        }
    }
    
    // Get single achievement
    class func getAchievementWithID(#achievementID:String, completion: (result:GKAchievement?, error:NSError?) -> Void) {
        GamiCent.getAllAchievements { (result, error) -> Void in
            if error != nil {
                println(error)
                return
            } else if result != nil {
                println("No result!")
                completion(result: nil, error: nil)
                return
            } else {
                for achievement in result! {
                    if achievement.identifier == achievementID {
                        completion(result: achievement, error: nil)
                        return
                    }
                }
                println("No identifier found!")
                completion(result: nil, error: nil)
            }
        }
    }
    
    class func getGKAllAchievementDescription(#completion: (descArrays:[GKAchievementDescription]?, error: NSError?) -> Void) {
        if GamiCent.isGameCenterAccessible() {
            GKAchievementDescription.loadAchievementDescriptionsWithCompletionHandler {
                (var descriptions:[AnyObject]!, error:NSError!) -> Void in
                if error != nil {
                    println("Game Center: couldn't load achievementInformation, error: \(error)")
                    completion(descArrays: nil, error: error)
                } else {
                    if let achievementDesc = descriptions as? [GKAchievementDescription] {
                        completion(descArrays: achievementDesc, error: nil)
                    } else {
                        let error = NSError()
                        completion(descArrays: nil, error: error)
                    }
                }
            }
        } else {
            let error = NSError()
            completion(descArrays: nil, error: error)
        }
        
    }
    
    // finish achievements
    class func reportAchievements( #percent : Double, achievementID : String, showBannnerIfCompleted : Bool, completion: ((success:Bool) -> Void)? ) {
        var achievement = GKAchievement(identifier: achievementID)
        if achievement != nil {
            achievement.percentComplete = percent

            /* show banner if achievement is 100% completed */
            if achievement.completed && showBannnerIfCompleted {
                achievement.showsCompletionBanner = true
            }
            
            GKAchievement.reportAchievements([achievement], withCompletionHandler: { (error) -> Void in
                if completion != nil {
                    if error != nil {
                        completion!(success: false)
                    } else {
                        completion!(success: true)
                    }
                }
            })
        }
    }
    
    class func isAuthenticatedGameCenter() -> Bool {
        return GKLocalPlayer.localPlayer().authenticated
    }
    
    class func isGameCenterAccessible() -> Bool {
        return GamiCent.isAuthenticatedGameCenter() && GamiCent.isConnectedToNetwork()
    }
    
    class func getPlayer() -> GKLocalPlayer {
        return GKLocalPlayer.localPlayer()
    }
    
    
    
    /*
        Check device's network connection
        This brilliant solution is retrieved from StackOverflow
        Reference: http://stackoverflow.com/a/25774420/3252242
    */
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection) ? true : false
    }
    
    
    // MARKS: game center view ctrl delegate
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        println("Im called!")
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
}