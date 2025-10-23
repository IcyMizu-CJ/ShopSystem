local ShopFrame = {}

local rf = game.ReplicatedStorage.ShopItems.RemoteFunction
local remotes2 = game.ReplicatedStorage.ShopItems.RemoteEvent2

ShopFrame.__index = ShopFrame

type self = {
	Frame: Instance,
	Name: string,
	Item: string,
	Description: string,
	Category: string,
	Subcat: string,
	Image: string,
	typeofprice: string,
	price: string,
	onsale: boolean,
}

export type ShopFrame = typeof(setmetatable({} :: self, ShopFrame))

function CheckIfEquipped(name, cat, subcat)
	local plr = game:GetService("Players").LocalPlayer
	local check = rf:InvokeServer("E", name, cat, subcat)
	return check
end

function CheckIfOwned(name, cat, subcat)
	local plr = game:GetService("Players").LocalPlayer
	local check = rf:InvokeServer("O", name, cat, subcat)
	return check
end

function emotesequip(item)
	local returnemotes = rf:InvokeServer("ReturnEmotes")
	local info = require(game.ReplicatedStorage.ShopItems.ItemInfo)

	local plr = game:GetService("Players").LocalPlayer
	local gui = plr:WaitForChild("PlayerGui"):WaitForChild("ShopGui").Frame.Buttons.EmotesEquip

	local concs = {}
	for i, v in pairs(gui:GetChildren()) do
		if v:IsA("Frame") then
			if returnemotes[v.Name] then
				local name
				for i2, v2 in pairs(info.Emotes) do
					for i3, v3 in pairs(v2) do
						if i3 == returnemotes[v.Name] then
							name = v3.Name
						end
					end
				end
				v.TextLabel.Text = v.Name .. ". " .. name
			else
				v.TextLabel.Text = "None"
			end
			local a
			a = v.TextButton.MouseButton1Click:Connect(function()
				remotes2:FireServer("EquipEmote", tonumber(v.Name), item)
				gui.Visible = false
				gui.Parent.Parent.Frames.Buy.Text = "Equipped"
			end)
			table.insert(concs, a)
			local b
			b = gui.Changed:Connect(function(w)
				if w == "Visible" then
					if gui.Visible == false then
						for i, v in pairs(concs) do
							v:Disconnect()
						end
						b:Disconnect()
					end
				end
			end)
		end
	end
end

function ShopFrame.new(item, description, image, typeofprice, price, category, subcat, Name, onsale, ugc) -- the reason for this many variables is because its looping trough the items in a different script and passing the itemsinfo trough the params
	local self = {} :: self
	self.Name = Name
	self.Frame = game.ReplicatedStorage.ShopItems.Frame:Clone()
	self.Item = item
	self.Description = description
	self.Image = image
	self.Category = category
	self.Subcat = subcat
	self.typeofprice = typeofprice
	self.price = price
	self.Equipped = CheckIfEquipped(self.Item, self.Category, self.Subcat)
	self.Owned = CheckIfOwned(self.Item, self.Category, self.Subcat)
	self.UGC = ugc
	setmetatable(self, ShopFrame)

	local plr = game:GetService("Players").LocalPlayer
	local gui = plr:WaitForChild("PlayerGui"):WaitForChild("ShopGui").Frame.Frames
	if onsale or self.Owned then
		self.Frame.Parent = gui[self.Category][self.Subcat]
		self.Frame.Title.Text = self.Name
		self.Frame.ItemImage.Image = self.Image
	else
		return nil
	end

	return self
end

function ShopFrame:ClickButton()
	local plr = game:GetService("Players").LocalPlayer
	local gui = plr:WaitForChild("PlayerGui"):WaitForChild("ShopGui").Frame.Frames
	local mp = game:GetService("MarketplaceService")
	local badge = game:GetService("BadgeService")
	local group = game:GetService("GroupService")
	gui.Parent.Buttons.EmotesEquip.Visible = false

	local function returntypeofpricetext(typeofprice, price)
		if typeofprice == "Money" then
			return "Buy for: " .. price .. "$"
		elseif typeofprice == "Gamepass" then
			return "Need to own gamepass: " .. mp:GetProductInfo(price, Enum.InfoType.GamePass).Name
		elseif typeofprice == "Group" then
			return "Need to be part of group: " .. group:GetGroupInfoAsync(price).Name
		elseif typeofprice == "Badge" then
			return "Need to own badge: " .. badge:GetBadgeInfoAsync(price).Name
		end
		return "R$"
	end

	self.Frame.ItemImage.MouseButton1Click:Connect(function()
		gui.ViewportFrame.Visible = false
		gui.ugc.Visible = false
		if gui.ViewportFrame.WorldModel.BaseModel.Humanoid.Animator:FindFirstChild("Animation") then
			gui.ViewportFrame.WorldModel.BaseModel.Humanoid.Animator:FindFirstChild("Animation"):Destroy()
		end

		self.Equipped = CheckIfEquipped(self.Item, self.Category, self.Subcat)
		self.Owned = CheckIfOwned(self.Item, self.Category, self.Subcat)

		gui.Selected.Value = self.Item

		gui.Title.Text = self.Name
		gui.Desc.Text = self.Description
		gui.ImageL.Image = self.Image

		if self.UGC ~= false then
			gui.ugc.Visible = true
		end

		if self.Category == "Emotes" then
			local anim = Instance.new("Animation")
			anim.Parent = gui.ViewportFrame.WorldModel.BaseModel.Humanoid.Animator
			gui.ViewportFrame.Visible = true
			anim.AnimationId = "rbxassetid://" .. self.Item
			local track = gui.ViewportFrame.WorldModel.BaseModel.Humanoid.Animator:LoadAnimation(anim)
			local playtracks = gui.ViewportFrame.WorldModel.BaseModel.Humanoid:GetPlayingAnimationTracks()
			for i, v in pairs(playtracks) do
				v:Stop()
			end
			track:Play()
		end
		if self.Owned == false then
			gui.Buy.Text = returntypeofpricetext(self.typeofprice, self.price)
		elseif self.Owned == true and self.Equipped == false then
			gui.Buy.Text = "Equip"
		else
			if self.Equipped == true then
				gui.Buy.Text = "Equipped"
			end
			if self.Category == "Morphs" then
				gui.Buy.Text = "UnEquip"
			end
		end
	end)
end

function ShopFrame:ugcBuy(db)
	local plr = game:GetService("Players").LocalPlayer
	if db then
		local ms = game:GetService("MarketplaceService")
		db = false
		task.spawn(function()
			task.wait(1)
			db = true
		end)
		ms:PromptPurchase(plr, self.UGC)
	end
end

function ShopFrame:Buy(db)
	local plr = game:GetService("Players").LocalPlayer
	local gui = plr:WaitForChild("PlayerGui"):WaitForChild("ShopGui").Frame.Frames
	self.Equipped = CheckIfEquipped(self.Item, self.Category, self.Subcat)
	self.Owned = CheckIfOwned(self.Item, self.Category, self.Subcat)
	if db then
		db = false
		task.spawn(function()
			task.wait(1)
			db = true
		end)
		if gui.Selected.Value == self.Item then
			if self.Owned == false then
				local check, text =
					rf:InvokeServer("AddItem", self.Item, self.Category, self.Subcat, self.typeofprice, self.price)
				if check then
					self.Owned = CheckIfOwned(self.Item, self.Category, self.Subcat)
					gui.Buy.Text = "Equip"
					local sound
					if game.Workspace:FindFirstChild("Chaching") == nil then
						sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://7847573603"
						sound.Name = "Chaching"
						sound.Parent = game.Workspace
					else
						sound = game.Workspace:FindFirstChild("Chaching")
					end
					sound:Play()
				else
					local a = game.ReplicatedStorage.ShopItems.ErrorText:Clone()
					a.Text = text
					a.Parent = gui.Parent.Parent.ErrorFrame
					local sound
					if game.Workspace:FindFirstChild("error") == nil then
						sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://8400918001"
						sound.Name = "error"
						sound.Parent = game.Workspace
					else
						sound = game.Workspace:FindFirstChild("error")
					end
					sound:Play()
					task.spawn(function()
						task.wait(1)
						for i = 0, 1, 0.1 do
							task.wait()
							a.TextTransparency = i
						end
						task.wait(1)
						a:Destroy()
					end)
				end
			elseif self.Owned == true and self.Equipped == false then
				if self.Category ~= "Emotes" then
					remotes2:FireServer("EquipItem", self.Item, self.Category, self.Subcat)
					gui.Buy.Text = "Equipped"
				else
					emotesequip(self.Item)
					gui.Parent.Buttons.EmotesEquip.Visible = true
				end
				if self.Category == "Morphs" then
					gui.Buy.Text = "UnEquip"
				end
			elseif self.Owned == true and self.Equipped == true then
				if self.Category == "Morphs" then
					gui.Buy.Text = "Equip"
					remotes2:FireServer("UnEquipItem", self.Category)
				end
			end
		end
	end
end

function ShopFrame:OwnedButton()
	local plr = game:GetService("Players").LocalPlayer
	local gui = plr:WaitForChild("PlayerGui"):WaitForChild("ShopGui").Frame.Buttons
	local db = true
	gui.Toggle.MouseButton1Click:Connect(function()
		print("Toggled")
		if db == true then
			db = false
			task.spawn(function()
				task.wait(0.2)
				db = true
			end)
			if gui.Toggle:GetAttribute("Toggled") == false and self.Owned == false then
				self.Frame.Visible = false
				gui.Toggle.Text = "X"
				task.spawn(function()
					task.wait(0.5)
					gui.Toggle:SetAttribute("Toggled", true)
				end)
			elseif gui.Toggle:GetAttribute("Toggled") == true then
				self.Frame.Visible = true
				gui.Toggle.Text = ""
				task.spawn(function()
					task.wait(0.5)
					gui.Toggle:SetAttribute("Toggled", false)
				end)
			end
		end
	end)
end

return ShopFrame
