local E, L, V, P, G = unpack(ElvUI)

local previousCombo = 0

local bounceHooked = false

local function CreateBounceAnimation(frame)
    if frame.bounceAnim then return end

    local bounce = frame:CreateAnimationGroup()
    bounce:SetLooping("NONE")

    local scaleUp = bounce:CreateAnimation("Scale")
    scaleUp:SetScale(1.75, 1.75)
    scaleUp:SetDuration(0.1)
    scaleUp:SetOrder(1)

    local scaleDown = bounce:CreateAnimation("Scale")
    scaleDown:SetScale(0.66, 0.66)
    scaleDown:SetDuration(0.1)
    scaleDown:SetOrder(2)

    frame.bounceAnim = bounce
end

local function PostUpdateClassPower(element, cur, max, _, powerType)
    if powerType ~= "COMBO_POINTS" then return end
    if not element or type(cur) ~= "number" or type(max) ~= "number" or max <= 0 then return end

    previousCombo = math.min(previousCombo, max)

    for i = 1, max do
        local point = element[i]
        if point and i > previousCombo and i <= cur then
            CreateBounceAnimation(point)
            point.bounceAnim:Stop()
            point.bounceAnim:Play()
        end
    end

    previousCombo = cur
end

local bounceInitFrame = CreateFrame("Frame")
bounceInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
bounceInitFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" and not bounceHooked then
        local playerFrame = _G.ElvUF_Player
        if playerFrame and playerFrame.ClassPower then
            hooksecurefunc(playerFrame.ClassPower, "PostUpdate", PostUpdateClassPower)
            bounceHooked = true
        end
    end
end)
