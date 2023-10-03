local item, super = Class(LightEquipItem, "ut_armors/cloudy_glasses")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Cloudy Glasses"
    self.short_name = "ClodGlass"
    self.serious_name = "Glasses"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Whether this item is for the light world
    self.light = true

    -- Default shop price (sell price is halved)
    self.price = 35
    -- Default shop sell price
    self.sell_price = 50
    -- Whether the item can be sold
    self.can_sell = true

    -- Light world check text
    self.check = {
        "Weapon DF 6\n* Glasses marred with wear.\n* Increases INV by 9.",
        "* (After you get hurt by an\nattack,[wait:10] you stay invulnerable\nfor longer.)" -- doesn't show up in UT???
    }

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"

    self.inv_bonus = 1

    self.bonuses = {
        defense = 6
    }

end

function item:showEquipText()
    Game.world:showText("* You equipped the glasses.")
end

function item:getLightBattleText(user, target)
    return "* "..target.chara:getNameOrYou().." equipped the glasses."
end

return item