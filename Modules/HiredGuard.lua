ub = LibStub('AceAddon-3.0'):GetAddon('UnderbellyBuddy')
ubHiredGuard = ub:NewModule('HiredGuard', 'AceConsole-3.0', 'AceEvent-3.0')

local buffName, _, buffIcon = GetSpellInfo(203894)
local fontName = GameFontHighlightSmallOutline:GetFont()
local inUnderbelly = false
local hasGuardBuff = false
local bar = {}
local barSize = {}
local secondsToDisplayWarning = {30, 90}
local barBase = {
    width = 140,
    height = 20,
    font = 8
}
local run = {
    warning = {},
    bar = false
}

function ubHiredGuard:OnInitialize()
    self.db = ub.db

    barSize = {
        width = self.db.profile.size * barBase.width,
        height = self.db.profile.size * barBase.height,
        font = self.db.profile.size * barBase.font
    }

    for _, value in pairs(secondsToDisplayWarning) do
        run.warning[value] = false
    end

    bar.container = CreateFrame('Frame', 'UnderbellyBuddyTimerBar', UIParent)
    bar.container:SetSize(barSize.width, barSize.height)
    bar.container:SetMovable(true)
    bar.container:SetUserPlaced(true)
    bar.container:SetPoint('CENTER', 0, 150)
    bar.container:EnableMouse(true)
    bar.container:RegisterForDrag('LeftButton')
    bar.container:SetScript('OnDragStart', function(self) if not ub.db.profile.lock then self:StartMoving() end end)
    bar.container:SetScript('OnDragStop', function(self) self:StopMovingOrSizing() end)
    bar.container:SetScript('OnMouseDown', function(self, button) if button == 'RightButton' then self:Hide() bar.timer:Hide() end end)    
end

function ubHiredGuard:OnEnable()
    local candyBar = LibStub('LibCandyBar-3.0')

    bar.timer = candyBar:New('Interface\\AddOns\\UnderbellyBuddy\\Media\\bar', barSize.width, barSize.height)
    bar.timer:SetPoint('CENTER', bar.container)
    bar.timer:SetLabel(buffName)
    bar.timer:SetIcon(buffIcon)
    bar.timer.candyBarLabel:SetFont(fontName, barSize.font)
    bar.timer.candyBarDuration:SetFont(fontName, barSize.font)
    bar.timer:Hide()

    bar.test = candyBar:New('Interface\\AddOns\\UnderbellyBuddy\\Media\\bar', barSize.width, barSize.height)
    bar.test:SetPoint('CENTER', bar.container)
    bar.test:SetLabel('Test Bar')
    bar.test:SetIcon(buffIcon)
    bar.test.candyBarLabel:SetFont(fontName, barSize.font)
    bar.test.candyBarDuration:SetFont(fontName, barSize.font)
    bar.test:Hide()

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckBodyGuard')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckBodyGuard')
    self:RegisterEvent('UNIT_AURA')
end

function ubHiredGuard:OnDisable()
    self:UnregisterEvent('PLAYER_ENTERING_WORLD')
    self:UnregisterEvent('ZONE_CHANGED_NEW_AREA')
    self:UnregisterEvent('UNIT_AURA')
    self:StopBar()
end

function ubHiredGuard:CheckBodyGuard()
    inUnderbelly = self:CheckZone(GetSubZoneText())
    hasGuardBuff = self:CheckBuff()
end

function ubHiredGuard:UNIT_AURA(eventName, unit)
    self:StartBar()
end

function ubHiredGuard:CheckZone(subzone)
    local correctZones = {'The Underbelly', 'The Underbelly Descent', 'Circle of Wills', 'The Black Market'}
    local value

    for _, value in pairs(correctZones) do
        if subzone == value then
            return true
        end
    end

    return false
end

function ubHiredGuard:CheckBuff()
    local buff = UnitBuff('player', buffName)

    if buff == buffName then
        return true
    else
        return false
    end
end

function ubHiredGuard:StartBar()
    if inUnderbelly then
        hasGuardBuff = self:CheckBuff()

        if hasGuardBuff and not run.bar then
            bar.test:Hide()
            bar.timer:AddUpdateFunction(function(bar) self:CheckRemaingTime(bar) end)
            bar.timer:SetDuration(300)
            bar.timer:Start()
        end

        if not hasGuardBuff then
            self:StopBar()
        end
    else
        self:StopBar()
    end
end

function ubHiredGuard:StopBar()
    if run.bar then
        bar.timer:Stop()
        run.bar = false

        for _, value in pairs(secondsToDisplayWarning) do
            run.warning[value] = false
        end
    end
end

function ubHiredGuard:Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function ubHiredGuard:CheckRemaingTime(bar)
    if self.db.profile.warning then
        local timeLeft = self:Round(bar.remaining, 1)
        local timeDisplay = string.format('%d seconds', timeLeft)

        if timeLeft > 60 then
            timeDisplay = string.format('%d minute %d seconds', timeLeft / 60 % 60, timeLeft % 60)         
        end

        for _, value in pairs(secondsToDisplayWarning) do
            if timeLeft == value and not run.warning[value] then 
                RaidNotice_AddMessage(RaidWarningFrame, string.format('Only %s remaining for %s!', timeDisplay, buffName), ChatTypeInfo['RAID_WARNING'])
                run.warning[value] = true
            end
        end
    end

    run.bar = true
end

function ubHiredGuard:SetEnabled(_, value)
    self.db.profile.enable = value
    
    if self.db.profile.enable then
        self:OnEnable()
    else
        self:OnDisable()
    end
end

function ubHiredGuard:ShowBar() 
    if run.bar then 
        bar.timer:Show() 
    else 
        ub:Print('No bar to display') 
    end 
end

function ubHiredGuard:HideBar()
    if run.bar then 
        bar.timer:Hide() 
    else 
        ub:Print('No bar to hide') 
    end 
 end

function ubHiredGuard:ShowTestBar()
    if not run.bar then
        bar.test:SetDuration(20)
        bar.test:Start()
    else
        ub:Print(string.format('%s is in progress and the test bar cannot be displayed.', buffName))
    end
end

function ubHiredGuard:SetSize(_, value) 
    self.db.profile.size = value
    
    bar.timer:SetSize(value * barBase.width, value * barBase.height)
    bar.timer.candyBarLabel:SetFont(fontName, value * barBase.font)
    bar.timer.candyBarDuration:SetFont(fontName, value * barBase.font)

    bar.test:SetSize(value * barBase.width, value * barBase.height)
    bar.test.candyBarLabel:SetFont(fontName, value * barBase.font)
    bar.test.candyBarDuration:SetFont(fontName, value * barBase.font)
end