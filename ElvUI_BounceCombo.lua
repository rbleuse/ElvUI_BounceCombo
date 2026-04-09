local E, L, V, P, G = unpack(ElvUI)
local EP = E:NewModule("ComboBounce", "AceHook-3.0", "AceEvent-3.0")

P["comboBounce"] = {
    ["enable"] = true,
    ["scale"] = 1.3,
    ["duration"] = 0.08,
}

local function CreateBounceAnimation(frame)
    if frame.bounceAnim then
        local anim = frame.bounceAnim
        local scale = E.db.comboBounce.scale
        local duration = E.db.comboBounce.duration

        anim._scaleUp:SetScale(scale, scale)
        anim._scaleUp:SetDuration(duration)
        anim._scaleDown:SetScale(1/scale, 1/scale)
        anim._scaleDown:SetDuration(duration)
        return
    end

    local scale = E.db.comboBounce.scale or 1.3
    local duration = E.db.comboBounce.duration or 0.08

    local bounce = frame:CreateAnimationGroup()

    local scaleUp = bounce:CreateAnimation("Scale")
    scaleUp:SetScale(scale, scale)
    scaleUp:SetDuration(duration)
    scaleUp:SetOrder(1)
    scaleUp:SetOrigin("CENTER", 0, 0)

    local scaleDown = bounce:CreateAnimation("Scale")
    scaleDown:SetScale(1/scale, 1/scale)
    scaleDown:SetDuration(duration)
    scaleDown:SetOrder(2)
    scaleDown:SetOrigin("CENTER", 0, 0)

    bounce._scaleUp = scaleUp
    bounce._scaleDown = scaleDown
    frame.bounceAnim = bounce
end

function EP:PostUpdateClassPower(element, cur, max, hasMaxChanged, powerType)
    if not E.db.comboBounce.enable or powerType ~= "COMBO_POINTS" then return end
    if not element or not cur or not max then return end

    local previous = element._previousCombo or 0

    -- If we spent points or changed targets, reset tracking
    if cur < previous then
        previous = 0
    end

    -- Animate only the newly gained points
    for i = 1, max do
        local point = element[i]
        if point and i > previous and i <= cur then
            CreateBounceAnimation(point)
            if point.bounceAnim:IsPlaying() then
                point.bounceAnim:Stop()
            end
            point.bounceAnim:Play()
        end
    end

    element._previousCombo = cur
end

function EP:HookClassPower()
    local playerFrame = _G.ElvUF_Player
    if playerFrame and playerFrame.ClassPower then
        if not self:IsHooked(playerFrame.ClassPower, "PostUpdate") then
            self:SecureHook(playerFrame.ClassPower, "PostUpdate", "PostUpdateClassPower")
        end
    else
        -- If player frame isn't ready, try again in 1 second
        E:Delay(1, EP.HookClassPower, EP)
    end
end

function EP:InsertOptions()
    if E.Options.args.comboBounce then return end

    E.Options.args.comboBounce = {
        order = 100,
        type = "group",
        name = "Combo Bounce",
        get = function(info) return E.db.comboBounce[info[#info]] end,
        set = function(info, value) E.db.comboBounce[info[#info]] = value end,
        args = {
            enable = {
                order = 1,
                type = "toggle",
                name = L["Enable"],
                desc = "Enable combo point bounce animation",
            },
            scale = {
                order = 2,
                type = "range",
                name = L["Scale"],
                min = 1.1, max = 2.0, step = 0.01,
            },
            duration = {
                order = 3,
                type = "range",
                name = L["Speed"],
                desc = "Duration of each half of the animation",
                min = 0.01, max = 0.5, step = 0.01,
            },
        },
    }
end

function EP:Initialize()
    EP:InsertOptions()

    self:HookClassPower()
end

E:RegisterModule(EP:GetName())