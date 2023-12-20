local AceGUI = LibStub("AceGUI-3.0")

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- Mage Mode Functions
function MageVendor:SetToMageMode()
    self.MageFrame:SetHeight(300)
    self.ContainerFrame:SetHeight(275)
    self.UserFrame:Hide()
    self.MageFrame:Show()
    self.ToggleButton:SetText("User Mode")
    self:UpdateLists()
    self:OnRequestAvailableMages()
end

function MageVendor:CreateUserRequestFrames()
    -- Create the frames for the user requests, max of 40
    for i = 1, 40 do
        local requestFrame =
            CreateFrame(
            "Frame",
            "MageVendorAllRequests" .. i .. "Request",
            self.AllRequestsScrollContainer,
            "MageVendorUserItem"
        )
        requestFrame:SetPoint("RIGHT", self.AllRequestsScrollContainer, "RIGHT", 0, 0)
        requestFrame:SetPoint("TOPLEFT", self.AllRequestsScrollContainer, "TOPLEFT", 10, 0)
        requestFrame:Hide()

        table.insert(self.requestFrames, requestFrame)
    end
end

function MageVendor:CreatePersonalRequestFrames()
    -- Create the frames for the user requests, max of 40
    for i = 1, 40 do
        local requestFrame =
            CreateFrame(
            "Frame",
            "MageVendorPersonalRequests" .. i .. "Request",
            self.PersonalRequestsScrollContainer,
            "MageVendorUserItem_Individual"
        )
        requestFrame:SetPoint("RIGHT", self.PersonalRequestsScrollContainer, "RIGHT", 0, 0)
        requestFrame:SetPoint("TOPLEFT", self.PersonalRequestsScrollContainer, "TOPLEFT", 10, 0)
        requestFrame:Hide()

        table.insert(self.personalRequestFrames, requestFrame)
    end
end

function MageVendor:UpdateLists()
    self:HideAllRequestFrames()
    self:CreateRequestList()
    self:CreatePersonalRequestList()  
end

function MageVendor:HideAllRequestFrames()
    for i = 1, 40 do
        self.requestFrames[i]:Hide()
        self.requestFrames[i]:SetPoint("TOPLEFT", self.AllRequestsScrollContainer, "TOPLEFT", 10, 0);

        self.personalRequestFrames[i]:Hide()
        self.personalRequestFrames[i]:SetPoint("TOPLEFT", self.PersonalRequestsScrollContainer, "TOPLEFT", 10, 0);
    end
end

function MageVendor:CreateRequestList()
    -- Create available requests
    local addedHeight = 0;
    for i, request in ipairs(self.availableRequests) do
        local requestFrame = self.requestFrames[i]
        requestFrame:Show()
        requestFrame:SetPoint("TOPLEFT", self.AllRequestsScrollContainer, "TOPLEFT", 10, -addedHeight)
        local nameFrame = _G[requestFrame:GetName() .. "UserName"]
        local foodFrame = _G[requestFrame:GetName() .. "FoodRequest"]
        local waterFrame = _G[requestFrame:GetName() .. "WaterRequest"]
        local acceptButton = _G[requestFrame:GetName() .. "CheckButton"]
        local cancelButton = _G[requestFrame:GetName() .. "CancelButton"]

        acceptButton:SetChecked(false)

        nameFrame:SetText(request["sender"])

        if(tonumber(request["food"]) == 0) then
            foodFrame:Hide()
        else
            foodFrame:Show()
        end

        if(tonumber(request["water"]) == 0) then
            waterFrame:Hide()
        else
            waterFrame:Show()
        end

        if(tonumber(request["food"]) == 1) then
            foodFrame:SetText("Food: "..request["food"].." stack")
        else
            foodFrame:SetText("Food: "..request["food"].." stacks")
        end

        if(tonumber(request["water"]) == 1) then
            waterFrame:SetText("Water: "..request["water"].." stack")
        else
            waterFrame:SetText("Water: "..request["water"].." stacks")
        end

        acceptButton:SetScript(
            "OnClick",
            function()
                MageVendor:MageAcceptRequest(request)
            end
        )

        cancelButton:SetScript(
            "OnClick",
            function()
                MageVendor:MageCancelRequest(request)
            end
        )

        addedHeight = addedHeight + 55
    end
end

function MageVendor:CreatePersonalRequestList()
    -- Create available requests
    local addedHeight = 0;
    for i, request in ipairs(self.personalRequests) do
        local requestFrame = self.personalRequestFrames[i]
        requestFrame:Show()
        requestFrame:SetPoint("TOPLEFT", self.PersonalRequestsScrollContainer, "TOPLEFT", 10, -addedHeight)
        local nameFrame = _G[requestFrame:GetName() .. "UserName"]
        local foodFrame = _G[requestFrame:GetName() .. "FoodRequest"]
        local waterFrame = _G[requestFrame:GetName() .. "WaterRequest"]
        local cancelButton = _G[requestFrame:GetName() .. "CancelButton"]
        local completeButton = _G[requestFrame:GetName() .. "CompleteButton"]

        nameFrame:SetText(request["sender"])
        
        if(tonumber(request["food"]) == 0) then
            foodFrame:Hide()
        else
            foodFrame:Show()
        end

        if(tonumber(request["water"]) == 0) then
            waterFrame:Hide()
        else
            waterFrame:Show()
        end

        if(tonumber(request["food"]) == 1) then
            foodFrame:SetText("Food: "..request["food"].." stack")
        else
            foodFrame:SetText("Food: "..request["food"].." stacks")
        end

        if(tonumber(request["water"]) == 1) then
            waterFrame:SetText("Water: "..request["water"].." stack")
        else
            waterFrame:SetText("Water: "..request["water"].." stacks")
        end

        cancelButton:SetScript(
            "OnClick",
            function()
                MageVendor:MageCancelRequest(request)
            end
        )

        completeButton:SetScript(
            "OnClick",
            function()
                MageVendor:MageCompleteRequest(request)
            end
        )

        addedHeight = addedHeight + 55
    end
end

function MageVendor:MageAcceptRequest(request)
    --remove the request from the available requests
    for i, availableRequest in ipairs(self.availableRequests) do
        if(availableRequest["sender"] == request["sender"]) then
            table.remove(self.availableRequests, i)
            break
        end
    end
    --add the request to the personal requests
    table.insert(self.personalRequests, request)

    self:UpdateLists()
    --send that this request was accepted
    local channel = self:GetChannel()
    MageVendor:SendCommMessage("MV_AcceptedReq", request["sender"], channel)

    --Send to the person that requested that their request was accepted
    MageVendor:SendCommMessage("MV_MageAccepted", self.characterName, "WHISPER", request["sender"])
    
end

function MageVendor:OnMageVendorAcceptedRequest(prefix, message, distribution, sender)
    for i, request in ipairs(self.availableRequests) do
        if(request["sender"] == message) then
            table.remove(self.availableRequests, i)
            break
        end
    end
    self:UpdateLists()
end

function MageVendor:MageCancelRequest(request)
    --Let the sender know that we are cancelling their request
    local channel = self:GetChannel()
    MageVendor:SendCommMessage("MV_CancelReq", request["sender"], channel)

    MageVendor:SendCommMessage("MV_MageCanceled", self.characterName, "WHISPER", request["sender"])

    --Remove the request from the personal requests
    for i, personalRequest in ipairs(self.personalRequests) do
        if(personalRequest["sender"] == request["sender"]) then
            table.remove(self.personalRequests, i)
            break
        end
    end
    --Remove the request from the available requests
    for i, availableRequest in ipairs(self.availableRequests) do
        if(availableRequest["sender"] == request["sender"]) then
            table.remove(self.availableRequests, i)
            break
        end
    end

    self:UpdateLists()
end

function MageVendor:OnMageVendorCancelRequest(prefix, message, distribution, sender)
    for i, request in ipairs(self.availableRequests) do
        if(request["sender"] == message) then
            table.remove(self.availableRequests, i)
            break
        end
    end
    for i, personalRequest in ipairs(self.personalRequests) do
        if(personalRequest["sender"] == message) then
            table.remove(self.personalRequests, i)
            break
        end
    end

    self:UpdateLists()
end

function MageVendor:MageCompleteRequest(request)
    --Let the sender know that we have completed their request
    MageVendor:SendCommMessage("MV_MageCompleted", self.characterName, "WHISPER", request["sender"])

    for i, personalRequest in ipairs(self.personalRequests) do
        if(personalRequest["sender"] == request["sender"]) then
            table.remove(self.personalRequests, i)
            break
        end
    end

    self:UpdateLists()
end

-- REQUESTS

function MageVendor:OnMageVendorRequestFoodAndWater(prefix, message, distribution, sender)
    --Check if the sender already exists in our requests table
    for i, request in ipairs(self.availableRequests) do
        if(request["sender"] == sender) then
            --If the number of food and water requested is zero, we should remove the request
            if(message == "0,0") then
                table.remove(self.availableRequests, i)
                self:UpdateLists()
                return
            end
            --Update the request
            local requestedAmounts = split(message, ",") 
            request["food"] = requestedAmounts[1]
            request["water"] = requestedAmounts[2]
            self:UpdateLists()
            return
        end
    end

    for i, request in ipairs(self.personalRequests) do
        if(request["sender"] == sender) then
            --If the number of food and water requested is zero, we should remove the request
            if(message == "0,0") then
                table.remove(self.personalRequests, i)
                self:UpdateLists()
                return
            end
            --Update the request
            local requestedAmounts = split(message, ",") 
            request["food"] = requestedAmounts[1]
            request["water"] = requestedAmounts[2]
            self:UpdateLists()
            return
        end
    end
    
    --Someone is requesting food and water, message is number of stacks requested
    local requestedAmounts = split(message, ",") 

    if(tonumber(requestedAmounts[1]) == 0 and tonumber(requestedAmounts[2]) == 0) then
        return
    end

    local request = {}

    request["sender"] = sender
    request["food"] = requestedAmounts[1]
    request["water"] = requestedAmounts[2]
    request["accepted"] = false

    table.insert(self.availableRequests, request)

    MageVendor:Print("Received request from " .. sender)

    self:UpdateLists()
end