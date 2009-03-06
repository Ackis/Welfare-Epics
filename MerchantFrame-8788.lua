--3.0.1.8788/FrameXML/MerchantFrame.lua

MERCHANT_ITEMS_PER_PAGE = 10;
BUYBACK_ITEMS_PER_PAGE = 12;
MAX_ITEM_COST = 3;
 
function MerchantFrame_OnLoad(self)
	self:RegisterEvent("MERCHANT_UPDATE");
	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("MERCHANT_SHOW");
	self:RegisterEvent("GUILDBANK_UPDATE_MONEY");
	self:RegisterForDrag("LeftButton");
	self.page = 1;
	-- Tab Handling code
	PanelTemplates_SetNumTabs(self, 2);
	PanelTemplates_SetTab(self, 1);
end
 
function MerchantFrame_OnEvent(self, event, ...)
	if ( event == "MERCHANT_UPDATE" ) then
		if ( self:IsVisible() ) then
			MerchantFrame_Update();
		end
	elseif ( event == "MERCHANT_CLOSED" ) then
		HideUIPanel(self);
	elseif ( event == "MERCHANT_SHOW" ) then
		ShowUIPanel(self);
		if ( not self:IsShown() ) then
			CloseMerchant();
			return;
		end
		self.page = 1;
		MerchantFrame_Update();
	elseif ( event == "PLAYER_MONEY" or event == "GUILDBANK_UPDATE_MONEY" or event == "GUILDBANK_UPDATE_WITHDRAWMONEY" ) then
		MerchantFrame_UpdateCanRepairAll();
		MerchantFrame_UpdateRepairButtons();
	end
end
 
function MerchantFrame_OnShow()
	OpenBackpack();
	-- Update repair all button status
	MerchantFrame_UpdateCanRepairAll();
	MerchantFrame_UpdateGuildBankRepair();
	PanelTemplates_SetTab(MerchantFrame, 1);
	MerchantFrame_Update();
end
 
function MerchantFrame_OnHide()
	CloseMerchant();
	CloseBackpack();
	ResetCursor();
 
	StaticPopup_Hide("CONFIRM_PURCHASE_TOKEN_ITEM");
end
 
function MerchantFrame_Update()
	if ( MerchantFrame.selectedTab == 1 ) then
		MerchantFrame_UpdateMerchantInfo();
	else
		MerchantFrame_UpdateBuybackInfo();
	end
 
end
 
function MerchantFrame_UpdateMerchantInfo()
	MerchantNameText:SetText(UnitName("NPC"));
	SetPortraitTexture(MerchantFramePortrait, "NPC");
 
	local numMerchantItems = GetMerchantNumItems();
 
	MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, MerchantFrame.page, math.ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE));
 
	local name, texture, price, quantity, numAvailable, isUsable, extendedCost;
	for i=1, MERCHANT_ITEMS_PER_PAGE, 1 do
		local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i);
		local itemButton = getglobal("MerchantItem"..i.."ItemButton");
		local merchantButton = getglobal("MerchantItem"..i);
		local merchantMoney = getglobal("MerchantItem"..i.."MoneyFrame");
		local merchantAltCurrency = getglobal("MerchantItem"..i.."AltCurrencyFrame");
		if ( index <= numMerchantItems ) then
			name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(index);
			getglobal("MerchantItem"..i.."Name"):SetText(name);
			SetItemButtonCount(itemButton, quantity);
			SetItemButtonStock(itemButton, numAvailable);
			SetItemButtonTexture(itemButton, texture);
 
			if ( extendedCost and (price <= 0) ) then
				itemButton.extendedCost = true;
				itemButton.link = GetMerchantItemLink(index);
				itemButton.texture = texture;
				MerchantFrame_UpdateAltCurrency(index, i);
				merchantAltCurrency:ClearAllPoints();
				merchantAltCurrency:SetPoint("BOTTOMLEFT", "MerchantItem"..i.."NameFrame", "BOTTOMLEFT", 0, 31);
				merchantMoney:Hide();
				merchantAltCurrency:Show();
			elseif ( extendedCost and (price > 0) ) then
				itemButton.extendedCost = true;
				itemButton.link = GetMerchantItemLink(index);
				itemButton.texture = texture;
				MerchantFrame_UpdateAltCurrency(index, i);
				MoneyFrame_Update(merchantMoney:GetName(), price);
				merchantAltCurrency:ClearAllPoints();
				merchantAltCurrency:SetPoint("LEFT", merchantMoney:GetName(), "RIGHT", -14, 0);
				merchantAltCurrency:Show();
				merchantMoney:Show();
			else
				itemButton.extendedCost = nil;
				MoneyFrame_Update(merchantMoney:GetName(), price);
				merchantAltCurrency:Hide();
				merchantMoney:Show();
			end
 
			itemButton.hasItem = true;
			itemButton:SetID(index);
			itemButton:Show();
			if ( numAvailable == 0 ) then
				-- If not available and not usable
				if ( not isUsable ) then
					SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0);
					SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
					SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
				else
					SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
					SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
					SetItemButtonNormalTextureVertexColor(itemButton,0.5, 0.5, 0.5);
				end
 
			elseif ( not isUsable ) then
				SetItemButtonNameFrameVertexColor(merchantButton, 1.0, 0, 0);
				SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0);
				SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0);
				SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0);
			else
				SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
				SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0);
				SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
				SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
			end
		else
			itemButton.hasItem = nil;
			itemButton:Hide();
			SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
			SetItemButtonSlotVertexColor(merchantButton,0.4, 0.4, 0.4);
			getglobal("MerchantItem"..i.."Name"):SetText("");
			getglobal("MerchantItem"..i.."MoneyFrame"):Hide();
			getglobal("MerchantItem"..i.."AltCurrencyFrame"):Hide();
		end
	end
 
	-- Handle repair items
	MerchantFrame_UpdateRepairButtons();
 
	-- Handle vendor buy back item
	local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable = GetBuybackItemInfo(GetNumBuybackItems());
	if ( buybackName ) then
		MerchantBuyBackItemName:SetText(buybackName);
		SetItemButtonCount(MerchantBuyBackItemItemButton, buybackQuantity);
		SetItemButtonStock(MerchantBuyBackItemItemButton, buybackNumAvailable);
		SetItemButtonTexture(MerchantBuyBackItemItemButton, buybackTexture);
		MerchantBuyBackItemMoneyFrame:Show();
		MoneyFrame_Update("MerchantBuyBackItemMoneyFrame", buybackPrice);
		MerchantBuyBackItem:Show();
 
	else
		MerchantBuyBackItemName:SetText("");
		MerchantBuyBackItemMoneyFrame:Hide();
		SetItemButtonTexture(MerchantBuyBackItemItemButton, "");
		SetItemButtonCount(MerchantBuyBackItemItemButton, 0);
		-- Hide the tooltip upon sale
		if ( GameTooltip:IsOwned(MerchantBuyBackItemItemButton) ) then
			GameTooltip:Hide();
		end
	end
 
	-- Handle paging buttons
	if ( numMerchantItems > MERCHANT_ITEMS_PER_PAGE ) then
		if ( MerchantFrame.page == 1 ) then
			MerchantPrevPageButton:Disable();
		else
			MerchantPrevPageButton:Enable();
		end
		if ( MerchantFrame.page == ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE) or numMerchantItems == 0) then
			MerchantNextPageButton:Disable();
		else
			MerchantNextPageButton:Enable();
		end
		MerchantPageText:Show();
		MerchantPrevPageButton:Show();
		MerchantNextPageButton:Show();
	else
		MerchantPageText:Hide();
		MerchantPrevPageButton:Hide();
		MerchantNextPageButton:Hide();
	end
 
	-- Show all merchant related items
	MerchantBuyBackItem:Show();
	MerchantFrameBottomLeftBorder:Show();
	MerchantFrameBottomRightBorder:Show();
 
	-- Hide buyback related items
	MerchantItem11:Hide();
	MerchantItem12:Hide();
	BuybackFrameTopLeft:Hide();
	BuybackFrameTopRight:Hide();
	BuybackFrameBotLeft:Hide();
	BuybackFrameBotRight:Hide();
 
	-- Position merchant items
	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -8);
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -8);
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -8);
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -8);
end
 
function MerchantFrame_UpdateAltCurrency(index, i)
	local itemTexture, itemValue, pointsTexture, button;
	local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(index);
	local frameName = "MerchantItem"..i.."AltCurrencyFrame";
	button = getglobal(frameName.."Points");
	-- update Alt Currency Frame with pointsValues
	if ( honorPoints and honorPoints ~= 0 ) then
		local factionGroup = UnitFactionGroup("player");
		if ( factionGroup ) then
			pointsTexture = "Interface\\TargetingFrame\\UI-PVP-"..factionGroup;
		end
		button.pointType = HONOR_POINTS;
		AltCurrencyFrame_Update(frameName.."Points", pointsTexture, honorPoints);
		button:Show();
	elseif ( arenaPoints and arenaPoints ~= 0 ) then
		button.pointType = ARENA_POINTS;
		AltCurrencyFrame_Update(frameName.."Points", "Interface\\PVPFrame\\PVP-ArenaPoints-Icon", arenaPoints);
		button:Show();
	else
		button:Hide();
	end
 
	-- update Alt Currency Frame with itemValues
	if ( itemCount > 0 ) then
		for i=1, MAX_ITEM_COST, 1 do
			button = getglobal(frameName.."Item"..i);
			button.index = index;
			button.item = i;
 
			itemTexture, itemValue, button.itemLink = GetMerchantItemCostItem(index, i);
 
			AltCurrencyFrame_Update(frameName.."Item"..i, itemTexture, itemValue);
			-- Anchor items based on how many item costs there are.
 
			if ( i > 1 ) then
				button:SetPoint("LEFT", frameName.."Item"..i-1, "RIGHT", 4, 0);
			elseif ( i == 1 and ( arenaPoints and honorPoints == 0 ) ) then
				button:SetPoint("LEFT", frameName.."Points", "LEFT", 0, 0);
			else
				button:SetPoint("LEFT", frameName.."Points", "RIGHT", 4, 0);
			end
			if ( not itemTexture ) then
				button:Hide();
			else
				button:Show();
			end
		end
	else
		for i=1, MAX_ITEM_COST, 1 do
			getglobal(frameName.."Item"..i):Hide();
		end
	end
end
 
function MerchantFrame_UpdateBuybackInfo()
	MerchantNameText:SetText(MERCHANT_BUYBACK);
	MerchantFramePortrait:SetTexture("Interface\\MerchantFrame\\UI-BuyBack-Icon");
 
	-- Show Buyback specific items
	MerchantItem11:Show();
	MerchantItem12:Show();
	BuybackFrameTopLeft:Show();
	BuybackFrameTopRight:Show();
	BuybackFrameBotLeft:Show();
	BuybackFrameBotRight:Show();
 
	-- Position buyback items
	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -15);
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -15);
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -15);
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -15);
 
	local numBuybackItems = GetNumBuybackItems();
	local itemButton, buybackButton;
	local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable;
	for i=1, BUYBACK_ITEMS_PER_PAGE do
		itemButton = getglobal("MerchantItem"..i.."ItemButton");
		buybackButton = getglobal("MerchantItem"..i);
		getglobal("MerchantItem"..i.."AltCurrencyFrame"):Hide();
		if ( i <= numBuybackItems ) then
			buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable = GetBuybackItemInfo(i);
			getglobal("MerchantItem"..i.."Name"):SetText(buybackName);
			SetItemButtonCount(itemButton, buybackQuantity);
			SetItemButtonStock(itemButton, buybackNumAvailable);
			SetItemButtonTexture(itemButton, buybackTexture);
			getglobal("MerchantItem"..i.."MoneyFrame"):Show();
			MoneyFrame_Update("MerchantItem"..i.."MoneyFrame", buybackPrice);
			itemButton:SetID(i);
			itemButton:Show();
			if ( numAvailable == 0 ) then
				-- If not available and not usable
				if ( not buybackIsUsable ) then
					SetItemButtonNameFrameVertexColor(buybackButton, 0.5, 0, 0);
					SetItemButtonSlotVertexColor(buybackButton, 0.5, 0, 0);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
					SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
				else
					SetItemButtonNameFrameVertexColor(buybackButton, 0.5, 0.5, 0.5);
					SetItemButtonSlotVertexColor(buybackButton, 0.5, 0.5, 0.5);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
					SetItemButtonNormalTextureVertexColor(itemButton,0.5, 0.5, 0.5);
				end
 
			elseif ( not buybackIsUsable ) then
				SetItemButtonNameFrameVertexColor(buybackButton, 1.0, 0, 0);
				SetItemButtonSlotVertexColor(buybackButton, 1.0, 0, 0);
				SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0);
				SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0);
			else
				SetItemButtonNameFrameVertexColor(buybackButton, 0.5, 0.5, 0.5);
				SetItemButtonSlotVertexColor(buybackButton, 1.0, 1.0, 1.0);
				SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
				SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
			end
		else
			SetItemButtonNameFrameVertexColor(buybackButton, 0.5, 0.5, 0.5);
			SetItemButtonSlotVertexColor(buybackButton,0.4, 0.4, 0.4);
			getglobal("MerchantItem"..i.."Name"):SetText("");
			getglobal("MerchantItem"..i.."MoneyFrame"):Hide();
			itemButton:Hide();
		end
	end
 
	-- Hide all merchant related items
	MerchantRepairAllButton:Hide();
	MerchantRepairItemButton:Hide();
	MerchantBuyBackItem:Hide();
	MerchantPrevPageButton:Hide();
	MerchantNextPageButton:Hide();
	MerchantFrameBottomLeftBorder:Hide();
	MerchantFrameBottomRightBorder:Hide();
	MerchantRepairText:Hide();
	MerchantPageText:Hide();
	MerchantGuildBankRepairButton:Hide();
end
 
function MerchantPrevPageButton_OnClick()
	PlaySound("igMainMenuOptionCheckBoxOn");
	MerchantFrame.page = MerchantFrame.page - 1;
	MerchantFrame_Update();
end
 
function MerchantNextPageButton_OnClick()
	PlaySound("igMainMenuOptionCheckBoxOn");
	MerchantFrame.page = MerchantFrame.page + 1;
	MerchantFrame_Update();
end
 
function MerchantItemBuybackButton_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp","RightButtonUp");
	self:RegisterForDrag("LeftButton");
 
	self.SplitStack = function(button, split)
		if ( split > 0 ) then
			BuyMerchantItem(button:GetID(), split);
		end
	end
end
 
function MerchantItemButton_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp","RightButtonUp");
	self:RegisterForDrag("LeftButton");
 
	self.SplitStack = function(button, split)
		if ( button.extendedCost ) then
			MerchantFrame_ConfirmExtendedItemCost(button, split)
		elseif ( split > 0 ) then
			BuyMerchantItem(button:GetID(), split);
		end
	end
 
	self.UpdateTooltip = MerchantItemButton_OnEnter;
end
 
function MerchantItemButton_OnClick(self, button)
	MerchantFrame.extendedCost = nil;
 
	if ( MerchantFrame.selectedTab == 1 ) then
		-- Is merchant frame
		if ( button == "LeftButton" ) then
			PickupMerchantItem(self:GetID());
			if ( self.extendedCost ) then
				MerchantFrame.extendedCost = self;
			end
		else
			if ( self.extendedCost ) then
				MerchantFrame_ConfirmExtendedItemCost(self);
			else
				BuyMerchantItem(self:GetID());
			end
		end
	else
		-- Is buyback item
		BuybackItem(self:GetID());
	end
end
 
function MerchantItemButton_OnModifiedClick(self, button)
	if ( MerchantFrame.selectedTab == 1 ) then
		-- Is merchant frame
		if ( HandleModifiedItemClick(GetMerchantItemLink(self:GetID())) ) then
			return;
		end
		if ( IsModifiedClick("SPLITSTACK") ) then
			local maxStack = GetMerchantItemMaxStack(self:GetID());
			if ( maxStack > 1 ) then
				if ( price and (price > 0) ) then
					local canAfford = floor(GetMoney() / price);
					if ( canAfford < maxStack ) then
						maxStack = canAfford;
					end
				end
				OpenStackSplitFrame(maxStack, self, "BOTTOMLEFT", "TOPLEFT");
			end
			return;
		end
	else
		HandleModifiedItemClick(GetBuybackItemLink(self:GetID()));
	end
end
 
function MerchantItemButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
	if ( MerchantFrame.selectedTab == 1 ) then
		GameTooltip:SetMerchantItem(button:GetID());
		GameTooltip_ShowCompareItem();
		MerchantFrame.itemHover = button:GetID();
	else
		GameTooltip:SetBuybackItem(button:GetID());
		if ( IsModifiedClick("DRESSUP") and button.hasItem ) then
			ShowInspectCursor();
		else
			ShowBuybackSellCursor(button:GetID());
		end
	end
end
 
LIST_DELIMITER = ", "
 
function MerchantFrame_ConfirmExtendedItemCost(itemButton, quantity)
	quantity = (quantity or 1);
	local index = itemButton:GetID();
	local itemTexture, itemLink, itemsString;
	local pointsTexture, button;
	local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(index);
	if ( (honorPoints == 0) and (arenaPoints == 0) and (itemCount == 0) ) then
		BuyMerchantItem( itemButton:GetID(), quantity );
		return;
	end
 
	local count = itemButton.count or 1;
	honorPoints, arenaPoints, itemCount = (honorPoints or 0) * quantity, (arenaPoints or 0) * quantity, (itemCount or 0) * quantity;
 
	if ( honorPoints and honorPoints ~= 0 ) then
		local factionGroup = UnitFactionGroup("player");
		if ( factionGroup ) then
			pointsTexture = "Interface\\PVPFrame\\PVP-Currency-"..factionGroup;
			itemsString = " |T" .. pointsTexture .. ":0:0:0:-1|t" ..  honorPoints .. " " .. HONOR_POINTS;
		end
	elseif ( arenaPoints and arenaPoints ~= 0 ) then
		itemsString = " |TInterface\\PVPFrame\\PVP-ArenaPoints-Icon:0:0:0:-1|t" .. arenaPoints .. " " .. ARENA_POINTS;
	end
 
	local maxQuality = 0;
	for i=1, MAX_ITEM_COST, 1 do
		itemTexture, itemCount, itemLink = GetMerchantItemCostItem(index, i);
		if ( itemLink ) then
			local _, _, itemQuality = GetItemInfo(itemLink);
			maxQuality = math.max(itemQuality, maxQuality);
			if ( itemsString ) then
				itemsString = itemsString .. LIST_DELIMITER .. format(ITEM_QUANTITY_TEMPLATE, (itemCount or 0) * quantity, itemLink);
			else
				itemsString = format(ITEM_QUANTITY_TEMPLATE, (itemCount or 0) * quantity, itemLink);
			end
		end
	end
 
	if ( honorPoints == 0 and arenaPoints == 0 and maxQuality <= ITEM_QUALITY_UNCOMMON ) then
		BuyMerchantItem( itemButton:GetID(), quantity );
		return;
	end
 
	MerchantFrame.itemIndex = index;
	MerchantFrame.count = quantity;
 
	local itemName, _, itemQuality = GetItemInfo(itemButton.link);
	local r, g, b = GetItemQualityColor(itemQuality);
	StaticPopup_Show("CONFIRM_PURCHASE_TOKEN_ITEM", itemsString, "", {["texture"] = itemButton.texture, ["name"] = itemName, ["color"] = {r, g, b, 1}, ["link"] = itemButton.link, ["index"] = index, ["count"] = count * quantity});
end
 
function MerchantFrame_UpdateCanRepairAll()
	if ( MerchantRepairAllIcon ) then
		local repairAllCost, canRepair = GetRepairAllCost();
		if ( canRepair ) then
			SetDesaturation(MerchantRepairAllIcon, nil);
			MerchantRepairAllButton:Enable();
		else
			SetDesaturation(MerchantRepairAllIcon, 1);
			MerchantRepairAllButton:Disable();
		end
	end
end
 
function MerchantFrame_UpdateGuildBankRepair()
	local repairAllCost, canRepair = GetRepairAllCost();
	if ( canRepair ) then
		SetDesaturation(MerchantGuildBankRepairButtonIcon, nil);
		MerchantGuildBankRepairButton:Enable();
	else
		SetDesaturation(MerchantGuildBankRepairButtonIcon, 1);
		MerchantGuildBankRepairButton:Disable();
	end
end
 
function MerchantFrame_UpdateRepairButtons()
	if ( CanMerchantRepair() ) then
		--See if can guildbank repair
		if ( CanGuildBankRepair() ) then
			MerchantRepairAllButton:SetWidth(32);
			MerchantRepairAllButton:SetHeight(32);
			MerchantRepairItemButton:SetWidth(32);
			MerchantRepairItemButton:SetHeight(32);
			MerchantRepairItemButton:SetPoint("RIGHT", MerchantRepairAllButton, "LEFT", -4, 0);
 
			MerchantRepairAllButton:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 115, 89);
			MerchantRepairText:ClearAllPoints();
			MerchantRepairText:SetPoint("CENTER", MerchantFrame, "BOTTOMLEFT", 97, 129);
			MerchantGuildBankRepairButton:Show();
		else
			MerchantRepairAllButton:SetWidth(36);
			MerchantRepairAllButton:SetHeight(36);
			MerchantRepairItemButton:SetWidth(36);
			MerchantRepairItemButton:SetHeight(36);
			MerchantRepairItemButton:SetPoint("RIGHT", MerchantRepairAllButton, "LEFT", -2, 0);
 
			MerchantRepairAllButton:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 172, 91);
			MerchantRepairText:ClearAllPoints();
			MerchantRepairText:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 26, 103);
			MerchantGuildBankRepairButton:Hide();
		end
		MerchantRepairText:Show();
		MerchantRepairAllButton:Show();
		MerchantRepairItemButton:Show();
	else
		MerchantRepairText:Hide();
		MerchantRepairAllButton:Hide();
		MerchantRepairItemButton:Hide();
		MerchantGuildBankRepairButton:Hide();
	end
end
