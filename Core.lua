MageVendor = LibStub("AceAddon-3.0"):NewAddon("MageVendor", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceBucket-3.0")
local AceGUI = LibStub("AceGUI-3.0")

function MageVendor:OnInitialize()
    self.version = "0.0.1"
    self.db = LibStub("AceDB-3.0"):New("MageVendorDB", MAGE_VENDOR_DEFAULT_VALUES, true)
    self.opt = self.db.profile
    self.options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MageVendor", self.options, {"mv"})
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MageVendor", "Mage Vendor")

    self.MinimapIcon = LibStub("LibDBIcon-1.0")

    local localClass, class = UnitClass("player")
    local name, realm = UnitName("player")

    self.characterName = name
    self.class = class
    self.requestFrames = {}
    self.personalRequestFrames = {}
    self.personalRequests = {}
    self.availableRequests = {}
    self.availableMages = {}
    self.inQueue = false
    self.queuePosition = 0
    self.mode = "USER"

    --Frames
    self.MageVendorFrame = _G["MageVendorMainFrame"]
    self.ContainerFrame = _G["MageVendorMainContainerFrame"]
    self.MageFrame = _G["MageVendorMageContainerFrame"]
    self.UserFrame = _G["MageVendorUserContainerFrame"]
    self.ToggleButton = _G["MageVendorToggleButton"]
    self.StatusText = _G["MageVendorStatus"]
    self.AllRequestsScrollContainer = _G["AllRequestsScrollChild"]
    self.PersonalRequestsScrollContainer = _G["PersonalRequestsScrollChild"]

    if(self.class == "MAGE") then
        self.mode = "MAGE"
        self.ToggleButton:Show()
        self:RegisterComm("MV_ReqFoodWater", "OnMageVendorRequestFoodAndWater")
        self:CreateUserRequestFrames()
        self:CreatePersonalRequestFrames()
        self:SetToMageMode()
        if(self.opt.availableRequests == nil) then
            self.opt.availableRequests = {}
        end
        if(self.opt.personalRequests == nil) then
            self.opt.personalRequests = {}
        end
        self.availableRequests = self.opt.availableRequests
        self.personalRequests = self.opt.personalRequests
        self:UpdateLists()
        self:Update() 
    end

    self:RegisterComm("MV_MageAvail", "OnMageVendorMageAvailable")
    self:RegisterComm("MV_MageUnavail", "OnMageVendorMageUnavailable")
    self:RegisterComm("MV_AvailMages", "OnRequestAvailableMages")
    self:RegisterComm("MV_AcceptedReq", "OnMageVendorAcceptedRequest")
    self:RegisterComm("MV_MageAccepted", "OnMageVendorMageAcceptedRequest")

    self:RegisterComm("MV_CancelReq", "OnMageVendorCancelRequest")
    self:RegisterComm("MV_MageCanceled", "OnMageVendorMageCanceledRequest")
    self:RegisterComm("MV_MageCompleted", "OnMageVendorMageCompletedRequest")

    self:RegisterChatCommand("mv", "SlashCommand")

    if BackdropTemplateMixin then
        Mixin(self.MageVendorFrame, BackdropTemplateMixin)
    end

    self.LibDataBroker =
        LibStub("LibDataBroker-1.1"):NewDataObject(
        "MageVendor",
        {
            ["type"] = "data source",
            ["text"] = "Mage Vendor",
            ["icon"] = "Interface\\Icons\\Ability_mage_conjurefoodrank10",
            ["OnTooltipShow"] = function(tooltip)
            
                    tooltip:SetText("Mage Vendor")
                    tooltip:AddLine("Request Food from your resident mage!", 0, 1, 0)
                    tooltip:AddDoubleLine("Left Click", "Toggle MageVendor", 0, 1, 0, 1, 1, 1)
                    tooltip:AddDoubleLine("Right Click", "Open Options", 0, 1, 0, 1, 1, 1)
                    tooltip:Show()
           
            end,
            ["OnClick"] = function(_, button)
                if (button == "LeftButton") then
                    self:FrameToggle()
                else
                    self:OpenOptions()
                end
            end
        }
    )

    self.MinimapIcon:Register("MageVendor", self.LibDataBroker, self.opt.minimap)

    local channel = self:GetChannel()
    self:SendCommMessage("MV_AvailMages", self.name, channel)

    self: MageVendorFrameToggle()
    MageVendor:Print("Mage Vendor "..self.version.." by Yva-Wild Growth (SoD)")
end

function MageVendor:SlashCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(MageVendor, "mv", "MageVendor", input)
    end
end

function MageVendor:OnEnable()
    -- Called when the addon is enabled
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("GROUP_LEFT")
    self:RegisterBucketEvent("PLAYER_ENTERING_WORLD", 2, "PLAYER_ENTERING_WORLD")
end

function MageVendor:PLAYER_ENTERING_WORLD()
    self:RegisterBucketEvent(
        {
            "GROUP_ROSTER_UPDATE",
            "RAID_ROSTER_UPDATE"
        },
        1,
        "Update"
    )
end

function MageVendor:GetChannel()
    if(UnitInBattleground("player")) then
        return "BATTLEGROUND"
    elseif(IsInRaid()) then
        return "RAID"
    else
        return "PARTY"
    end
end

function MageVendor:Update()
    if(self.class == "MAGE") then
        local channel = self:GetChannel()

        if(self.mode == "MAGE") then
            self:SendCommMessage("MV_MageAvail", self.name, channel)
        else
            self:SendCommMessage("MV_MageUnavail", self.name, channel)
        end
    end
end

function MageVendor:GROUP_JOINED()
    C_Timer.After(
        2.0,
        function()
            self:Update()
        end
    )
end

function MageVendor:GROUP_LEFT()
    C_Timer.After(
        2.0,
        function()
            self:Update()
        end
    )
end



function MageVendor:DragStart()
    self.MageVendorFrame:StartMoving()
end

function MageVendor:DragStop()
    self.MageVendorFrame:StopMovingOrSizing()
end

function MageVendor:FrameToggle()
    if self.MageVendorFrame:IsShown() then
        self.opt.frameVisible = false
    else
        self.opt.frameVisible = true
    end
    self:MageVendorFrameToggle()
end

function MageVendor:MageVendorFrameToggle()
    if (MageVendor.opt.frameVisible == false) then
        self.MageVendorFrame:Hide()
    else
        self.MageVendorFrame:Show()
    end
end

function MageVendor:MageVendorMinimapIconToggle()
    if (MageVendor.opt.minimap.show == false) then
        MageVendor.MinimapIcon:Hide("MageVendor")
    else
        MageVendor.MinimapIcon:Show("MageVendor")
    end
end

function MageVendor:BtnClose()
    self.opt.frameVisible = false
    self:MageVendorFrameToggle()
end

function MageVendor:FoodSliderValueChanged(slider, value)
    --MageVendor.options.foodAmount = value
    local foodRequestText = _G["FoodRequestText_Text"]
    if(value == 1 and foodRequestText ~= nil) then
        foodRequestText:SetText("1 Stack")
    else
        foodRequestText:SetText(value .. " Stacks")
    end
   
end

function MageVendor:WaterSliderValueChanged(slider, value)
    --MageVendor.options.waterAmount = value
    local waterRequestText = _G["WaterRequestText_Text"]
    if(value == 1 and waterRequestText ~= nil) then
        waterRequestText:SetText("1 Stack")
    else
        waterRequestText:SetText(value .. " Stacks")
    end
   
end

function MageVendor:ToggleMode()
    if(self.mode == "USER") then
        self.mode = "MAGE"
        self:SetToMageMode()
    else
        self.mode = "USER"
        self:SetToUserMode()
    end

end



function MageVendor:OnRequestAvailableMages()
    if(self.class == "MAGE") then
        local channel = self:GetChannel()

        if(self.mode == "MAGE") then
            self:SendCommMessage("MV_MageAvail", self.name, channel)
        else
            self:SendCommMessage("MV_MageUnavail", self.name, channel)
        end
    end
end



function MageVendor:CancelButtonClick()
end

function MageVendor:UpdateStatus()
    if(self.mode == "USER") then
        --Check if we have any mages available
        if(#self.availableMages > 0) then
            --List the mages available
            local mages = ""
            --Only add a comma if we have more than one mage
            if(#self.availableMages > 1) then
                mages = "Mages Available: "
                for i, name in ipairs(self.availableMages) do
                    mages = mages .. name .. ", "
                end
            else
                mages = "Mage Available: " .. self.availableMages[1]
            end

            self.StatusText:SetText(mages)
        else
            self.StatusText:SetText("No Mages Available")
        end
    end
end

function MageVendor:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open("MageVendor")
end