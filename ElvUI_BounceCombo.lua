local E, L, V, P, G = unpack(ElvUI)
local EP = E:NewModule("ComboBounce", "AceHook-3.0", "AceEvent-3.0")

P.comboBounce = {
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

    UpdateAnimationSettings(frame)
end

function EP:PostUpdateClassPower(element, cur, _, _, powerType)
    if not db.enable or powerType ~= "COMBO_POINTS" then return end
    if not element or not cur then return end

    local previous = element._previousCombo or 0

    -- Reset tracking if points spent or target changed
    if cur < previous then
        previous = 0
    end

    -- Loop only through the "new" points
    for i = previous + 1, cur do
        local point = element[i]
        if point then
            CreateBounceAnimation(point)

            if point.bounceAnim:IsPlaying() then
                point.bounceAnim:Finish()
            end

            point.bounceAnim:Play()
        end
    end

    element._previousCombo = cur
end

-- Refresh all existing animations when options change
function EP:UpdateAllSettings()
    db = E.db.comboBounce
    local playerFrame = _G.ElvUF_Player
    if playerFrame and playerFrame.ClassPower then
        local element = playerFrame.ClassPower

        for i = 1, #element do
            local point = element[i] or (element.buttons and element.buttons[i])
            UpdateAnimationSettings(point)
        end
    end
end

-- Hook safely after UI loads
function EP:HookClassPower()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    local playerFrame = _G.ElvUF_Player
    if playerFrame and playerFrame.ClassPower then
        if not self:IsHooked(playerFrame.ClassPower, "PostUpdate") then
            self:SecureHook(playerFrame.ClassPower, "PostUpdate", "PostUpdateClassPower")
        end
    end
end

function EP:InsertOptions()
    if E.Options.args.comboBounce then return end

    E.Options.args.comboBounce = {
        order = 100,
        type = "group",
        name = "Combo Bounce",
        get = function(info) return E.db.comboBounce[info[#info]] end,
        set = function(info, value) 
            E.db.comboBounce[info[#info]] = value 
            EP:UpdateAllSettings()
        end,
        args = {
            enable = {
                order = 1,
                type = "toggle",
                name = L["Enable"],
            },
            scale = {
                order = 2,
                type = "range",
                name = L["Scale"],
                min = 1.1, max = 2.0, step = 0.01,
                disabled = function() return not E.db.comboBounce.enable end,
            },
            duration = {
                order = 3,
                type = "range",
                name = L["Speed"],
                min = 0.01, max = 0.5, step = 0.01,
                disabled = function() return not E.db.comboBounce.enable end,
            },
        },
    }
end

function EP:Initialize()
    db = E.db.comboBounce
    self:InsertOptions()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "HookClassPower")
end

E:RegisterModule(EP:GetName())