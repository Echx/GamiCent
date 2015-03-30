//
//  ViewController.swift
//  GameCenterFramework
//
//  Created by Jiang Sheng on 29/3/15.
//  Copyright (c) 2015 Gison. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var newScoreField: UITextField!
    @IBOutlet weak var playerInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gamiCent = GamiCent.sharedInstance({
            (isAuthentified) -> Void in
            println(isAuthentified)
            if isAuthentified {
                /* Success! */
                println("Login!!!")
                let player = GamiCent.getPlayer()
                self.playerInfo.text = "PlayerId: \(player.playerID) Name: \(player.alias)"
            } else {
                /* Failed. */
                /* No internet connection? not authentified? */
                println("Failed!!!")
            }
        })
        /* Set delegate */
        GamiCent.delegate = self
    }
    
    @IBAction func reportNewScore(sender: AnyObject) {
        // get score
        if let score = newScoreField.text.toInt() {
            GamiCent.reportScoreLeaderboard(leaderboardID: "gamicent_leader1", score: score) { (isSuccessful, error) in
                if (error != nil) {
                    println("Error!")
                    return
                }
                if (isSuccessful) {
                    println("new Score \(score) sent!")
                } else {
                    println("Score not sent due to network or player auth.")
                }
            }
        } else {
            println("Input wrong things!")
        }
    }
    
    
    @IBAction func getLeaderboards(sender: AnyObject) {
        GamiCent.getLeaderboards { (resultArrayGKLeaderboard, error) -> Void in
            if (error != nil) {
                println("Error!")
                return
            }
            
            if (resultArrayGKLeaderboard != nil) {
                println("Get leaderboards")
                for item in resultArrayGKLeaderboard! {
                    println("ID: \(item.identifier)")
                    println("ID: \(item.title)")
                }
            }
            
        }
    }
    
    @IBAction func getScoresInLeaderboard(sender: AnyObject) {
        println("Get current leaderboard")
        GamiCent.getLeaderboardWithID(leaderboardID: "gamicent_leader1") {
            (scoreList, localScore, error) in
            if (error != nil) {
                println("Error")
                return
            }
            
            if (scoreList != nil) {
                println("Leaderboard Identifier : \(localScore!.leaderboardIdentifier)")
                println("Date : \(localScore!.date)")
                println("Rank :\(localScore!.rank)")
                println("Hight Score : \(localScore!.value)")
                println("All scores: \(scoreList)")
            }
        }
    }
    
    @IBAction func openLeaderboard(sender : AnyObject) {
        GamiCent.showLeaderboard(leaderboardID: "gamicent_leader1") { (isShow) -> Void in
            if (isShow) {
                println("Success")
            } else {
                println("Fail!")
            }
        }
    }
    
    @IBAction func openAchievement(sender : AnyObject) {
        GamiCent.showAchievements { (isShow) -> Void in
            if isShow {
                println("Success")
            } else {
                println("Fail")
            }
        }
    }

    @IBAction func getAchievements(sender : AnyObject) {
        GamiCent.getAllAchievementDescription { (result, error) -> Void in
            if error != nil {
                println(error)
            } else {
                if let achievements = result {
                    for achievement in achievements {
                        println("ID: \(achievement.identifier)")
                        println("Description: \(achievement.unachievedDescription)")
                    }
                } else {
                    println("No achievement")
                }
            }
        }
    }
    
    @IBAction func getSingleAchievements(sender : AnyObject) {
        GamiCent.getAchievementWithID(achievementID: "gamicent_a1") { (result, error) -> Void in
            if error != nil {
                println(error)
            } else {
                if let achievement = result {
                    println("ID: \(achievement.identifier)")
                    println("Description: \(achievement.percentComplete)")
                } else {
                    println("No such achievement")
                }
            }
        }
    }
    
    @IBAction func reportFinished(sender : AnyObject) {
        GamiCent.reportAchievements(percent: 100.0, achievementID: "gamicent_a1", isShowBanner: true) { (success) -> Void in
            if (success) {
                println("Finished reporting!")
            }
        }
    }

}

