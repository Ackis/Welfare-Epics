--[[
****************************************************************************************
Welfare Epics
$Date: 2008-09-12 22:48:11 -0600 (Fri, 12 Sep 2008) $
$Rev: 71 $

Author: Ackis on Illidan US Horde

****************************************************************************************

Please see Wowace.com for more information.

****************************************************************************************
]]


local L			= LibStub("AceLocale-3.0"):GetLocale("Welfare Epics")

WelfareEpics	= LibStub("AceAddon-3.0"):NewAddon("Welfare Epics", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

local addon = WelfareEpics

local GetMerchantItemLink = GetMerchantItemLink
local GetMerchantItemInfo = GetMerchantItemInfo

-- Returns main description configuration

local function giveOptions()

	local options =
	{
		desc =
		{
			order = 1,
			type = "description",
			name = L["FILTER_OPTIONS"] .. "\n",
		},
	}

	return options

end

-- Returns configuration options for profiling

local function giveProfiles()

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
	return profiles

end

-- Returns configuraion options for filter

local function giveFilter()

	local filter =
	{
		desc =
		{
			order = 1,
			type = "description",
			name = L["FILTER_OPTIONS"] .. "\n",
		},
		usable =
		{
			name	= L["Usable"],
			desc	= L["USABLE_TOGGLE"],
			type	= "toggle",
			get		= function() return addon.db.profile.usable end,
			set		= function() addon.db.profile.usable = not addon.db.profile.usable end,
			order	= 2,
		},
		cloth =
		{
			name	= L["Cloth"],
			desc	= L["CLOTH_TOGGLE"],
			type	= "toggle",
			get		= function() return addon.db.profile.cloth end,
			set		= function() addon.db.profile.cloth = not addon.db.profile.cloth end,
			order	= 3,
		},
		leather =
		{
			name	= L["Leather"],
			desc	= L["LEATHER_TOGGLE"],
			type	= "toggle",
			get		= function() return addon.db.profile.leather end,
			set		= function() addon.db.profile.leather = not addon.db.profile.leather end,
			order	= 4,
		},
		mail =
		{
			name	= L["Mail"],
			desc	= L["MAIL_TOGGLE"],
			type	= "toggle",
			get		= function() return addon.db.profile.mail end,
			set		= function() addon.db.profile.mail = not addon.db.profile.mail end,
			order	= 4,
		},
		plate =
		{
			name	= L["Plate"],
			desc	= L["PLATE_TOGGLE"],
			type	= "toggle",
			get		= function() return addon.db.profile.plate end,
			set		= function() addon.db.profile.plate = not addon.db.profile.plate end,
			order	= 4,
		},
	}

	return filter

end

-- Register slash commands and profile defaults

function addon:OnInitialize()

	local AceConfigReg = LibStub("AceConfigRegistry-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	self.db = LibStub("AceDB-3.0"):New("WelfareEpicsDB", defaults, "char")

	-- Create the options with Ace3
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Welfare Epics",giveOptions)
	AceConfigReg:RegisterOptionsTable("Welfare Epics Filter",giveFilter)
	AceConfigReg:RegisterOptionsTable("Welfare Epics Profile",giveProfiles)

	-- Add the options to blizzard frame (add them backwards so they show up in the proper order
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("Welfare Epics","Welfare Epics")
	self.optionsFrame[L["About"]] = LibStub("LibAboutPanel").new("Welfare Epics", "Welfare Epics")
	self.optionsFrame[L["Filter"]] = AceConfigDialog:AddToBlizOptions("Welfare Epics Filter", L["Filter"], "Welfare Epics")
	self.optionsFrame[L["Profile"]] = AceConfigDialog:AddToBlizOptions("Welfare Epics Profile", L["Profile"], "Welfare Epics")

	-- Register slash commands
	self:RegisterChatCommand("welfareepics", "ChatCommand")

	-- Set default options, which are to include everything in the scan
	self.db:RegisterDefaults(
		{ profile =
			{
			-- Filter Options
		    usable = true,
			}
		}
	)

end

-- Register events and hooks

function addon:OnEnable()

	-- Register events
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")

	-- Replace the entire MerchantFrame_Update Function, this will taint stuffz
	self:RawHook("MerchantFrame_Update", "MerchantFrame_Update", true)
	-- Hook into MerchantItem Button clicks so we can deal with the new tabs we have
	self:SecureHook("MerchantItemButton_OnClick")
	self:SecureHook("MerchantItemButton_OnModifiedClick")
	self:SecureHook("MerchantItemButton_OnEnter")

	self:Print("This mod is unstable.  Please don't it until there is a forum post.  All items which you cannot use are filtered from vendors.  Thank you, Ackis")

end

-- Scans the vendor list adding item indexes to a local table

function addon:MERCHANT_SHOW()

	-- Parse all the items on the vendor
	self:ParseItems()
	-- Display the Usable items only to start with
	self:AddFilteredMerchantItems("Usable")
	-- Add drop-down menus
	self:AddDropDownMenu()

end

-- Nils out the tables used to free up memory

function addon:MERCHANT_CLOSED()

	self:ResetTables()

end

do

	-- All the categories 
	local tabcategories = {"Usable", "Armor", "Weapon", "Other"}
	tabcategories["Armor"] = {"Cloth","Leather","Mail","Plate","Trinket","Other Armor"}
	tabcategories["Weapon"] = {"Axe", "Dagger", "Mace", "Staff", "Sword", "Wand", "Ranged"}
	tabcategories["Other"] = {"Tradeskill"}

	-- Create look up tables for tabs and indexes
	local lookuptable = {}
	local reverselookuptable = {}

	-- List of indexes of all items availible to the vendor
	local merchantlist = {}

	-- Creates emtpy table space for us to use

	function addon:CreateTables()
		-- Make sure our tables are created
		-- Create empty table spaces
		for _,i in ipairs(tabcategories) do
			if (not merchantlist[i]) then
				merchantlist[i] = {}
			end
			for _,j in ipairs(tabcategories[i]) do
				if (not merchantlist[j]) then
					merchantlist[j] = {}
				end
			end
		end
	end

	-- Empties the table space

	function addon:ResetTables()

		-- Reset the type tables
		for _,i in ipairs(tabcategories) do
			for _,j in ipairs(tabcategories[i]) do
				merchantlist[j] = nil
			end
			merchantlist[i] = nil
		end

	end

	-- Scans the availible items at a vendor, adding the usable ones to a list and scanning the other items and addit them to appropiate lists

	function addon:ParseItems()

		self:CreateTables()

		local numMerchantItems = GetMerchantNumItems()

		for i=1,numMerchantItems,1 do
			-- See if the item is usable or not
			local name, _, _, _, _, isUsable = GetMerchantItemInfo(i)
			-- Scan the item link to determine what type of item we are dealing with
			local itemtype,category,classtype = addon:ScanLink(GetMerchantItemLink(i))

			-- Add the item to the sub-category table
			table.insert(merchantlist[itemtype],i)
			-- Add the item to the category table
			table.insert(merchantlist[category],i)
			-- Get a list of usable items
			if isUsable then
				table.insert(usablevendoritems,i)
			end
		end

	end

	-- Populates a vendor tab with the appropiate items

	function addon:AddFilteredMerchantItems(filtertype)

		MerchantNameText:SetText(UnitName("NPC"))
		SetPortraitTexture(MerchantFramePortrait, "NPC")

		local numMerchantItems = #merchantlist[filtertype]

		self:SetPagingText(numMerchantItems)

		for i=1, MERCHANT_ITEMS_PER_PAGE, 1 do
			local vendorcount = (i + ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE))
			local index = merchantlist[filtertype][vendorcount]
			-- If we're at empty spots (ie: no items to display) add an empty item
			if vendorcount > numMerchantItems then
				self:AddBlankVendorItem(i)
			-- If we still have items to display, add that items
			else
				self:AddMerchantItem(index,i,numMerchantItems)
			end
		end

		self:HandleBlizzStuff()
		self:HandlePages(numMerchantItems)
		self:SetupMerchantFrame()

	end

	-- Scans a given item link outputting the type of Armor/weapon it is, and what type of piece (melee, caster, healer, tank)

	function addon:ScanLink(link)

		local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)
		--ScanItemLink
		if (itemType == "Armor") then
			if (itemSubType == "Cloth") then
				return itemSubType,itemType,"Caster DPS"
			elseif (itemSubType == "Leather") then
				return itemSubType,itemType,"Caster DPS"
			elseif (itemSubType == "Mail") then
				return itemSubType,itemType,"Caster DPS"
			elseif (itemSubType == "Plate") then
				return itemSubType,itemType,"Caster DPS"
			elseif (itemSubType == "Miscellaneous") then
				if (itemEquipLoc == "INVTYPE_TRINKET") then
					return "Trinket",itemType,"Caster DPS"
				else
					return "Other Armor",itemType,"Caster DPS"
				end
			else
				return "Other Armor",itemType,"Caster DPS"
			end
		elseif (itemType == "Weapon") then
			return "Weapon",itemType,"Caster DPS"
		else
			return "Other","Other","Caster DPS"
		end

	end
	
	-- Adds items to the Merchant frame

	function addon:MerchantFrame_Update()

		-- If we're on the main tab, hide everything we can't use
		if (MerchantFrame.selectedTab == 1) then
			self:HideUnusable()
		-- If we're on the buyback tab, display the buy back stuff
		elseif (MerchantFrame.selectedTab == 2) then
			MerchantFrame_UpdateBuybackInfo()
		end

	end

	-- Code borrowed from thoaky

	function addon:AddDropDownMenu()
--http://ace.pastey.net/94768
		-- Create the first drop down menu
		local info = UIDropDownMenu_CreateInfo()

		for name, c in pairs(tabcategories) do
			info.text = name
			info.value = name
			info.func = addon.ChangeDropdown
			info.checked = nil
			UIDropDownMenu_AddButton(info, 1)
		end

	end

end

function addon:ChangeDropdown() 

	self:Print("Whee")
	--UIDropDownMenu_SetSelectedValue(AltoholicTabCharacters_SelectChar, self.value)

end  

-- Blizzard functions to set up the Merchant Frame

function addon:SetupMerchantFrame()

	-- Show all merchant related items
	MerchantBuyBackItem:Show()
	MerchantFrameBottomLeftBorder:Show()
	MerchantFrameBottomRightBorder:Show()
	 
	-- Hide buyback related items
	MerchantItem11:Hide()
	MerchantItem12:Hide()
	BuybackFrameTopLeft:Hide()
	BuybackFrameTopRight:Hide()
	BuybackFrameBotLeft:Hide()
	BuybackFrameBotRight:Hide()
	 
	-- Position merchant items
	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -8)
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -8)
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -8)
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -8)

end

-- Sets the number of pages for each merchant window

function addon:SetPagingText(numMerchantItems)

	MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, MerchantFrame.page, math.ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE))

end

-- Adds blank item to vendor

function addon:AddBlankVendorItem(VendorItemLocation)

	local merchantButton = getglobal("MerchantItem"..VendorItemLocation)
	local itemButton = getglobal("MerchantItem"..VendorItemLocation.."ItemButton")

	itemButton.hasItem = nil
	itemButton:Hide()
	SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5)
	SetItemButtonSlotVertexColor(merchantButton,0.4, 0.4, 0.4)
	getglobal("MerchantItem"..VendorItemLocation.."Name"):SetText("")
	getglobal("MerchantItem"..VendorItemLocation.."MoneyFrame"):Hide()
	getglobal("MerchantItem"..VendorItemLocation.."AltCurrencyFrame"):Hide()

end

-- The reamining code that blizzard has, deals with buybacks and paging buttons

function addon:HandleBlizzStuff()

	-- Handle repair items
	MerchantFrame_UpdateRepairButtons()
	 
	-- Handle vendor buy back item
	local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable = GetBuybackItemInfo(GetNumBuybackItems())
	if (buybackName) then
		MerchantBuyBackItemName:SetText(buybackName)
		SetItemButtonCount(MerchantBuyBackItemItemButton, buybackQuantity)
		SetItemButtonStock(MerchantBuyBackItemItemButton, buybackNumAvailable)
		SetItemButtonTexture(MerchantBuyBackItemItemButton, buybackTexture)
		MerchantBuyBackItemMoneyFrame:Show()
		MoneyFrame_Update("MerchantBuyBackItemMoneyFrame", buybackPrice)
		MerchantBuyBackItem:Show()
	 
	else
		MerchantBuyBackItemName:SetText("")
		MerchantBuyBackItemMoneyFrame:Hide()
		SetItemButtonTexture(MerchantBuyBackItemItemButton, "")
		SetItemButtonCount(MerchantBuyBackItemItemButton, 0)
	-- Hide the tooltip upon sale
		if (GameTooltip:IsOwned(MerchantBuyBackItemItemButton)) then
			GameTooltip:Hide()
		end
	end

end

-- Updates the page numbers

function addon:HandlePages(numMerchantItems)
	-- Handle paging buttons
	if (numMerchantItems > MERCHANT_ITEMS_PER_PAGE) then
		if (MerchantFrame.page == 1) then
			MerchantPrevPageButton:Disable()
		else
			MerchantPrevPageButton:Enable()
		end
		if (MerchantFrame.page == ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE) or numMerchantItems == 0) then
			MerchantNextPageButton:Disable()
		else
			MerchantNextPageButton:Enable()
		end
		MerchantPageText:Show()
		MerchantPrevPageButton:Show()
		MerchantNextPageButton:Show()
	else
		MerchantPageText:Hide()
		MerchantPrevPageButton:Hide()
		MerchantNextPageButton:Hide()
	end
end

-- Adds an item to the vendor.  It is venodr ID VendorItemIndex and put into location VendorItemLocation

function addon:AddMerchantItem(VendorItemIndex,VendorItemLocation,numMerchantItems)

	local name, texture, price, quantity, numAvailable, isUsable, extendedCost

	local itemButton = getglobal("MerchantItem"..VendorItemLocation.."ItemButton")
	local merchantButton = getglobal("MerchantItem"..VendorItemLocation)
	local merchantMoney = getglobal("MerchantItem"..VendorItemLocation.."MoneyFrame")

	local merchantAltCurrency = getglobal("MerchantItem"..VendorItemLocation.."AltCurrencyFrame")

	name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(VendorItemIndex)
	getglobal("MerchantItem"..VendorItemLocation.."Name"):SetText(name)
	SetItemButtonCount(itemButton, quantity)
	SetItemButtonStock(itemButton, numAvailable)
	SetItemButtonTexture(itemButton, texture)

	if (extendedCost and (price <= 0)) then
		itemButton.extendedCost = true
		itemButton.link = GetMerchantItemLink(VendorItemIndex)
		itemButton.texture = texture
		MerchantFrame_UpdateAltCurrency(VendorItemIndex, VendorItemLocation)
		merchantAltCurrency:ClearAllPoints()
		merchantAltCurrency:SetPoint("BOTTOMLEFT", "MerchantItem"..VendorItemLocation.."NameFrame", "BOTTOMLEFT", 0, 31)
		merchantMoney:Hide()
		merchantAltCurrency:Show()
	elseif (extendedCost and (price > 0)) then
		itemButton.extendedCost = true
		itemButton.link = GetMerchantItemLink(VendorItemIndex)
		itemButton.texture = texture
		MerchantFrame_UpdateAltCurrency(VendorItemIndex, VendorItemLocation)
		MoneyFrame_Update(merchantMoney:GetName(), price)
		merchantAltCurrency:ClearAllPoints()
		merchantAltCurrency:SetPoint("LEFT", merchantMoney:GetName(), "RIGHT", -14, 0)
		merchantAltCurrency:Show()
		merchantMoney:Show()
	else
		itemButton.extendedCost = nil
		MoneyFrame_Update(merchantMoney:GetName(), price)
		merchantAltCurrency:Hide()
		merchantMoney:Show()
	end

	itemButton.hasItem = true
	itemButton:SetID(VendorItemIndex)
	itemButton:Show()

	if (numAvailable == 0) then
		-- If not available and not usable
		if (not isUsable) then
			SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0)
			SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0)
			SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0)
			SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0)
		else
			SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5)
			SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5)
			SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5)
			SetItemButtonNormalTextureVertexColor(itemButton,0.5, 0.5, 0.5)
		end
		elseif (not isUsable) then
		SetItemButtonNameFrameVertexColor(merchantButton, 1.0, 0, 0)
		SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0)
		SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0)
		SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0)
	else
		SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5)
		SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0)
		SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
		SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
	end

end

function addon:MerchantItemButton_OnClick(self, button)
	MerchantFrame.extendedCost = nil
 
	if (MerchantFrame.selectedTab > 2) then
		-- Is merchant frame
		if (button == "LeftButton") then
			PickupMerchantItem(self:GetID())
			if (self.extendedCost) then
				MerchantFrame.extendedCost = self
			end
		else
			if (self.extendedCost) then
				MerchantFrame_ConfirmExtendedItemCost(self)
			else
				BuyMerchantItem(self:GetID())
			end
		end
	end
end
 
function addon:MerchantItemButton_OnModifiedClick(self, button)
	if (MerchantFrame.selectedTab > 2) then
		-- Is merchant frame
		if ( HandleModifiedItemClick(GetMerchantItemLink(self:GetID())) ) then
			return;
		end
		if ( IsModifiedClick("SPLITSTACK") ) then
			local maxStack = GetMerchantItemMaxStack(self:GetID())
			if ( maxStack > 1 ) then
				if ( price and (price > 0) ) then
					local canAfford = floor(GetMoney() / price)
					if ( canAfford < maxStack ) then
						maxStack = canAfford
					end
				end
				OpenStackSplitFrame(maxStack, self, "BOTTOMLEFT", "TOPLEFT")
			end
			return
		end
	end
end
 
function addon:MerchantItemButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	if (MerchantFrame.selectedTab > 2) then
		GameTooltip:SetMerchantItem(button:GetID())
		GameTooltip_ShowCompareItem()
		MerchantFrame.itemHover = button:GetID()
		GameTooltip:Show()
	end
end

--tooltip:SetOwner() and CursorUpdate(Self)