local AceGUI = LibStub("AceGUI-3.0")

function MageVendor:SetToUserMode()
    self.MageFrame:SetHeight(200)
    self.ContainerFrame:SetHeight(175)
    self.MageFrame:Hide()
    self.UserFrame:Show()
    self.ToggleButton:SetText("Mage Mode")

    self:OnRequestAvailableMages()
end

function MageVendor:RequestFoodAndWater(food, water)
    --If we don't have any mages, don't send the request
    if(#MageVendor.availableMages == 0) then
        MageVendor:Print("No mages available to fulfill your request.")
        return
    end

    local channel = MageVendor:GetChannel()
    MageVendor:SendCommMessage("MV_ReqFoodWater", food .. "," .. water, channel)

    self.StatusText:SetText("Request sent.")
end

function MageVendor:OnMageVendorMageAvailable(prefix, message, distribution, sender)
    --Check if the sender is already in the list, if not add them
    for i, name in ipairs(self.availableMages) do
        if(name == sender) then
            return
        end
    end
    table.insert(self.availableMages, sender)

    self:UpdateStatus()
end

function MageVendor:OnMageVendorMageUnavailable(prefix, message, distribution, sender)
    for i, name in ipairs(self.availableMages) do
        if(name == sender) then
            table.remove(self.availableMages, i)
        end
    end

    self:UpdateStatus()
end

function MageVendor:OnMageVendorMageAcceptedRequest(prefix, message, distribution, sender)
    MageVendor:Print(sender .. " has accepted your request.")
    self.StatusText:SetText(sender .. " has accepted your request.")
end

function MageVendor:OnMageVendorMageCanceledRequest(prefix, message, distribution, sender)
    MageVendor:Print(sender .. " has canceled your request.")
    self:UpdateStatus()
end

function MageVendor:OnMageVendorMageCompletedRequest(prefix, message, distribution, sender)
    MageVendor:Print(sender .. " has completed your request.")
    self:UpdateStatus()
end