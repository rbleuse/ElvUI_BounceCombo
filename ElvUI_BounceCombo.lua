local E, L, _, P = unpack(ElvUI)
local EP = E:NewModule("BounceCombo", "AceHook-3.0", "AceEvent-3.0")

P.bounceCombo = {
    enable = true,
    scale = 1.3,
    duration = 0.08,
}

local db
local function UpdateAnimationSettings(frame)
    if not frame or not frame.bounceAnim then return end
    local anim = frame.bounceAnim
    local scale = db.scale
    local duration = db.duration
    local invScale = 1 / scale

    anim._scaleUp:SetScale(scale, scale)
    anim._scaleUp:SetDuration(duration)
    anim._scaleDown:SetScale(invScale, invScale)
    anim._scaleDown:SetDuration(duration)
end

local function CreateBounceAnimation(frame)
    if frame.bounceAnim then return end

    local bounce = frame:CreateAnimationGroup()
    local scaleUp = bounce:CreateAnimation("Scale")
    scaleUp:SetOrder(1)
    scaleUp:SetOrigin("CENTER", 0, 0)

    local scaleDown = bounce:CreateAnimation("Scale")
    scaleDown:SetOrder(2)
    scaleDown:SetOrigin("CENTER", 0, 0)

    bounce._scaleUp = scaleUp
    bounce._scaleDown = scaleDown
    frame.bounceAnim = bounce

    bounce:SetScript("OnFinished", function() frame:SetScale(1) end)

    UpdateAnimationSettings(frame)
end

function EP:PostUpdateClassPower(element, cur, _, _, powerType)
    if not db.enable or powerType ~= "COMBO_POINTS" then return end
    if not element or not cur then return end

    if self._targetJustChanged then
        element._bounceComboPrevious = cur
        self._targetJustChanged = nil
        return
    end

    local previous = element._bounceComboPrevious or 0

    -- Reset tracking if points spent or target changed
    if cur < previous then
        previous = 0
    end

    -- Loop only through the "new" points
    for i = previous + 1, cur do
        local point = element[i]
        if point then
            CreateBounceAnimation(point)

            point.bounceAnim:Stop()
            point.bounceAnim:Play()
        end
    end

    element._bounceComboPrevious = cur
end

-- Refresh all existing animations when options change
function EP:UpdateAllSettings()
    local playerFrame = _G.ElvUF_Player
    if playerFrame and playerFrame.ClassPower then
        local element = playerFrame.ClassPower

        for i = 1, #element do
            local point = element[i]
            UpdateAnimationSettings(point)
        end
    end
end

-- Hook safely after UI loads
function EP:HookClassPower()
    local playerFrame = _G.ElvUF_Player
    if not (playerFrame and playerFrame.ClassPower) then return end

    if not self:IsHooked(playerFrame.ClassPower, "PostUpdate") then
        self:SecureHook(playerFrame.ClassPower, "PostUpdate", "PostUpdateClassPower")
    end
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function EP:InsertOptions()
    if E.Options.args.bounceCombo then return end

    E.Options.args.bounceCombo = {
        order = 100,
        type = "group",
        name = L["Combo Bounce"],
        get = function(info) return db[info[#info]] end,
        set = function(info, value)
            db[info[#info]] = value
            EP:UpdateAllSettings()
        end,
        args = {
            enable = {
                order = 1,
                type = "toggle",
                name = L["Enable"],
                desc = L["Enable the bounce animation when combo points are gained."],
            },
            scale = {
                order = 2,
                type = "range",
                name = L["Scale"],
                desc = L["How much the combo point grows at the peak of the bounce."],
                min = 1.1, max = 2.0, step = 0.01,
                disabled = function() return not db.enable end,
            },
            duration = {
                order = 3,
                type = "range",
                name = L["Speed"],
                desc = L["Duration of each half of the bounce (scale up, then scale down)."],
                min = 0.01, max = 0.5, step = 0.01,
                disabled = function() return not db.enable end,
            },
        },
    }
end

function EP:RefreshDB()
    db = E.db.bounceCombo
    self:UpdateAllSettings()
end

function EP:Initialize()
    db = E.db.bounceCombo
    self:InsertOptions()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "HookClassPower")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function() self._targetJustChanged = true end)

    if E.data then
        E.data:RegisterCallback("OnProfileChanged", function() EP:RefreshDB() end)
        E.data:RegisterCallback("OnProfileCopied",  function() EP:RefreshDB() end)
        E.data:RegisterCallback("OnProfileReset",   function() EP:RefreshDB() end)
    else
        E.db.RegisterCallback(E.db, "OnProfileChanged", function() EP:RefreshDB() end)
        E.db.RegisterCallback(E.db, "OnProfileCopied",  function() EP:RefreshDB() end)
        E.db.RegisterCallback(E.db, "OnProfileReset",   function() EP:RefreshDB() end)
    end
end

E:RegisterModule(EP:GetName())