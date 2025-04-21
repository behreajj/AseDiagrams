local diagOptions <const> = {
    -- TODO: Phyllotaxis
    -- TODO: Mobius transformation
    -- TODO: https://en.wikipedia.org/wiki/Stereographic_projection#Wulff_net
    "GOLDEN_RECT",
    "NESTED_CIRCLES",
    "POLAR_GRID",
    "RULE_OF_THIRDS",
    "SAND_RECKONER",
    "SEED_OF_LIFE",
    "STAR",
}

local layerPlaces <const> = {
    "ABOVE",
    "BELOW",
    "TOP",
    "TOP_LOCAL",
    "BOTTOM",
    "BOTTOM_LOCAL",
}

local defaults <const> = {
    diagOption = "POLAR_GRID",
    strokeWeight = 1,
    swMin = 1,
    swMax = 32,
    strokeAbgr32 = 0xffffffff,
    useAntialias = true,
    layerPlace = "BOTTOM",

    xOffset = 0,
    yOffset = 0,

    -- Nested circles:
    nestedCount = 6,
    minNest = 3,
    maxNest = 12,
    showMeasure = false,
    showBottom = true,
    showTop = true,

    -- Polar grid:
    ringCount = 8,
    polarRingMin = 0,
    polarRingMax = 32,
    lineCount = 16,
    polarLineMin = 0,
    polarLineMax = 64,
    angOffsetDeg = 0,

    -- Sand reckoner:
    sandReckCount = 5,
    minSandReck = 0,
    maxSandReck = 11,

    -- Star:
    sidesStar = 5,
    starMin = 5,
    starMax = 16,
    angStarDeg = 0,
}

---@param context GraphicsContext canvas
---@param xc number center x
---@param yc number center y
---@param w number radius x
---@param h number radius y
---@param quadrant integer
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
---@param useAntialias? boolean use antialias
local function drawOrthoArc(
    context,
    xc, yc, w, h, quadrant,
    strokeClr, strokeWeight,
    useAntialias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then return end

    local kw <const> = 0.5522847498307936 * w
    local kh <const> = 0.5522847498307936 * h

    local xcVerif = useAntialias and xc or math.floor(xc)
    local ycVerif = useAntialias and yc or math.floor(yc)
    local qVerif <const> = quadrant % 4

    local right <const> = xcVerif + w
    local left <const> = xcVerif - w
    local top <const> = ycVerif + h
    local bottom <const> = ycVerif - h

    context:beginPath()
    if qVerif == 3 then
        context:moveTo(right, yc)
        context:cubicTo(right, yc + kh, xc + kw, top, xc, top)
    elseif qVerif == 2 then
        context:moveTo(xc, top)
        context:cubicTo(xc - kw, top, left, yc + kh, left, yc)
    elseif qVerif == 1 then
        context:moveTo(left, yc)
        context:cubicTo(left, yc - kh, xc - kw, bottom, xc, bottom)
    else
        context:moveTo(xc, bottom)
        context:cubicTo(xc + kw, bottom, right, yc - kh, right, yc)
    end

    context.strokeWidth = strokeWeight
    context.color = strokeClr
    context:stroke()
end

---@param context GraphicsContext canvas
---@param xc number center x
---@param yc number center y
---@param w number radius x
---@param h number radius y
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
---@param useAntialias? boolean use antialias
local function drawEllipse(
    context,
    xc, yc, w, h,
    strokeClr, strokeWeight,
    useAntialias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then return end

    local kw <const> = 0.5522847498307936 * w
    local kh <const> = 0.5522847498307936 * h

    local xcVerif = useAntialias and xc or math.floor(xc)
    local ycVerif = useAntialias and yc or math.floor(yc)

    local right <const> = xcVerif + w
    local left <const> = xcVerif - w
    local top <const> = ycVerif + h
    local bottom <const> = ycVerif - h

    context:beginPath()
    context:moveTo(right, yc)
    context:cubicTo(right, yc + kh, xc + kw, top, xc, top)
    context:cubicTo(xc - kw, top, left, yc + kh, left, yc)
    context:cubicTo(left, yc - kh, xc - kw, bottom, xc, bottom)
    context:cubicTo(xc + kw, bottom, right, yc - kh, right, yc)
    context:closePath()

    context.strokeWidth = strokeWeight
    context.color = strokeClr
    context:stroke()
end

---@param context GraphicsContext canvas
---@param xo number x origin
---@param yo number y origin
---@param xd number x destination
---@param yd number y destination
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
local function drawLine(
    context,
    xo, yo, xd, yd,
    strokeClr, strokeWeight)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then
        return
    end

    context:beginPath()
    context:moveTo(xo, yo)
    context:lineTo(xd, yd)
    context:closePath()

    context.strokeWidth = strokeWeight
    context.color = strokeClr
    context:stroke()
end

---@param context GraphicsContext canvas
---@param xc number center x
---@param yc number center y
---@param w number radius x
---@param h number radius y
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
---@param useAntialias? boolean use antialias
local function drawRect(
    context,
    xc, yc, w, h,
    strokeClr, strokeWeight,
    useAntialias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then
        return
    end

    local xcVerif = useAntialias and xc or math.floor(xc)
    local ycVerif = useAntialias and yc or math.floor(yc)

    local right <const> = xcVerif + w
    local left <const> = xcVerif - w
    local top <const> = ycVerif + h
    local bottom <const> = ycVerif - h

    context:beginPath()
    context:moveTo(left, top)
    context:lineTo(right, top)
    context:lineTo(right, bottom)
    context:lineTo(left, bottom)
    context:closePath()

    context.strokeWidth = strokeWeight
    context.color = strokeClr
    context:stroke()
end

---@param x integer
---@return Color
local function abgr32ToAseColor(x)
    return Color {
        r = (x >> 0x00) & 0xff,
        g = (x >> 0x08) & 0xff,
        b = (x >> 0x10) & 0xff,
        a = (x >> 0x18) & 0xff,
    }
end

local dlg <const> = Dialog {
    title = "Diagrams",
}

dlg:combobox {
    id = "diagOption",
    label = "Type:",
    option = defaults.diagOption,
    options = diagOptions,
    focus = false,
    onchange = function()
        local args <const> = dlg.data
        local diagOption <const> = args.diagOption
        local isNest <const> = diagOption == "NESTED_CIRCLES"
        local isPolar <const> = diagOption == "POLAR_GRID"
        local isSand <const> = diagOption == "SAND_RECKONER"
        local isStar <const> = diagOption == "STAR"

        dlg:modify { id = "nestedCount", visible = isNest }
        dlg:modify { id = "showMeasure", visible = isNest }
        dlg:modify { id = "showBottom", visible = isNest }
        dlg:modify { id = "showTop", visible = isNest }

        dlg:modify { id = "ringCount", visible = isPolar }
        dlg:modify { id = "lineCount", visible = isPolar }
        dlg:modify { id = "angOffsetDeg", visible = isPolar }

        dlg:modify { id = "sandReckCount", visible = isSand }

        dlg:modify { id = "sidesStar", visible = isStar }
        dlg:modify { id = "angStarDeg", visible = isStar }
    end,
}

dlg:newrow { always = false }

dlg:slider {
    id = "nestedCount",
    label = "Count:",
    value = defaults.nestedCount,
    min = defaults.minNest,
    max = defaults.maxNest,
    focus = false,
    visible = defaults.diagOption == "NESTED_CIRCLES",
}

dlg:newrow { always = false }

dlg:check {
    id = "showMeasure",
    label = "Show:",
    text = "Measure",
    selected = defaults.showMeasure,
    focus = false,
    visible = defaults.diagOption == "NESTED_CIRCLES",
}

dlg:check {
    id = "showBottom",
    text = "Bottom",
    selected = defaults.showBottom,
    focus = false,
    visible = defaults.diagOption == "NESTED_CIRCLES",
}

dlg:check {
    id = "showTop",
    text = "Top",
    selected = defaults.showTop,
    focus = false,
    visible = defaults.diagOption == "NESTED_CIRCLES",
}

dlg:newrow { always = false }

dlg:slider {
    id = "ringCount",
    label = "Rings:",
    value = defaults.ringCount,
    min = defaults.polarRingMin,
    max = defaults.polarRingMax,
    focus = false,
    visible = defaults.diagOption == "POLAR_GRID",
}

dlg:newrow { always = false }

dlg:slider {
    id = "lineCount",
    label = "Sectors:",
    value = defaults.lineCount,
    min = defaults.polarLineMin,
    max = defaults.polarLineMax,
    focus = false,
    visible = defaults.diagOption == "POLAR_GRID",
}

dlg:newrow { always = false }

dlg:slider {
    id = "angOffsetDeg",
    label = "Angle:",
    value = defaults.angOffsetDeg,
    min = -180,
    max = 180,
    focus = false,
    visible = defaults.diagOption == "POLAR_GRID",
}

dlg:newrow { always = false }

dlg:slider {
    id = "sandReckCount",
    label = "Sections:",
    value = defaults.sandReckCount,
    min = defaults.minSandReck,
    max = defaults.maxSandReck,
    focus = false,
    visible = defaults.diagOption == "SAND_RECKONER",
}

dlg:newrow { always = false }

dlg:slider {
    id = "sidesStar",
    label = "Spokes:",
    value = defaults.sidesStar,
    min = defaults.starMin,
    max = defaults.starMax,
    focus = false,
    visible = defaults.diagOption == "STAR",
}

dlg:newrow { always = false }

dlg:slider {
    id = "angStarDeg",
    label = "Angle:",
    value = defaults.angStarDeg,
    min = -180,
    max = 180,
    focus = false,
    visible = defaults.diagOption == "STAR",
}

dlg:newrow { always = false }

dlg:number {
    id = "xOffset",
    label = "Offset:",
    text = string.format("%d", defaults.xOffset),
    decimals = 0,
    focus = false,
}

dlg:number {
    id = "yOffset",
    text = string.format("%d", defaults.yOffset),
    decimals = 0,
    focus = false,
}

dlg:newrow { always = false }

dlg:slider {
    id = "strokeWeight",
    label = "Stroke:",
    value = defaults.strokeWeight,
    min = defaults.swMin,
    max = defaults.swMax,
    focus = false,
}

dlg:newrow { always = false }

dlg:color {
    id = "strokeColor",
    label = "Color:",
    color = abgr32ToAseColor(defaults.strokeAbgr32),
    focus = false,
}

dlg:newrow { always = false }

dlg:check {
    id = "useAntialias",
    label = "Enable:",
    text = "AntiAlias",
    selected = defaults.useAntialias,
    focus = false,
}

dlg:newrow { always = false }

dlg:combobox {
    id = "layerPlace",
    label = "Layer:",
    option = defaults.layerPlace,
    options = layerPlaces,
    focus = false,
}

dlg:newrow { always = false }

dlg:button {
    id = "okButton",
    text = "&OK",
    focus = true,
    onclick = function()
        local sprite = app.sprite
        if not sprite then
            local defSpec <const> = ImageSpec {
                width = 640,
                height = 360,
                colorMode = ColorMode.RGB,
                transparentColor = 0
            }
            defSpec.colorSpace = ColorSpace { sRGB = true }
            sprite = Sprite(defSpec)

            app.transaction("Set Palette", function()
                local palette <const> = sprite.palettes[1]
                palette:resize(256)
                local floor <const> = math.floor

                local k = 0
                while k < 256 do
                    local h <const> = k // 64
                    local m <const> = k - h * 64
                    palette:setColor(k, Color {
                        r = floor(((m % 8) / 7) * 255 + 0.5),
                        g = floor(((m // 8) / 7) * 255 + 0.5),
                        b = floor((h / 3) * 255 + 0.5),
                        a = 255
                    })
                    k = k + 1
                end
                palette:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
            end)

            app.sprite = sprite
        end

        local spriteSpec <const> = sprite.spec
        local colorMode <const> = spriteSpec.colorMode

        local image <const> = Image(spriteSpec)
        local context <const> = image.context
        if not context then
            app.alert {
                title = "Error",
                text = "Drawing canvas could not be found."
            }
            return
        end

        local args <const> = dlg.data
        local diagOption <const> = args.diagOption
            or defaults.diagOption --[[@as string]]
        local xOffset <const> = args.xOffset
            or defaults.xOffset --[[@as number]]
        local yOffset <const> = args.yOffset
            or defaults.yOffset --[[@as number]]
        local strokeWeight <const> = args.strokeWeight
            or defaults.strokeWeight --[[@as integer]]
        local strokeColor <const> = args.strokeColor
            or abgr32ToAseColor(defaults.strokeAbgr32) --[[@as Color]]
        local useAntialias <const> = args.useAntialias --[[@as boolean]]
        local layerPlace <const> = args.layerPlace
            or defaults.layerPlace --[[@as string]]

        if strokeColor.alpha <= 0 then
            app.alert {
                title = "Error",
                text = "Stroke color has zero alpha."
            }
            return
        end

        local activeTool <const> = app.tool
        if activeTool.id == "slice" then
            app.tool = "hand"
        end

        local pixelRatio <const> = sprite.pixelRatio
        local wPixel <const> = math.max(1, math.abs(pixelRatio.width))
        local hPixel <const> = math.max(1, math.abs(pixelRatio.height))
        local shortPixel <const> = math.min(wPixel, hPixel)

        local xCorrect = 1
        local yCorrect = 1
        if wPixel ~= hPixel then
            if wPixel == shortPixel then
                yCorrect = wPixel / hPixel
            elseif hPixel == shortPixel then
                xCorrect = hPixel / wPixel
            end
        end

        local wSprite <const> = spriteSpec.width
        local hSprite <const> = spriteSpec.height
        local xSpriteCenter <const> = wSprite * 0.5
        local ySpriteCenter <const> = hSprite * 0.5
        local shortEdge <const> = math.min(
                wSprite * wPixel,
                hSprite * hPixel)
            // shortPixel

        local useAntialiasVerif <const> = useAntialias
            and colorMode ~= ColorMode.INDEXED
        if useAntialiasVerif then context.antialias = true end

        local xCenter <const> = xSpriteCenter + xOffset
        local yCenter <const> = ySpriteCenter - yOffset

        local cos <const> = math.cos
        local sin <const> = math.sin
        local tau <const> = math.pi + math.pi
        local phi <const> = (1 + math.sqrt(5)) / 2
        local goldenAngle <const> = tau / (phi * phi)

        local gridName = "Layer"
        if diagOption == "GOLDEN_RECT" then
            gridName = "Golden Rectangle"

            local phiInv <const> = 1.0 / phi
            local phiInvE2 <const> = phiInv * phiInv
            local phiInvE3 <const> = phiInvE2 * phiInv
            local phiInvE4 <const> = phiInvE3 * phiInv
            local phiInvE5 <const> = phiInvE4 * phiInv
            local halfEdge <const> = shortEdge * 0.5
            local wRect <const> = xCorrect * halfEdge * phi
            local hRect <const> = yCorrect * halfEdge

            drawRect(
                context,
                xCenter, yCenter,
                wRect, hRect,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            local wDiam <const> = wRect + wRect
            local hDiam <const> = hRect + hRect

            local left <const> = xCenter - wRect
            local right <const> = xCenter + wRect
            local top <const> = yCenter - hRect
            local bottom <const> = yCenter + hRect

            -- There's no point in generalizing these to a for loop, in most
            -- cases the canvas will be too small for more iterations than this
            -- to be needed.
            local xConst1 <const> = left + wDiam * phiInv
            drawLine(
                context,
                xConst1, top,
                xConst1, bottom,
                strokeColor, strokeWeight)

            local yConst2 <const> = top + hDiam * phiInv
            drawLine(
                context,
                xConst1, yConst2,
                right, yConst2,
                strokeColor, strokeWeight)

            local xConst3 <const> = right - wDiam * phiInvE3
            drawLine(
                context,
                xConst3, yConst2,
                xConst3, bottom,
                strokeColor, strokeWeight)

            local yConst4 <const> = bottom - hDiam * phiInvE3
            drawLine(
                context,
                xConst1, yConst4,
                xConst3, yConst4,
                strokeColor, strokeWeight)

            local xConst5 <const> = xConst1 + wDiam * phiInvE5
            drawLine(
                context,
                xConst5, yConst2,
                xConst5, yConst4,
                strokeColor, strokeWeight)

            local rx <const> = xCorrect * shortEdge
            local ry <const> = yCorrect * shortEdge
            drawOrthoArc(
                context,
                xConst1, bottom,
                rx, ry, 1,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawOrthoArc(
                context,
                xConst1, yConst2,
                rx * phiInv, ry * phiInv, 0,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawOrthoArc(
                context,
                xConst3, yConst2,
                rx * phiInvE2, ry * phiInvE2, 3,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawOrthoArc(
                context,
                xConst3, yConst4,
                rx * phiInvE3, ry * phiInvE3, 2,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawOrthoArc(
                context,
                xConst5, yConst4,
                rx * phiInvE4, ry * phiInvE4, 1,
                strokeColor, strokeWeight,
                useAntialiasVerif)
        elseif diagOption == "NESTED_CIRCLES" then
            gridName = "Nested Circles"

            local count <const> = args.nestedCount
                or defaults.nestedCount --[[@as integer]]
            local showMeasure <const> = args.showMeasure --[[@as boolean]]
            local showBottom <const> = args.showBottom --[[@as boolean]]
            local showTop <const> = args.showTop --[[@as boolean]]

            local mShowVerif = showMeasure
            local bShowVerif = showBottom
            local tShowVerif = showTop
            if (not showMeasure)
                and (not showBottom)
                and (not showTop) then
                mShowVerif = defaults.showMeasure
                bShowVerif = defaults.showBottom
                tShowVerif = defaults.showTop
            end

            local baseCircDiam <const> = (yCorrect * shortEdge * 2) / count
            local baseCircRad <const> = baseCircDiam * 0.5
            local halfEdge <const> = shortEdge * 0.5

            local xMinRadius <const> = xCorrect * baseCircRad
            local yMinRadius <const> = yCorrect * baseCircRad
            local xMaxRadius <const> = xCorrect * halfEdge
            local yMaxRadius <const> = yCorrect * halfEdge

            local yOrig <const> = yCenter - yMinRadius + yMaxRadius
            local yDest <const> = yCenter + yMinRadius - yMaxRadius

            local toFac <const> = count ~= 1
                and 1.0 / (count - 1.0)
                or 0.0

            if mShowVerif then
                local i = 0
                while i < count do
                    local t <const> = i * toFac
                    local y <const> = (1.0 - t) * yOrig + t * yDest

                    drawEllipse(
                        context,
                        xCenter, y,
                        xMinRadius, yMinRadius,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)

                    i = i + 1
                end
            end

            if bShowVerif then
                local j = 0
                while j < count do
                    local t <const> = j * toFac
                    local u <const> = 1.0 - t
                    local xr <const> = u * xMinRadius + t * xMaxRadius
                    local yr <const> = u * yMinRadius + t * yMaxRadius

                    drawEllipse(
                        context,
                        xCenter, yOrig + yMinRadius - yr,
                        xr, yr,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)

                    j = j + 1
                end
            end

            if tShowVerif then
                local k = 0
                while k < count do
                    local t <const> = k * toFac
                    local u <const> = 1.0 - t
                    local xr <const> = u * xMinRadius + t * xMaxRadius
                    local yr <const> = u * yMinRadius + t * yMaxRadius

                    drawEllipse(
                        context,
                        xCenter, yDest - yMinRadius + yr,
                        xr, yr,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)

                    k = k + 1
                end
            end
        elseif diagOption == "POLAR_GRID" then
            gridName = "Polar Grid"

            local ringCount <const> = args.ringCount
                or defaults.ringCount --[[@as integer]]
            local lineCount <const> = args.lineCount
                or defaults.lineCount --[[@as integer]]
            local angOffsetDeg <const> = args.angOffsetDeg
                or defaults.angOffsetDeg --[[@as integer]]

            local invalRequest <const> = ringCount <= 0 and lineCount <= 0
            local rcVerif <const> = invalRequest
                and defaults.ringCount
                or ringCount
            local lcVerif <const> = invalRequest
                and defaults.lineCount
                or lineCount

            local angOffsetRad <const> = (useAntialiasVerif
                    and (angOffsetDeg == 26
                        or angOffsetDeg == 27))
                and 0.46364760900081
                or math.rad(angOffsetDeg)

            local xMaxRadius <const> = xCorrect * shortEdge * 0.5
            local xMinRadius <const> = rcVerif ~= 0
                and xMaxRadius / rcVerif
                or xMaxRadius * 0.5

            local yMaxRadius <const> = yCorrect * shortEdge * 0.5
            local yMinRadius <const> = rcVerif ~= 0
                and yMaxRadius / rcVerif
                or yMaxRadius * 0.5

            if rcVerif > 0 then
                local toFac <const> = rcVerif ~= 1
                    and 1.0 / (rcVerif - 1.0)
                    or 1.0
                local i = 0
                while i < rcVerif do
                    local t <const> = i * toFac
                    local u <const> = 1.0 - t
                    local xRadius <const> = u * xMinRadius
                        + t * xMaxRadius
                    local yRadius <const> = u * yMinRadius
                        + t * yMaxRadius

                    -- TODO: Option to turn this into a spherical grid by
                    -- scaling the radii appropriately? Could change t, but
                    -- would also have to change the min radius.
                    -- t = math.sqrt(1.0 - math.sqrt(t * t))
                    drawEllipse(
                        context,
                        xCenter, yCenter,
                        xRadius, yRadius,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)
                    i = i + 1
                end
            end

            if lcVerif > 0 then
                local j = 0
                while j < lcVerif do
                    local theta <const> = tau * j / lcVerif - angOffsetRad
                    local cosTheta <const> = cos(theta)
                    local sinTheta <const> = sin(theta)

                    drawLine(context,
                        xCenter + 0 * cosTheta,
                        yCenter + 0 * sinTheta,
                        xCenter + xMaxRadius * cosTheta,
                        yCenter + yMaxRadius * sinTheta,
                        strokeColor, strokeWeight)

                    j = j + 1
                end
            end
        elseif diagOption == "RULE_OF_THIRDS" then
            gridName = "Rule of Thirds"

            drawLine(context,
                0, hSprite / 3.0 - yOffset,
                wSprite, hSprite / 3.0 - yOffset,
                strokeColor, strokeWeight)

            drawLine(context,
                0, hSprite * 2.0 / 3.0 - yOffset,
                wSprite, hSprite * 2.0 / 3.0 - yOffset,
                strokeColor, strokeWeight)

            drawLine(context,
                wSprite / 3.0 + xOffset, 0,
                wSprite / 3.0 + xOffset, hSprite,
                strokeColor, strokeWeight)

            drawLine(context,
                wSprite * 2.0 / 3.0 + xOffset, 0,
                wSprite * 2.0 / 3.0 + xOffset, hSprite,
                strokeColor, strokeWeight)
        elseif diagOption == "SAND_RECKONER" then
            gridName = "Sand Reckoner"

            local sandReckCount <const> = args.sandReckCount
                or defaults.sandReckCount --[[@as integer]]

            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            if sandReckCount > 1 then
                local i = 0
                while i < sandReckCount - 1 do
                    local t <const> = (i + 1) / sandReckCount
                    local u <const> = 1.0 - t

                    local x <const> = u * (xCenter - xRadius)
                        + t * (xCenter + xRadius)
                    local y <const> = u * (yCenter - yRadius)
                        + t * (yCenter + yRadius)

                    drawLine(context,
                        x, yCenter - yRadius,
                        x, yCenter + yRadius,
                        strokeColor, strokeWeight)

                    drawLine(context,
                        xCenter - xRadius, y,
                        xCenter + xRadius, y,
                        strokeColor, strokeWeight)

                    i = i + 1
                end
            end

            if sandReckCount > 0 then
                drawRect(
                    context,
                    xCenter, yCenter,
                    xRadius, yRadius,
                    strokeColor, strokeWeight,
                    useAntialiasVerif)
            end

            local points <const> = {
                xCenter + xRadius, yCenter,           -- right edge midpoint
                xCenter + xRadius, yCenter - yRadius, -- top right corner
                xCenter, yCenter - yRadius,           -- top edge midpoint
                xCenter - xRadius, yCenter - yRadius, -- top left corner
                xCenter - xRadius, yCenter,           -- left edge midpoint
                xCenter - xRadius, yCenter + yRadius, -- bottom left corner
                xCenter, yCenter + yRadius,           -- bottom edge midpoint
                xCenter + xRadius, yCenter + yRadius, -- bottom right corner
            }
            local lenPoints <const> = #points

            local j = 0
            while j < lenPoints do
                local k <const> = (j + 4) % lenPoints
                drawLine(context,
                    points[1 + j], points[2 + j],
                    points[1 + k], points[2 + k],
                    strokeColor, strokeWeight)
                j = j + 2
            end
        elseif diagOption == "SEED_OF_LIFE" then
            gridName = "Seed of Life"

            local angOffsetDeg <const> = 30
            local angOffsetRad <const> = math.rad(angOffsetDeg)
            local xRadius <const> = xCorrect * shortEdge * 0.25
            local yRadius <const> = yCorrect * shortEdge * 0.25

            -- Center circle
            drawEllipse(
                context,
                xCenter, yCenter,
                xRadius, yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            local i = 0
            while i < 6 do
                local theta <const> = tau * i / 6.0 - angOffsetRad
                local cosTheta <const> = cos(theta)
                local sinTheta <const> = sin(theta)
                local rct <const> = xRadius * cosTheta
                local rst <const> = yRadius * sinTheta
                local xc <const> = xCenter + rct
                local yc <const> = yCenter + rst

                drawEllipse(
                    context,
                    xc, yc,
                    xRadius, yRadius,
                    strokeColor, strokeWeight,
                    useAntialiasVerif)

                i = i + 1
            end
        elseif diagOption == "STAR" then
            local sidesStar <const> = args.sidesStar
                or defaults.sidesStar --[[@as integer]]
            local angStarDeg <const> = args.angStarDeg
                or defaults.angStarDeg --[[@as integer]]

            local sidesVerif <const> = math.max(5, math.abs(sidesStar))
            local angStarRad <const> = math.rad(90 + angStarDeg)
            local toTheta <const> = tau / sidesVerif
            local skip <const> = math.ceil(sidesVerif / 3)

            gridName = string.format("Star %d", sidesVerif)

            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            local i = 0
            while i < sidesVerif do
                local j <const> = (i + 1) % sidesVerif
                local k <const> = (i + skip) % sidesVerif

                local theta0 <const> = i * toTheta - angStarRad
                local theta1 <const> = j * toTheta - angStarRad
                local theta2 <const> = k * toTheta - angStarRad

                local x0 <const> = xCenter + xRadius * cos(theta0)
                local y0 <const> = yCenter + yRadius * sin(theta0)

                -- TODO: Make a separate polygon method?
                drawLine(context, x0, y0,
                    xCenter + xRadius * cos(theta1),
                    yCenter + yRadius * sin(theta1),
                    strokeColor, strokeWeight)

                drawLine(context, x0, y0,
                    xCenter + xRadius * cos(theta2),
                    yCenter + yRadius * sin(theta2),
                    strokeColor, strokeWeight)

                i = i + 1
            end
        else
            app.alert {
                title = "Error",
                text = "Unrecognized diagram option."
            }
            return
        end

        local hasBkg <const> = sprite.backgroundLayer ~= nil
        local frObjs <const> = sprite.frames
        local lenFrObjs <const> = #frObjs
        local activeLayer <const> = app.layer
            or sprite.layers[1] --[[@as Layer]]
        local activeFrObj <const> = app.frame
            or frObjs[1] --[[@as Frame]]

        app.transaction("Diagram", function()
            local gridLayer <const> = sprite:newLayer()

            -- There could be an option to choose active or range frames
            -- instead of all. However, the control flow for this is finicky.
            -- Getting those frames outside the transaction immediately above
            -- results in inappropriately offset frames.
            local k = 0
            while k < lenFrObjs do
                k = k + 1
                sprite:newCel(gridLayer, k, image, Point(0, 0))
            end

            gridLayer.name = gridName
            if layerPlace == "BOTTOM_LOCAL"
                or layerPlace == "TOP_LOCAL"
                or layerPlace == "ABOVE"
                or layerPlace == "BELOW" then
                gridLayer.parent = activeLayer.parent
            end

            if layerPlace == "BOTTOM" then
                gridLayer.stackIndex = hasBkg and 2 or 1
            elseif layerPlace == "BOTTOM_LOCAL" then
                gridLayer.stackIndex = 1
            elseif layerPlace == "ABOVE" then
                gridLayer.stackIndex = activeLayer.stackIndex + 1
            elseif layerPlace == "BELOW" then
                if activeLayer.isBackground then
                    gridLayer.stackIndex = activeLayer.stackIndex + 1
                else
                    gridLayer.stackIndex = activeLayer.stackIndex
                end
            end
        end)

        app.layer = activeLayer
        app.frame = activeFrObj
        app.refresh()
    end,
}

dlg:button {
    id = "cancelButton",
    text = "&CANCEL",
    focus = false,
    onclick = function() dlg:close() end,
}

dlg:show {
    wait = false,
    autoscrollbars = true,
}