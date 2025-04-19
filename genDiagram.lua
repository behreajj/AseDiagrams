local diagOptions <const> = {
    "POLAR_GRID",
    "RULE_OF_THIRDS",
    "SAND_RECKONER",
    "SEED_OF_LIFE"
}

local defaults <const> = {
    diagOption = "POLAR_GRID",
    strokeWeight = 1,
    swMin = 1,
    swMax = 32,
    strokeAbgr32 = 0xffffffff,
    useAntialias = true,

    xOffset = 0,
    yOffset = 0,

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
}

---@param context GraphicsContext canvas
---@param xc number center x
---@param yc number center y
---@param w number radius x
---@param h number radius y
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
---@param useAntiAlias? boolean use antialias
local function drawEllipse(
    context,
    xc, yc, w, h,
    strokeClr, strokeWeight,
    useAntiAlias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then
        return
    end

    local kw <const> = 0.5522847498307936 * w
    local kh <const> = 0.5522847498307936 * h

    local xcVerif = useAntiAlias and xc or math.floor(xc)
    local ycVerif = useAntiAlias and yc or math.floor(yc)

    local right <const> = xcVerif + w
    local left <const> = xcVerif - w
    local top <const> = ycVerif + h
    local bottom <const> = ycVerif - h

    if useAntiAlias then context.antialias = true end
    if useStrokeVerif then context.strokeWidth = strokeWeight end

    context:beginPath()
    context:moveTo(right, yc)
    context:cubicTo(right, yc + kh, xc + kw, top, xc, top)
    context:cubicTo(xc - kw, top, left, yc + kh, left, yc)
    context:cubicTo(left, yc - kh, xc - kw, bottom, xc, bottom)
    context:cubicTo(xc + kw, bottom, right, yc - kh, right, yc)
    context:closePath()

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
---@param useAntiAlias? boolean use antialias
local function drawLine(
    context,
    xo, yo, xd, yd,
    strokeClr, strokeWeight,
    useAntiAlias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then
        return
    end

    if useAntiAlias then context.antialias = true end
    if useStrokeVerif then context.strokeWidth = strokeWeight end

    context:beginPath()
    context:moveTo(xo, yo)
    context:lineTo(xd, yd)
    context:closePath()

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
---@param useAntiAlias? boolean use antialias
local function drawRect(
    context,
    xc, yc, w, h,
    strokeClr, strokeWeight,
    useAntiAlias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then
        return
    end

    if useAntiAlias then context.antialias = true end
    if useStrokeVerif then context.strokeWidth = strokeWeight end

    local xcVerif = useAntiAlias and xc or math.floor(xc)
    local ycVerif = useAntiAlias and yc or math.floor(yc)

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
        local isPolar <const> = diagOption == "POLAR_GRID"
        local isSand <const> = diagOption == "SAND_RECKONER"

        dlg:modify { id = "ringCount", visible = isPolar }
        dlg:modify { id = "lineCount", visible = isPolar }
        dlg:modify { id = "angOffsetDeg", visible = isPolar }

        dlg:modify { id = "sandReckCount", visible = isSand }
    end,
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

dlg:button {
    id = "okButton",
    text = "&OK",
    focus = true,
    onclick = function()
        local sprite = app.sprite
        if not sprite then
            sprite = Sprite(640, 360)
            sprite.gridBounds = Rectangle(0, 0, 40, 40)
            app.sprite = sprite
        end

        local spriteSpec <const> = sprite.spec
        local colorMode <const> = spriteSpec.colorMode

        -- TODO: Is this really necessary?
        if colorMode ~= ColorMode.RGB then
            app.alert {
                title = "Error",
                text = "Only RGB Color Mode is supported."
            }
            return
        end

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

        local xCenter <const> = xSpriteCenter + xOffset
        local yCenter <const> = ySpriteCenter - yOffset

        local cos <const> = math.cos
        local sin <const> = math.sin
        local tau <const> = math.pi + math.pi

        local gridName = "Layer"
        if diagOption == "POLAR_GRID" then
            gridName = "Polar Grid"

            local ringCount <const> = args.ringCount
                or defaults.ringCount --[[@as integer]]
            local lineCount <const> = args.lineCount
                or defaults.lineCount --[[@as integer]]
            local angOffsetDeg <const> = args.angOffsetDeg
                or defaults.angOffsetDeg --[[@as integer]]

            local angOffsetRad <const> = (useAntialiasVerif
                    and (angOffsetDeg == 26
                        or angOffsetDeg == 27))
                and 0.46364760900081
                or math.rad(angOffsetDeg)

            local xMaxRadius <const> = xCorrect * shortEdge * 0.5
            local xMinRadius <const> = ringCount ~= 0
                and xMaxRadius / ringCount
                or xMaxRadius * 0.5

            local yMaxRadius <const> = yCorrect * shortEdge * 0.5
            local yMinRadius <const> = ringCount ~= 0
                and yMaxRadius / ringCount
                or yMaxRadius * 0.5

            if ringCount > 0 then
                local toFac <const> = ringCount ~= 1
                    and 1.0 / (ringCount - 1.0)
                    or 1.0
                local i = 0
                while i < ringCount do
                    local t <const> = i * toFac
                    local u <const> = 1.0 - t
                    local xRadius <const> = u * xMinRadius
                        + t * xMaxRadius
                    local yRadius <const> = u * yMinRadius
                        + t * yMaxRadius

                    drawEllipse(
                        context,
                        xCenter, yCenter,
                        xRadius, yRadius,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)
                    i = i + 1
                end
            end

            if lineCount > 0 then
                local j = 0
                while j < lineCount do
                    local theta <const> = tau * j / lineCount - angOffsetRad
                    local cosTheta <const> = cos(theta)
                    local sinTheta <const> = sin(theta)
                    local xo <const> = xCenter + 0 * cosTheta
                    local yo <const> = yCenter + 0 * sinTheta
                    local xd <const> = xCenter + xMaxRadius * cosTheta
                    local yd <const> = yCenter + yMaxRadius * sinTheta

                    drawLine(
                        context,
                        xo, yo,
                        xd, yd,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)

                    j = j + 1
                end
            end
        elseif diagOption == "RULE_OF_THIRDS" then
            gridName = "Rule of Thirds"

            drawLine(
                context,
                0, hSprite / 3.0 - yOffset,
                wSprite, hSprite / 3.0 - yOffset,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                0, hSprite * 2.0 / 3.0 - yOffset,
                wSprite, hSprite * 2.0 / 3.0 - yOffset,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                wSprite / 3.0 + xOffset, 0,
                wSprite / 3.0 + xOffset, hSprite,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                wSprite * 2.0 / 3.0 + xOffset, 0,
                wSprite * 2.0 / 3.0 + xOffset, hSprite,
                strokeColor, strokeWeight,
                useAntialiasVerif)
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

                    local x <const> = u * (xCenter - xRadius) + t * (xCenter + xRadius)
                    local y <const> = u * (yCenter - yRadius) + t * (yCenter + yRadius)

                    drawLine(
                        context,
                        x, yCenter - yRadius,
                        x, yCenter + yRadius,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)

                    drawLine(
                        context,
                        xCenter - xRadius, y,
                        xCenter + xRadius, y,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)

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

            drawLine(
                context,
                xCenter, yCenter + yRadius,
                xCenter + xRadius, yCenter - yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter, yCenter - yRadius,
                xCenter + xRadius, yCenter + yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter, yCenter - yRadius,
                xCenter - xRadius, yCenter + yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter + xRadius, yCenter,
                xCenter - xRadius, yCenter + yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter + xRadius, yCenter,
                xCenter - xRadius, yCenter - yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter, yCenter + yRadius,
                xCenter - xRadius, yCenter - yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter - xRadius, yCenter,
                xCenter + xRadius, yCenter + yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawLine(
                context,
                xCenter - xRadius, yCenter,
                xCenter + xRadius, yCenter - yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)
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
        local activeLayer <const> = app.layer or sprite.layers[1]
        local activeFrObj <const> = app.frame or sprite.frames[1]

        app.transaction("Diagram", function()
            local gridLayer <const> = sprite:newLayer()

            local k = 0
            while k < lenFrObjs do
                k = k + 1
                local frObj <const> = frObjs[k]
                sprite:newCel(gridLayer, frObj, image, Point(0, 0))
            end

            gridLayer.name = gridName
            gridLayer.stackIndex = hasBkg and 2 or 1
            gridLayer.isEditable = false
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