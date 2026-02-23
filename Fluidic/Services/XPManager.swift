import Foundation

struct XPLevel {
    let level: Int
    let xpRequired: Int
    let titleEN: String
    let titleCS: String
}

@Observable
final class XPManager {

    var showLevelUp = false
    var newLevel: Int = 0

    static let levels: [XPLevel] = [
        XPLevel(level: 1, xpRequired: 0, titleEN: "Beginner", titleCS: "Začátečník"),
        XPLevel(level: 2, xpRequired: 300, titleEN: "Hydration Rookie", titleCS: "Nováček hydratace"),
        XPLevel(level: 3, xpRequired: 800, titleEN: "Water Apprentice", titleCS: "Vodní učeň"),
        XPLevel(level: 4, xpRequired: 1500, titleEN: "Hydration Pro", titleCS: "Profík hydratace"),
        XPLevel(level: 5, xpRequired: 3000, titleEN: "Water Master", titleCS: "Vodní mistr"),
        XPLevel(level: 6, xpRequired: 5000, titleEN: "Hydration Legend", titleCS: "Legenda hydratace"),
        XPLevel(level: 7, xpRequired: 8000, titleEN: "Aqua Champion", titleCS: "Aqua šampion"),
        XPLevel(level: 8, xpRequired: 12000, titleEN: "Supreme Hydrator", titleCS: "Nejvyšší hydrátor"),
        XPLevel(level: 9, xpRequired: 18000, titleEN: "Fluidic Elite", titleCS: "Fluidic elita"),
        XPLevel(level: 10, xpRequired: 25000, titleEN: "Transcendent", titleCS: "Transcendentní"),
    ]

    func awardXP(_ amount: Int, settings: UserSettings?) {
        guard let settings else { return }
        settings.totalXP += amount

        let newLvl = Self.levelFor(xp: settings.totalXP)
        if newLvl > settings.currentLevel {
            settings.currentLevel = newLvl
            newLevel = newLvl
            showLevelUp = true
        }
    }

    static func levelFor(xp: Int) -> Int {
        var level = 1
        for l in levels {
            if xp >= l.xpRequired { level = l.level }
            else { break }
        }
        return level
    }

    static func xpForNextLevel(currentLevel: Int) -> Int {
        if currentLevel >= levels.count { return levels.last?.xpRequired ?? 0 }
        return levels[currentLevel].xpRequired
    }

    static func xpForCurrentLevel(currentLevel: Int) -> Int {
        guard currentLevel >= 1, currentLevel <= levels.count else { return 0 }
        return levels[currentLevel - 1].xpRequired
    }

    static func progressToNextLevel(totalXP: Int, currentLevel: Int) -> Double {
        if currentLevel >= levels.count { return 1.0 }
        let currentThreshold = xpForCurrentLevel(currentLevel: currentLevel)
        let nextThreshold = xpForNextLevel(currentLevel: currentLevel)
        let range = nextThreshold - currentThreshold
        guard range > 0 else { return 1.0 }
        return Double(totalXP - currentThreshold) / Double(range)
    }

    static func title(for level: Int, isCS: Bool) -> String {
        guard level >= 1, level <= levels.count else { return "" }
        let l = levels[level - 1]
        return isCS ? l.titleCS : l.titleEN
    }

    func dismissLevelUp() {
        showLevelUp = false
    }
}
