MageVendor.options = {
    name = " " .. "MageVendor",
    type = "group",
    childGroups = "tab",
    args = {
        settings = {
            order = 1,
            name = "Settings",
            desc = "Change global settings",
            type = "group",
            cmdHidden = true,
            args = {
                showminimapicon = {
                    order = 1,
                    name = "Show Minimap Icon",
                    desc = "[Show/Hide] Minimap Icon",
                    type = "toggle",
                    width = 1.0,
                    get = function(info)
                        return MageVendor.opt.minimap.show
                    end,
                    set = function(info, value)
                        MageVendor.opt.minimap.show = value
                        MageVendor:MageVendorMinimapIconToggle()
                    end
                },
                showframe = {
                    order = 2,
                    name = "Show Window",
                    desc = "[Show/Hide] Buff Manager Window",
                    type = "toggle",
                    width = 1.0,
                    get = function(info)
                        return MageVendor.opt.frameVisible
                    end,
                    set = function(info, value)
                        MageVendor.opt.frameVisible = value
                        MageVendor:MageVendorFrameToggle()
                    end
                },
            }
        }
    }
}