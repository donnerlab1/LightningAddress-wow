local _, ADDONSELF = ...

LightningAddress = LibStub("AceAddon-3.0"):NewAddon("LightningAddress", "AceConsole-3.0", "AceComm-3.0")


local options = {
    name = "LightningAddress",
    handler = LightningAddress,
    type = 'group',
    args = {
        msg = {
            type = 'input',
            name = 'Lightning Address',
            desc = 'Set your LightningAddress Lightning Address',
            set = 'SetMyLightningAddress',
            get = 'GetMyLightningAddress',
        },
    },
}


function LightningAddress:GetMyLightningAddress(info)
    return self.db.global.lightningaddress
end

function LightningAddress:SetMyLightningAddress(info, input)
    self.db.global.lightningaddress = input
end

function LightningAddress:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LightningAddressDB")
    LibStub("AceConfig-3.0"):RegisterOptionsTable("LightningAddress", options, {"la", "la2"})
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LightningAddress", "LightningAddress")
    LightningAddress:Print("LightningAddressDB initialized")
    LightningAddress:RegisterComm("lightningaddress")
end

local qrcode = ADDONSELF.qrcode

local BLOCK_SIZE = 5

local bdInfo = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true,
    tileEdge = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },    
}

local function CreateQRTip(qrsize, name)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f.backdropInfo = bdInfo
    f:ApplyBackdrop()
    f:SetBackdropColor(1, 1, 1, 1);

    local function CreateBlock(idx)
        local t = CreateFrame("Frame", nil, f)

        t:SetWidth(BLOCK_SIZE)
        t:SetHeight(BLOCK_SIZE)
        t.texture = t:CreateTexture(nil, "OVERLAY")
        t.texture:SetAllPoints(t)

        local x = (idx % qrsize) * BLOCK_SIZE
        local y = (math.floor(idx / qrsize)) * BLOCK_SIZE

        t:SetPoint("TOPLEFT", f, 20 + x, - 20 - y);

        return t
    end


    do
        f:SetFrameStrata("BACKGROUND")
        f:SetWidth(qrsize * BLOCK_SIZE + 40)
        f:SetHeight(qrsize * BLOCK_SIZE + 40)
        f:SetMovable(true)
        f:EnableMouse(true)
        


        f:SetPoint("CENTER", 0, 0)
        f:RegisterForDrag("LeftButton") 
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    end

    do
        local b = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        b:SetPoint("TOPRIGHT", f, 0, 0);
    end

    f.boxes = {}

    f.SetBlack = function(idx)
        f.boxes[idx].texture:SetColorTexture(0, 0, 0)
    end

    f.SetWhite = function(idx)
        f.boxes[idx].texture:SetColorTexture(1, 1, 1)
    end

    for i = 1, qrsize * qrsize do
        tinsert(f.boxes, CreateBlock(i - 1))
    end

    return f
end

LightningAddress:RegisterChatCommand("qrcode", "OpenQrCode")

function LightningAddress:OpenQrCode(msg)
  -- Process the slash command ('input' contains whatever follows the slash command)
  local ok, tab_or_message = qrcode(msg, 4)
    if not ok then
        print(tab_or_message)
    else
        local tab = tab_or_message
        local size = #tab

        local f = CreateQRTip(size)
        f:Show()

        for x = 1, #tab do
            for y = 1, #tab do

                if tab[x][y] > 0 then
                    f.SetBlack((y - 1) * size + x - 1 + 1)
                else
                    f.SetWhite((y - 1) * size + x - 1 + 1)
                end
            end
        end
    end
end

LightningAddress:RegisterChatCommand("tip", "TipTarget")

function LightningAddress:TipTarget(msg)
    local target = getNameOrTarget(msg)
    if target == nil then
        return
    end
    LightningAddress:Print("Tring to tip: " .. target)
    LightningAddress:SendCommMessage("lightningaddress", "request", "WHISPER", target)
end

function getNameOrTarget(msg)
    if msg ~= nil and msg ~= "" then return msg end
    local name, realm = UnitName("target")
    if name == nil then
        LightningAddress:Print("no target selected")
        return
    end
    local target = name
    if realm ~= nil then
        target = name .. "-" .. realm
    end
    return target
end

function LightningAddress:OnCommReceived(prefix, message, distribution, sender)
    LightningAddress:Print("New message " .. prefix .. " " .. message .. " " .. distribution .. " " ..sender)
    if prefix ~= "lightningaddress" then return end
    if message == "request" then 
        LightningAddress:Print("Request received from " .. sender)
        local address = LightningAddress:GetMyLightningAddress(nil)
        if address == nil then 
            LightningAddress:Print("No lightning address set")
            return
        end
        LightningAddress:SendCommMessage("lightningaddress", lnprefix(address), "WHISPER", sender)
        return
    end
    LightningAddress:Print("Response received from " .. sender .. " Address: " .. message)
    LightningAddress:OpenQrCode(message, message)
end

function lnprefix(address)
    if string.find(address, "lightning:") then
        return address
    end
    return "lightning:" .. address
  end

function LightningAddress:MyFunction()
    self.db.char.myVal = "My character-specific saved value"

    self.db.global.myOtherVal = "My global saved value"
end