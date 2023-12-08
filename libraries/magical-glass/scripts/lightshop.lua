local LightShop, super = Class(Object)

function LightShop:init()
    super.init(self)
    self.currency_text = "%d"..Game:getConfig("lightCurrencyShort")
    self.sell_currency_text = "($%"..Game:getConfig("lightCurrencyShort")..")"

    -- Shown when you first enter a shop
    self.encounter_text = "* Encounter text"
    -- Shown when you return to the main menu of the shop
    self.shop_text = "* Shop text"
    -- Shown when you leave a shop
    self.leaving_text = "* Leaving text"
    -- Shown when you're in the BUY menu
    self.buy_menu_text = "Purchase\ntext"
    -- Shown when you're about to buy something.
    self.buy_confirmation_text = "Buy it for\n%s ?"
    -- Shown when you refuse to buy something
    self.buy_refuse_text = "Buy\nrefused\ntext"
    -- Shown when you buy something
    self.buy_text = "Buy text"
    -- Shown when you buy something and it goes in your storage
    self.buy_storage_text = "Storage\nbuy text"
    -- Shown when you don't have enough money to buy something
    self.buy_too_expensive_text = "Not\nenough\nmoney."
    -- Shown when you don't have enough space to buy something.
    self.buy_no_space_text = "You're\ncarrying\ntoo much."
    -- Shown when something doesn't have a sell price
    self.sell_no_price_text = "No\nprice\ntext"
    -- Shown when you're in the SELL menu
    self.sell_menu_text = "Sell\nmenu\ntext"
    -- Shown when you try to sell an empty spot
    self.sell_nothing_text = "Sell\nnothing\attempt"
    -- Shown when you're about to sell something.
    self.sell_confirmation_text = "Sell it for\n%s ?"
    -- Shown when you refuse to sell something
    self.sell_refuse_text = "Sell\nrefuse\ntext"
    -- Shown when you sell something
    self.sell_text = "Sell\ntext"
    -- Shown when you have nothing in a storage
    self.sell_no_storage_text = "Empty\ninventory\ntext"
    -- Shown when you enter the talk menu.
    self.talk_text = "Talk\ntext"

    self.hide_storage_text = false

    -- MAINMENU
    self.menu_options = {
        {"Buy",  "BUYMENU" },
        {"Sell", "SELLMENU"},
        {"Talk", "TALKMENU"},
        {"Exit", "LEAVE"   }
    }

    self.items = {}
    self.talks = {}
    self.talk_replacements = {}

    -- SELLMENU
    self.sell_storage = "items"

    self.sold_text = "Thank you!"

    self.background = "ui/shop/bg_seam"

    -- STATES: MAINMENU, BUYMENU, SELLMENU, SELLING, TALKMENU, LEAVE, LEAVING, DIALOGUE
    self.state = "NONE"
    self.state_reason = nil

    self.buy_confirming = false
    self.sell_confirming = false

    self.shop_music = ""
    self.music = Music()

    self.timer = Timer()
    self:addChild(self.timer)

    self.voice = nil

    self.shopkeeper = Shopkeeper()
    self.shopkeeper:setPosition(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.shopkeeper.layer = SHOP_LAYERS["shopkeeper"]
    self:addChild(self.shopkeeper)

    self.bg_cover = Rectangle(0, SCREEN_HEIGHT/2, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.bg_cover:setColor(0, 0, 0)
    self.bg_cover.layer = SHOP_LAYERS["cover"]
    self:addChild(self.bg_cover)

    self.current_selecting = 1
    -- self.current_selecting will be in use... so let's just add another????????
    self.current_selecting_choice = 1
    -- This'll be a separate variable because it keeps track of
    -- what you selected between main menu options. This can
    -- normally be done with hardcoded position sets, like in
    -- other places, but in the Spamton shop in Deltarune,
    -- SELL is replaced with BUYMORE!!!, and when you exit out
    -- of that menu, it places you on the correct menu option.
    self.main_current_selecting = 1
    -- Same here too...
    self.sell_current_selecting = 1
    -- Oh my god
    self.item_current_selecting = 1

    self.item_offset = 0

    self.font = Assets.getFont("main")
    self.heart_sprite = Assets.getTexture("player/heart_menu")

    self.fade_alpha = 0
    self.fading_out = false
    self.box_ease_timer = 0
    self.box_ease_beginning = -8
    self.box_ease_top = 220 - 53
    self.box_ease_method = "outExpo"
    self.box_ease_multiplier = 1

    self.draw_divider = true

    self.hide_price = false

    self.leave_options = {}
end

function LightShop:postInit()
    -- Mutate talks

    self:processReplacements()

    -- Make a sprite for the background
    if self.background and self.background ~= "" then
        self.background_sprite = Sprite(self.background, 0, 0)
        self.background_sprite:setScale(2, 2)
        self.background_sprite.layer = SHOP_LAYERS["background"]
        self:addChild(self.background_sprite)
    end

    -- Construct the UI
    self.large_box = UIBox(0, 0, 0, 0, "shop")
    local left, top = self.large_box:getBorder()
    self.large_box:setOrigin(0, 1)
    self.large_box.x = left - 8
    self.large_box.y = SCREEN_HEIGHT - top + 10
    self.large_box.width = SCREEN_WIDTH - (top * 2) + 18
    self.large_box.height = 194
    self.large_box:setLayer(SHOP_LAYERS["right_box"])

    self:addChild(self.large_box)

    self.info_box = UIBox(0, 0, 0, 0, "shop")
    local left, top = self.info_box:getBorder()
    self.info_box:setOrigin(1, 1)
    self.info_box.x = SCREEN_WIDTH - left + 10
    -- find a more elegant way to do this...
    self.info_box.y = SCREEN_HEIGHT - top - self.large_box.height - (1 * 2) + 16 + 1
    self.info_box.width = 174
    self.info_box.height = 180
    self.info_box:setLayer(SHOP_LAYERS["info_box"])

    self.info_box.visible = false

    self:addChild(self.info_box)

    local emoteCommand = function(text, node)
        self:onEmote(node.arguments[1])
    end

    self.dialogue_text = DialogueText(nil, 40, 260, 372, 194)

    self.dialogue_text:registerCommand("emote", emoteCommand)

    self.dialogue_text:setLayer(SHOP_LAYERS["dialogue"])
    self:addChild(self.dialogue_text)
    self:setDialogueText(self.encounter_text)

    self.right_text = DialogueText("", 40 + 420, 260, 176, 206)

    self.right_text:registerCommand("emote", emoteCommand)

    self.right_text:setLayer(SHOP_LAYERS["dialogue"])
    self:addChild(self.right_text)
    self:setRightText("")

    self.talk_dialogue = {self.dialogue_text, self.right_text}
end

function LightShop:startTalk(talk) end

function LightShop:onEnter()
    self:setState("MAINMENU")
    self:setDialogueText(self.encounter_text)
    -- Play music
    if self.shop_music and self.shop_music ~= "" then
        self.music:play(self.shop_music)
    end
end

function LightShop:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end

function LightShop:getVoice()
    return self.voice
end

function LightShop:getVoicedText(text)
    local voice = self:getVoice()

    if not voice then return text end

    if type(text) == "table" then
        local voiced_text = {}
        for _,v in ipairs(text) do
            table.insert(voiced_text, "[voice:"..voice.."]"..v)
        end
        return voiced_text
    else
        return "[voice:"..voice.."]"..text
    end
end

function LightShop:setDialogueText(text, no_voice)
    self.dialogue_text:setText(no_voice and text or self:getVoicedText(text))
end

function LightShop:setRightText(text, no_voice)
    self.right_text:setText(no_voice and text or self:getVoicedText(text))
end

function LightShop:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

function LightShop:getState()
    return self.state
end

function LightShop:onStateChange(old,new)
    Game.key_repeat = false
    self.buy_confirming = false
    self.sell_confirming = false
    if new == "MAINMENU" then
        self.info_box.visible = false
        self.dialogue_text.width = 372
        self:setDialogueText(self.shop_text)
        self:setRightText("")
    elseif new == "BUYMENU" then
        self:setDialogueText("")
        self:setRightText(self.buy_menu_text)
        self.info_box.visible = true
        self.info_box.height = -8
        self.box_ease_timer = 0
        self.box_ease_beginning = -8
        if #self.items > 0 then
            self.box_ease_top = 220 - 53
        else
            self.box_ease_top = -8
        end
        self.box_ease_method = "outExpo"
        self.box_ease_multiplier = 1
        self.current_selecting = 1
    elseif new == "SELLMENU" then
        self:setDialogueText("")
        if not self.state_reason then
            self:setRightText(self.sell_menu_text)
        end
        self.info_box.visible = false
    elseif new == "SELLING" then
        Game.key_repeat = true
        self:setDialogueText("")
        if self.state_reason and type(self.state_reason) == "table" then
            if self.sell_options_text[self.state_reason[2]] then
                self:setRightText(self.sell_options_text[self.state_reason[2]])
            else
                self:setRightText("Invalid\nmenu\ntext")
            end
        else
            self:setRightText("Invalid\nstate\nreason")
        end
        self.info_box.visible = false
        self.item_current_selecting = 1
        self.item_offset = 0
    elseif new == "TALKMENU" then
        self:setDialogueText("")
        self:setRightText(self.talk_text)
        self.info_box.visible = false
        if self.state_reason ~= "DIALOGUE" then
            self.current_selecting = 1
        end
        self:processReplacements()
        self:onTalk()
    elseif new == "LEAVE" then
        self:setRightText("")
        self.info_box.visible = false
        self:onLeave()
    elseif new == "LEAVING" then
        self:setRightText("")
        self:setDialogueText("")
        self.info_box.visible = false
        self:leave()
    elseif new == "DIALOGUE" then
        self.dialogue_text.width = 598
        self:setRightText("")
        self.info_box.visible = false
    end
end

function LightShop:onLeave()
    self:startDialogue(self.leaving_text, "LEAVING")
end

function LightShop:leave()
    self.fading_out = true
    self.music:fade(0, 20/30)
end

function LightShop:leaveImmediate()
    self:remove()
    Game.shop = nil
    Game.state = "OVERWORLD"
    Game.fader.alpha = 1
    Game.fader:fadeIn()
    Game.world:setState("GAMEPLAY")

    --self.transition_target.shop = nil
    --Game.world:transitionImmediate(self.transition_target)
    if self.leave_options["menu"] then
        Game:returnToMenu()
    elseif self.leave_options["x"] then
        Game.world:mapTransition(self.leave_options["map"] or Game.world.map.id, self.leave_options["x"], self.leave_options["y"], self.leave_options["facing"])
    elseif self.leave_options["marker"] then
        Game.world:mapTransition(self.leave_options["map"] or Game.world.map.id, self.leave_options["marker"], self.leave_options["facing"])
    else
        if self.leave_options["facing"] then
            Game.world.player:setFacing(self.leave_options["facing"])
        end
        Game.world.music:resume()
    end
end

function LightShop:onTalk() end

function LightShop:onEmote(emote)
    -- Default behaviour: set sprite / animation
    self.shopkeeper:onEmote(emote)
end

function LightShop:startDialogue(text,callback)

    local state = "MAINMENU"
    if self.state == "TALKMENU" then
        state = "TALKMENU"
    end

    self:setState("DIALOGUE")
    self:setDialogueText(text)

    self.dialogue_text.advance_callback = (function()
        if type(callback) == "string" then
            state = callback
        elseif type(callback) == "function" then
            if callback() then
                return
            end
        end

        self:setState(state, "DIALOGUE")
    end)
end

function LightShop:registerItem(item, options)
    return self:replaceItem(#self.items + 1, item, options)
end

function LightShop:replaceItem(index, item, options)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if item then
        options = options or {}
        options["name"]        = options["name"]        or item:getName()
        options["description"] = options["description"] or item:getLightShopDescription()
        options["price"]       = options["price"]       or item:getBuyPrice()
        options["bonuses"]     = options["bonuses"]     or item:getStatBonuses()
        options["color"]       = options["color"]       or {1, 1, 1, 1}
        options["flag"]        = options["flag"]        or ("stock_" .. tostring(index) .. "_" .. item.id)

        options["stock"] = self:getFlag(options["flag"], options["stock"])

        self.items[index] = {
            item = item,
            options = options
        }
        return true
    else
        return false
    end
end

function LightShop:registerTalk(talk, color)
    table.insert(self.talks, {talk, {color=color or COLORS.white}})
end

function LightShop:replaceTalk(talk, index, color)
    self.talks[index] = {talk, {color=color or COLORS.yellow}}
end

function LightShop:registerTalkAfter(talk, index, flag, value, color)
    table.insert(self.talk_replacements, {index, {talk, {flag=flag or ("talk_" .. tostring(index)), value=value, color=color or COLORS.yellow}}})
end

function LightShop:processReplacements()
    for i = 1, #self.talks do
        -- Replace talk option if any replacements flag is set
        -- (Replacements registered later have higher priority)
        for j = 1, #self.talk_replacements do
            if self.talk_replacements[j][1] == i then
                local talk_replacement = self.talk_replacements[j][2]
                if self:getFlag(talk_replacement[2].flag) == (talk_replacement[2].value or true) then
                    self:replaceTalk(talk_replacement[1], i, talk_replacement[2].color)
                end
            end
        end
    end
end

function LightShop:update()
    -- Update talk sprites
    for _,object in ipairs(self.talk_dialogue) do
        if self.shopkeeper.talk_sprite then
            object.talk_sprite = self.shopkeeper.sprite
        else
            object.talk_sprite = nil
        end
    end

    super.update(self)

    self.box_ease_timer = math.min(1, self.box_ease_timer + (DT * self.box_ease_multiplier))

    if self.state == "BUYMENU" then
        self.info_box.height = Utils.ease(self.box_ease_beginning, self.box_ease_top, self.box_ease_timer, self.box_ease_method)

        if self.shopkeeper.slide then
            local target_x = SCREEN_WIDTH/2 - 80
            if self.shopkeeper.x > target_x + 60 then
                self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
            end
            if self.shopkeeper.x > target_x + 40 then
                self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
            end
            if self.shopkeeper.x > target_x then
                self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
            end
        end
    elseif self.shopkeeper.slide then
        local target_x = SCREEN_WIDTH/2
        if self.shopkeeper.x < target_x - 50 then
            self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x < target_x - 30 then
            self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x < target_x then
            self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
    end

    if self.fading_out then
        self.fade_alpha = self.fade_alpha + (DT * 2)
        if self.fade_alpha >= 1 then
            self:leaveImmediate()
        end
    end
end

function LightShop:draw()
    self:drawBackground()

    super.draw(self)

    if self.draw_divider then
        Draw.setColor(COLORS.white)
        love.graphics.setLineWidth(8)
        love.graphics.line((self.large_box.width/2) + 127, self.large_box.y + 50, (self.large_box.width/2) + 127, self.large_box.height + 50)
    end

    love.graphics.setFont(self.font)
    if self.state == "MAINMENU" then
        Draw.setColor(COLORS.white)
        for i = 1, #self.menu_options do
            love.graphics.print(self.menu_options[i][1], 480, 220 + (i * 40))
        end
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 450, 228 + (self.main_current_selecting * 40), 0, 2)
    elseif self.state == "BUYMENU" then

        while self.current_selecting - self.item_offset > 5 do
            self.item_offset = self.item_offset + 1
        end

        while self.current_selecting - self.item_offset < 1 do
            self.item_offset = self.item_offset - 1
        end

        if self.item_offset + 5 > #self.items + 1 then
            if #self.items + 1 > 5 then
                self.item_offset = self.item_offset - 1
            end
        end

        if #self.items + 1 == 5 then
            self.item_offset = 0
        end

        -- Item type (item, key, weapon, armor)
        for i = 1 + self.item_offset, self.item_offset + math.max(4, math.min(5, #self.items)) do
            if i == math.max(4, #self.items) + 1 then break end
            local y = 220 + ((i - self.item_offset) * 40)
            local item = self.items[i]
            if not item then
                -- If the item is null, add some empty space
                Draw.setColor(COLORS.dkgray)
                love.graphics.print("--------", 60, y)
            elseif item.options["stock"] and (item.options["stock"] <= 0) then
                -- If we've depleted the stock, show a "sold out" message
                Draw.setColor(COLORS.gray)
                love.graphics.print("--- SOLD OUT ---", 60, y)
            else
                Draw.setColor(item.options["color"])
                local str
                if not self.hide_price then
                    str = string.format(self.currency_text, item.options["price"] or 0) .. " - " .. item.options["name"]
                else
                    str = item.options["name"]
                end
                if item.options["price"] and item.options["price"] < 10 then
                    str = "  " .. str
                end
                love.graphics.print(str, 60, y)
            end
        end
        Draw.setColor(COLORS.white)
        if self.item_offset == math.max(4, #self.items) - 4 then
            love.graphics.print("Exit", 60, 220 + (math.max(4, #self.items) + 1 - self.item_offset) * 40)
        end
        Draw.setColor(Game:getSoulColor())
        if not self.buy_confirming then
            Draw.draw(self.heart_sprite, 30, 228 + ((self.current_selecting - self.item_offset) * 40), 0, 2)
        else
            Draw.draw(self.heart_sprite, 30 + 420, 228 + 80 + 10 + (self.current_selecting_choice * 30), 0, 2)
            Draw.setColor(COLORS.white)
            local lines = Utils.split(string.format(self.buy_confirmation_text, string.format(self.currency_text, self.items[self.current_selecting].options["price"] or 0)), "\n")
            for i = 1, #lines do
                love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
            end
            love.graphics.print("Yes", 60 + 420, 420 - 80)
            love.graphics.print("No",  60 + 420, 420 - 80 + 30)
        end
        Draw.setColor(COLORS.white)

        if (self.current_selecting <= #self.items) then
            local current_item = self.items[self.current_selecting]
            local box_left, box_top = self.info_box:getBorder()

            local left = self.info_box.x - self.info_box.width - (box_left / 2) * 1.5
            local top = self.info_box.y - self.info_box.height - (box_top / 2) * 1.5
            local width = self.info_box.width + box_left * 1.5
            local height = self.info_box.height

            Draw.pushScissor()
            Draw.scissor(left, top, width, height)

            Draw.setColor(COLORS.white)
            if not current_item.options["dont_show_change"] == true and (current_item.item.type == "weapon" or current_item.item.type == "armor") then
                local equip
                local difference = ""
                local stat = ""
                if current_item.item.type == "weapon" then
                    equip = Game.party[1]:getWeapon()
                    difference = current_item.item:getStatBonus("attack") - equip:getStatBonus("attack")
                    stat = "AT"
                elseif current_item.item.type == "armor" then
                    equip = Game.party[1]:getArmor(1)
                    difference = current_item.item:getStatBonus("defense") - equip:getStatBonus("defense")
                    stat = "DF"
                end

                if difference >= 0 then
                    difference = "+" .. difference
                else
                    difference = "-" .. difference
                end

                local desc = current_item.options["description"] .. "("..difference.." "..stat..")"
                love.graphics.print(desc, left + 28, top + 28)
            else
                love.graphics.print(current_item.options["description"], left + 28, top + 28)
            end

            Draw.popScissor()
        end
    elseif self.state == "SELLMENU" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 50, 230 + (self.sell_current_selecting * 40), 0, 2)
        Draw.setColor(COLORS.white)
        love.graphics.setFont(self.font)
        for i, v in ipairs(self.sell_options) do
            love.graphics.print(v[1], 80, 220 + (i * 40))
        end
        love.graphics.print("Return", 80, 220 + ((#self.sell_options + 1) * 40))
    elseif self.state == "SELLING" then
        if self.item_current_selecting - self.item_offset > 5 then
            self.item_offset = self.item_offset + 1
        end

        if self.item_current_selecting - self.item_offset < 1 then
            self.item_offset = self.item_offset - 1
        end

        local inventory = Game.inventory:getStorage(self.state_reason[2])

        if inventory and inventory.sorted then
            if self.item_offset + 5 > #inventory then
                if #inventory > 5 then
                    self.item_offset = self.item_offset - 1
                end
            end
            if #inventory == 5 then
                self.item_offset = 0
            end
        end

        Draw.setColor(Game:getSoulColor())

        Draw.draw(self.heart_sprite, 30, 230 + ((self.item_current_selecting - self.item_offset) * 40), 0, 2)
        if self.sell_confirming then
            Draw.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30), 0, 2)
            Draw.setColor(COLORS.white)
            local lines = Utils.split(string.format(self.sell_confirmation_text, string.format(self.currency_text, inventory[self.item_current_selecting]:getSellPrice())), "\n")
            for i = 1, #lines do
                love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
            end
            love.graphics.print("Yes", 60 + 420, 420 - 80)
            love.graphics.print("No",  60 + 420, 420 - 80 + 30)
        end

        Draw.setColor(COLORS.white)

        if inventory then
            for i = 1 + self.item_offset, self.item_offset + math.min(5, inventory.max) do
                local item = inventory[i]
                love.graphics.setFont(self.font)

                if item then
                    Draw.setColor(COLORS.white)
                    love.graphics.print(item:getName(), 60, 220 + ((i - self.item_offset) * 40))
                    if item:isSellable() then
                        love.graphics.print(string.format(self.currency_text, item:getSellPrice()), 60 + 240, 220 + ((i - self.item_offset) * 40))
                    end
                else
                    Draw.setColor(COLORS.dkgray)
                    love.graphics.print("--------", 60, 220 + ((i - self.item_offset) * 40))
                end
            end

            local max = inventory.max
            if inventory.sorted then
                max = #inventory
            end

            Draw.setColor(COLORS.white)

            if max > 5 then

                for i = 1, max do
                    local percentage = (i - 1) / (max - 1)
                    local height = 129

                    local draw_location = percentage * height

                    local tocheck = self.item_current_selecting
                    if self.sell_confirming then
                        tocheck = self.current_selecting_choice
                    end

                    if i == tocheck then
                        love.graphics.rectangle("fill", 372, 292 + draw_location, 9, 9)
                    elseif inventory.sorted then
                        love.graphics.rectangle("fill", 372 + 3, 292 + 3 + draw_location, 3, 3)
                    end
                end

                -- Draw arrows
                if not self.sell_confirming then
                    local sine_off = math.sin((Kristal.getTime()*30)/6) * 3
                    if self.item_offset + 4 < (max - 1) then
                        Draw.draw(self.arrow_sprite, 370, 149 + sine_off + 291)
                    end
                    if self.item_offset > 0 then
                        Draw.draw(self.arrow_sprite, 370, 14 - sine_off + 291 - 25, 0, 1, -1)
                    end
                end
            end
        else
            love.graphics.print("Invalid storage", 60, 220 + (1 * 40))
        end
    elseif self.state == "TALKMENU" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 30, 228 + (self.current_selecting * 40), 0, 2)
        Draw.setColor(COLORS.white)
        love.graphics.setFont(self.font)
        for i = 1, math.max(4, #self.talks) do
            local v = self.talks[i]
            if v then
                Draw.setColor(v[2].color)
                love.graphics.print(v[1], 60, 220 + (i * 40))
            else
                Draw.setColor(COLORS.dkgray)
                love.graphics.print("--------", 60, 220 + (i * 40))
            end
        end
        Draw.setColor(COLORS.white)
        love.graphics.print("Exit", 60, 220 + ((math.max(4, #self.talks) + 1) * 40))
    end

    if self.state == "MAINMENU" or
       self.state == "BUYMENU"  or
       self.state == "SELLMENU" or
       self.state == "SELLING"  or
       self.state == "TALKMENU" then
        Draw.setColor(COLORS.white)
        love.graphics.setFont(self.font)
        love.graphics.print(string.format(self.currency_text, self:getMoney()), 460, 420)

        local current_storage = Game.inventory:getStorage(self.sell_storage)
        local space = Game.inventory:getFreeSpace(current_storage)

        love.graphics.print(space .. "/" .. current_storage.max, 560, 420)
    end

    Draw.setColor(0, 0, 0, self.fade_alpha)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

function LightShop:drawBackground()
    -- Draw a black backdrop
    Draw.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

function LightShop:onKeyPressed(key, is_repeat)
    if self.state == "MAINMENU" then
        if Input.isConfirm(key) then
            local selection = self.menu_options[self.main_current_selecting][2]
            if type(selection) == "string" then
                self:setState(selection)
            elseif type(selection) == "function" then
                selection()
            end
        elseif Input.is("up", key) then
            self.main_current_selecting = self.main_current_selecting - 1
            if (self.main_current_selecting <= 0) then
                self.main_current_selecting = #self.menu_options
            end
        elseif Input.is("down", key) then
            self.main_current_selecting = self.main_current_selecting + 1
            if (self.main_current_selecting > #self.menu_options) then
                self.main_current_selecting = 1
            end
        end
    elseif self.state == "BUYMENU" then
        if self.buy_confirming then
            if Input.isConfirm(key) then
                self.buy_confirming = false
                local current_item = self.items[self.current_selecting]
                if self.current_selecting_choice == 1 then
                    self:buyItem(current_item)
                elseif self.current_selecting_choice == 2 then
                    self:setRightText(self.buy_refuse_text)
                else
                    self:setRightText("What?????[wait:5]\ndid you\ndo????")
                end
            elseif Input.isCancel(key) then
                self.buy_confirming = false
                self:setRightText(self.buy_refuse_text)
            elseif Input.is("up", key) or Input.is("down", key) then
                if self.current_selecting_choice == 1 then
                    self.current_selecting_choice = 2
                else
                    self.current_selecting_choice = 1
                end
            end
        else
            local old_selecting = self.current_selecting
            if Input.isConfirm(key) then
                if self.current_selecting == math.max(#self.items, 4) + 1 then
                    self:setState("MAINMENU")
                elseif self.items[self.current_selecting] then
                    if self.items[self.current_selecting].options["stock"] then
                        if self.items[self.current_selecting].options["stock"] <= 0 then
                            return
                        end
                    end
                    self.buy_confirming = true
                    self.current_selecting_choice = 1
                    self:setRightText("")
                end
            elseif Input.isCancel(key) then
                self:setState("MAINMENU")
            elseif Input.is("up", key) then
                self.current_selecting = self.current_selecting - 1
                if (self.current_selecting <= 0) then
                    self.current_selecting = math.max(#self.items, 4) + 1
                end
            elseif Input.is("down", key) then
                self.current_selecting = self.current_selecting + 1
                if (self.current_selecting > math.max(#self.items, 4) + 1) then
                    self.current_selecting = 1
                end
            end
            if Input.is("up", key) or Input.is("down", key) then
                if self.current_selecting >= #self.items + 1 then
                    self.box_ease_timer = 0
                    self.box_ease_beginning = self.info_box.height
                    self.box_ease_top = -8
                    self.box_ease_method = "linear"
                    self.box_ease_multiplier = 8
                elseif (old_selecting >= #self.items + 1) and (self.current_selecting <= #self.items) then
                    self.box_ease_timer = 0
                    self.box_ease_beginning = self.info_box.height
                    self.box_ease_top = 220 - 53
                    self.box_ease_method = "outExpo"
                    self.box_ease_multiplier = 1
                end
            end
        end
    elseif self.state == "SELLMENU" then
        if Input.isConfirm(key) then
            if (self.sell_current_selecting <= #self.sell_options) then
                self:enterSellMenu(self.sell_options[self.sell_current_selecting])
            else
                self:setState("MAINMENU")
            end
        elseif Input.isCancel(key) then
            self:setState("MAINMENU")
        elseif Input.is("up", key) then
            self.sell_current_selecting = self.sell_current_selecting - 1
            if (self.sell_current_selecting <= 0) then
                self.sell_current_selecting = #self.sell_options + 1
            end
        elseif Input.is("down", key) then
            self.sell_current_selecting = self.sell_current_selecting + 1
            if (self.sell_current_selecting > #self.sell_options + 1) then
                self.sell_current_selecting = 1
            end
        end
    elseif self.state == "SELLING" then
        local inventory = Game.inventory:getStorage(self.state_reason[2])
        if inventory then
            if self.sell_confirming then
                if Input.isConfirm(key) then
                    self.sell_confirming = false
                    Game.key_repeat = true
                    local current_item = inventory[self.item_current_selecting]
                    if self.current_selecting_choice == 1 then
                        self:sellItem(current_item)
                        if inventory.sorted then
                            if self.item_current_selecting > #inventory then
                                self.item_current_selecting = self.item_current_selecting - 1
                            end
                            if self.item_current_selecting == 0 then
                                self:setState("SELLMENU", true)
                            end
                        end
                    elseif self.current_selecting_choice == 2 then
                        self:setRightText(self.sell_refuse_text)
                    else
                        self:setRightText("What?????[wait:5]\ndid you\ndo????")
                    end
                elseif Input.isCancel(key) then
                    self.sell_confirming = false
                    Game.key_repeat = true
                    self:setRightText(self.sell_refuse_text)
                elseif Input.is("up", key) or Input.is("down", key) then
                    if self.current_selecting_choice == 1 then
                        self.current_selecting_choice = 2
                    else
                        self.current_selecting_choice = 1
                    end
                end
            else
                if Input.isConfirm(key) and not is_repeat then
                    if inventory[self.item_current_selecting] then
                        if inventory[self.item_current_selecting]:isSellable() then
                            self.sell_confirming = true
                            Game.key_repeat = false
                            self.current_selecting_choice = 1
                            self:setRightText("")
                        else
                            self:setRightText(self.sell_no_price_text)
                        end
                    else
                        self:setRightText(self.sell_nothing_text)
                    end
                elseif Input.isCancel(key) and not is_repeat then
                    self:setState("SELLMENU")
                elseif Input.is("up", key) then
                    self.item_current_selecting = self.item_current_selecting - 1
                    if (self.item_current_selecting <= 0) then
                        self.item_current_selecting = 1
                    end
                elseif Input.is("down", key) then
                    local max = inventory.max
                    if inventory.sorted then
                        max = #inventory
                    end
                    self.item_current_selecting = self.item_current_selecting + 1
                    if (self.item_current_selecting > max) then
                        self.item_current_selecting = max
                    end
                end
            end
        else
            if Input.isConfirm(key) or Input.isCancel(key) then
                self:setState("MAINMENU")
            end
        end
    elseif self.state == "TALKMENU" then
        if Input.isConfirm(key) then
            if (self.current_selecting <= #self.talks) then
                local talk = self.talks[self.current_selecting]
                self:setFlag("talk_" .. self.current_selecting, true)
                self:startTalk(talk[1])
            elseif self.current_selecting == math.max(4, #self.talks) + 1 then
                self:setState("MAINMENU")
            end
        elseif Input.isCancel(key) then
            self:setState("MAINMENU")
        elseif Input.is("up", key) then
            self.current_selecting = self.current_selecting - 1
            if (self.current_selecting <= 0) then
                self.current_selecting = math.max(4, #self.talks) + 1
            end
        elseif Input.is("down", key) then
            self.current_selecting = self.current_selecting + 1
            if (self.current_selecting > math.max(4, #self.talks) + 1) then
                self.current_selecting = 1
            end
        end
    end
end

function LightShop:enterSellMenu(sell_data)
    if not sell_data then
        self:setRightText(self.sell_no_storage_text)
    elseif not Game.inventory:getStorage(sell_data[2]) then
        self:setRightText(self.sell_no_storage_text)
    elseif Game.inventory:getItemCount(sell_data[2], false) == 0 then
        self:setRightText(self.sell_no_storage_text)
    else
        self:setState("SELLING", sell_data)
    end
end

function LightShop:buyItem(current_item)
    if (current_item.options["price"] or 0) > self:getMoney() then
        self:setRightText(self.buy_too_expensive_text)
    else
        -- PURCHASE THE ITEM
        -- Remove the gold
        self:removeMoney(current_item.options["price"] or 0)

        -- Decrement the stock
        if current_item.options["stock"] then
            current_item.options["stock"] = current_item.options["stock"] - 1
            self:setFlag(current_item.options["flag"], current_item.options["stock"])
        end

        -- Add the item to the inventory
        local new_item = Registry.createItem(current_item.item.id)
        new_item:load(current_item.item:save())
        if Game.inventory:addItem(new_item) then
            -- Visual/auditorial feedback (did I spell that right?)
            Assets.playSound("locker")
            self:setRightText(self.buy_text)
        else
            -- Not enough space, oops
            self:setRightText(self.buy_no_space_text)
        end
    end
end

function LightShop:setFlag(name, value)
    Game:setFlag("shop#" .. self.id .. ":" .. name, value)
end

function LightShop:getFlag(name, default)
    return Game:getFlag("shop#" .. self.id .. ":" .. name, default)
end

function LightShop:sellItem(current_item)
    -- SELL THE ITEM
    -- Add the gold
    self:addMoney(current_item:getSellPrice())
    Game.inventory:removeItem(current_item)

    Assets.playSound("locker")
    self:setRightText(self.sell_text)
end

function LightShop:getMoney()
    return Game:isLight() and Game.lw_money or Game.money
end

function LightShop:setMoney(amount)
    if Game:isLight() then
        Game.lw_money = amount
    else
        Game.money = amount
    end
end

function LightShop:addMoney(amount)
    self:setMoney(self:getMoney() + amount)
end

function LightShop:removeMoney(amount)
    self:setMoney(self:getMoney() - amount)
end

return LightShop