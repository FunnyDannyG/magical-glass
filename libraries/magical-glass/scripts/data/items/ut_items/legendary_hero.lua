local item, super = Class(HealItem, "ut_items/legandary_hero")

function item:init(inventory)
    super.init(self)

    -- Display name
    self.name = "Legendary Hero"
    self.short_name = "Leg.Hero"
    self.serious_name = "L. Hero"

    -- How this item is used on you (ate, drank, eat, etc.)
    self.use_method = "eat"
    -- How this item is used on other party members (eats, etc.)
    self.use_method_other = "eats"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    self.heal_amount = 40

    -- Default shop sell price
    self.sell_price = 15
    -- Whether the item can be sold
    self.can_sell = true

    -- Light world check text
    self.check = "Heals 40 HP\n* Sandwich shaped like a sword.\n* Increases ATTACK when eaten."

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false
    
end

function item:getLightBattleText(user, target, buff)
    local message = ""
    if buff then
        message = "\n* ATTACK increased by 4!"
    end
    return "* " ..target.chara:getNameOrYou().." "..self:getUseMethod(target.chara).." the Legendary Hero."..message
end

function item:onLightBattleUse(user, target)
    self:battleUseSound(user, target)
    local buff = false
    if target.chara:getStat("attack") < 150 then
        target.chara:addStatBuff("attack", 4)
        buff = true
    end
    Game.battle:battleText(self:getLightBattleText(user, target, buff).."\n"..self:getLightBattleHealingText(user, target))
    return true
end

function item:battleUseSound(user, target)
    Game.battle.timer:script(function(wait)
        Assets.stopAndPlaySound("swallow")
        wait(0.4)
        if not Game:getFlag("#serious_mode") then
            Assets.stopAndPlaySound("hero")
        else
            Assets.stopAndPlaySound("power")
        end
    end)
end

function item:worldUseSound(target)
    Game.world.timer:script(function(wait)
        Assets.stopAndPlaySound("swallow")
        wait(0.4)
        if not Game:getFlag("#serious_mode") then
            Assets.stopAndPlaySound("hero")
        else
            Assets.stopAndPlaySound("power")
        end
    end)
end

return item