local diagOptions <const> = {
    -- stereographic projection?
    -- https://en.wikipedia.org/wiki/Tomoe
    -- TODO: Circles arranged in a circle at an offset to create a
    -- swirl pattern?
    "ARC",
    "DIMETRIC_GRID",
    "EGG",
    "GOLDEN_RECT",
    "HEX_GRID",
    "IN_CIRCLE",
    "IN_SQUARE",
    "INSCRIBED_POLY",
    "NESTED_CIRCLES",
    "POLAR_GRID",
    "RULE_OF_THIRDS",
    "SAND_RECKONER",
    "SEED_OF_LIFE",
    "STAR",
    "VESICA_PISCIS",
}

local layerPlaces <const> = {
    "ABOVE",
    "BELOW",
    "TOP",
    "TOP_LOCAL",
    "BOTTOM",
    "BOTTOM_LOCAL",
}

local arcModes <const> = {
    "PIE",
    "STROKE",
}

local defaults <const> = {
    diagOption = "POLAR_GRID",
    strokeWeight = 1,
    swMin = 1,
    swMax = 32,
    strokeAbgr32 = 0xffffffff,
    useAntialias = true,
    useTrimAlpha = true,
    layerPlace = "BOTTOM",

    xOffset = 0,
    yOffset = 0,

    -- Arc:
    arcMode = "PIE",
    arcStartDeg = 0,
    arcStopDeg = 90,

    -- Dimetric grid:
    dimetricCount = 12,
    minDimetric = 1,
    maxDimetric = 32,

    -- Egg:
    angEggDeg = 0,

    -- Hex grid:
    hexRings = 4,
    minRings = 1,
    maxRings = 32,
    useDimetric = false,

    -- Inscribed polygons:
    polyIter = 4,
    sidesPoly = 3,
    angPolyDeg = 0,
    polyMin = 3,
    polyMax = 10,
    minIter = 1,
    maxIter = 16,

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

    -- Vesica Piscis:
    useSeedRatio = false,
    usePivot = false,
    angVesicaDeg = 0,

    wSprite = 640,
    hSprite = 360,
    wBkgCheck = 40,
    hBkgCheck = 40,
}

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

    local xcVerif <const> = useAntialias and xc or math.floor(xc)
    local ycVerif <const> = useAntialias and yc or math.floor(yc)

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
---@param arcMode "STROKE"|"PIE" arc draw mode
---@param xc number center x
---@param yc number center y
---@param w number radius x
---@param h number radius y
---@param startAngle number start angle in radians
---@param stopAngle number stop angle in radians
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
---@param useAntialias? boolean use antialias
local function drawArc(
    context,
    arcMode,
    xc, yc, w, h,
    startAngle, stopAngle,
    strokeClr, strokeWeight,
    useAntialias)
    local tau <const> = math.pi + math.pi
    local halfpi <const> = math.pi * 0.5

    local stAngVerif <const> = math.min(startAngle, stopAngle)
    local edAngVerif <const> = math.max(startAngle, stopAngle)
    local arcLength <const> = math.min(edAngVerif - stAngVerif, tau)

    if math.abs(tau - arcLength) < 0.00139
        or math.abs(arcLength) < 0.00139 then
        drawEllipse(context, xc, yc, w, h,
            strokeClr, strokeWeight, useAntialias)
        return
    end

    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then return end

    local xcVerif <const> = useAntialias and xc or math.floor(xc)
    local ycVerif <const> = useAntialias and yc or math.floor(yc)

    local cos <const> = math.cos
    local sin <const> = math.sin

    local arcLen01 <const> = arcLength / tau
    local kntAdd <const> = arcLen01 % 0.25 > 0.00001 and 1 or 0
    local knCtVerif <const> = math.max(2, math.ceil(kntAdd + 4 * arcLen01))
    local toStep <const> = 1.0 / (knCtVerif - 1.0)
    local invKnCt <const> = toStep * arcLen01
    local xhm <const> = w * (4.0 / 3.0) * math.tan(halfpi * invKnCt)
    local yhm <const> = h * (4.0 / 3.0) * math.tan(halfpi * invKnCt)

    local cosAngle = cos(-stAngVerif)
    local sinAngle = sin(-stAngVerif)
    local xap = xcVerif + w * cosAngle
    local yap = ycVerif + h * sinAngle
    local hmsina = sinAngle * xhm
    local hmcosa = cosAngle * yhm
    local cp1x = xap + hmsina
    local cp1y = yap - hmcosa
    local cp2x = 0
    local cp2y = 0

    context:beginPath()
    context:moveTo(xap, yap)

    local i = 1
    while i < knCtVerif do
        local t = i * toStep
        local u = 1.0 - t
        local angle = u * stAngVerif + t * edAngVerif

        cosAngle = cos(-angle)
        sinAngle = sin(-angle)
        xap = xcVerif + w * cosAngle
        yap = ycVerif + h * sinAngle

        hmsina = sinAngle * xhm
        hmcosa = cosAngle * yhm
        cp2x = xap - hmsina
        cp2y = yap + hmcosa

        context:cubicTo(cp1x, cp1y, cp2x, cp2y, xap, yap)

        cp1x = xap + hmsina
        cp1y = yap - hmcosa

        i = i + 1
    end

    if arcMode == "PIE" then
        context:lineTo(xcVerif, ycVerif)
        context:closePath()
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
---@param sides integer sides
---@param rotation number rotation
---@param strokeClr Color stroke color
---@param strokeWeight integer stroke weight
---@param useAntialias? boolean use antialias
local function drawPolygon(
    context,
    xc, yc, w, h,
    sides, rotation,
    strokeClr, strokeWeight,
    useAntialias)
    local useStrokeVerif <const> = strokeWeight > 0
        and strokeClr.alpha > 0
    if (not useStrokeVerif) then
        return
    end

    local xcVerif <const> = useAntialias and xc or math.floor(xc)
    local ycVerif <const> = useAntialias and yc or math.floor(yc)

    local iToTheta <const> = 6.2831853071796 / sides
    local cos <const> = math.cos
    local sin <const> = math.sin

    context:beginPath()
    context:moveTo(
        cos(-rotation) * w + xcVerif,
        ycVerif - sin(-rotation) * h)
    local i = 0
    while i < sides do
        i = i + 1
        local a <const> = i * iToTheta - rotation
        context:lineTo(
            cos(a) * w + xcVerif,
            ycVerif - sin(a) * h)
    end
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

    local xcVerif <const> = useAntialias and xc or math.floor(xc)
    local ycVerif <const> = useAntialias and yc or math.floor(yc)

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

        local isArc <const> = diagOption == "ARC"
        local isDimetric <const> = diagOption == "DIMETRIC_GRID"
        local isEgg <const> = diagOption == "EGG"
        local isHex <const> = diagOption == "HEX_GRID"
        local isPoly <const> = diagOption == "INSCRIBED_POLY"
        local isNest <const> = diagOption == "NESTED_CIRCLES"
        local isPolar <const> = diagOption == "POLAR_GRID"
        local isSand <const> = diagOption == "SAND_RECKONER"
        local isStar <const> = diagOption == "STAR"
        local isVesica <const> = diagOption == "VESICA_PISCIS"

        dlg:modify { id = "arcMode", visible = isArc }
        dlg:modify { id = "arcStartDeg", visible = isArc }
        dlg:modify { id = "arcStopDeg", visible = isArc }

        dlg:modify { id = "dimetricCount", visible = isDimetric }

        dlg:modify { id = "angEggDeg", visible = isEgg }

        dlg:modify { id = "hexRings", visible = isHex }
        dlg:modify { id = "useDimetric", visible = isHex }

        dlg:modify { id = "polyIter", visible = isPoly }
        dlg:modify { id = "sidesPoly", visible = isPoly }
        dlg:modify { id = "angPolyDeg", visible = isPoly }

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

        dlg:modify { id = "useSeedRatio", visible = isVesica }
        dlg:modify { id = "usePivot", visible = isVesica }
        dlg:modify { id = "angVesicaDeg", visible = isVesica }
    end,
}

dlg:newrow { always = false }

dlg:combobox {
    id = "arcMode",
    label = "Type:",
    option = defaults.arcMode,
    options = arcModes,
    focus = false,
    visible = defaults.diagOption == "ARC"
}

dlg:newrow { always = false }

dlg:slider {
    id = "arcStartDeg",
    label = "Start:",
    value = defaults.arcStartDeg,
    min = 0,
    max = 360,
    focus = false,
    visible = defaults.diagOption == "ARC",
}

dlg:slider {
    id = "arcStopDeg",
    label = "Stop:",
    value = defaults.arcStopDeg,
    min = 0,
    max = 360,
    focus = false,
    visible = defaults.diagOption == "ARC",
}

dlg:newrow { always = false }

dlg:slider {
    id = "dimetricCount",
    label = "Count:",
    value = defaults.dimetricCount,
    min = defaults.minDimetric,
    max = defaults.maxDimetric,
    focus = false,
    visible = defaults.diagOption == "DIMETRIC_GRID",
}

dlg:newrow { always = false }

dlg:slider {
    id = "angEggDeg",
    label = "Angle:",
    value = defaults.angEggDeg,
    min = -180,
    max = 180,
    focus = false,
    visible = defaults.diagOption == "EGG",
}

dlg:newrow { always = false }

dlg:slider {
    id = "hexRings",
    label = "Rings:",
    value = defaults.hexRings,
    min = defaults.minRings,
    max = defaults.maxRings,
    focus = false,
    visible = defaults.diagOption == "HEX_GRID",
}

dlg:newrow { always = false }

dlg:check {
    id = "useDimetric",
    label = "Scale:",
    text = "Dimetric",
    selected = defaults.useDimetric,
    focus = false,
    visible = defaults.diagOption == "HEX_GRID",
}

dlg:newrow { always = false }

dlg:slider {
    id = "polyIter",
    label = "Count:",
    value = defaults.polyIter,
    min = defaults.minIter,
    max = defaults.maxIter,
    focus = false,
    visible = defaults.diagOption == "NESTED_CIRCLES",
}

dlg:newrow { always = false }

dlg:slider {
    id = "sidesPoly",
    label = "Sides:",
    value = defaults.sidesPoly,
    min = defaults.polyMin,
    max = defaults.polyMax,
    focus = false,
    visible = defaults.diagOption == "INSCRIBED_POLY",
}

dlg:newrow { always = false }

dlg:slider {
    id = "angPolyDeg",
    label = "Angle:",
    value = defaults.angPolyDeg,
    min = -180,
    max = 180,
    focus = false,
    visible = defaults.diagOption == "INSCRIBED_POLY",
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
    text = "Guides",
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

dlg:slider {
    id = "angVesicaDeg",
    label = "Angle:",
    value = defaults.angVesicaDeg,
    min = -180,
    max = 180,
    focus = false,
    visible = defaults.diagOption == "VESICA_PISCIS",
}

dlg:newrow { always = false }

dlg:check {
    id = "useSeedRatio",
    label = "Enable:",
    text = "Seed of Life",
    selected = defaults.useSeedRatio,
    focus = false,
    visible = defaults.diagOption == "VESICA_PISCIS",
}

dlg:check {
    id = "usePivot",
    text = "Pivot",
    selected = defaults.usePivot,
    focus = false,
    visible = defaults.diagOption == "VESICA_PISCIS",
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

dlg:check {
    id = "useTrimAlpha",
    text = "Trim",
    selected = defaults.useTrimAlpha,
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
                width = defaults.wSprite,
                height = defaults.hSprite,
                colorMode = ColorMode.RGB,
                transparentColor = 0
            }
            defSpec.colorSpace = ColorSpace { sRGB = true }
            sprite = Sprite(defSpec)

            local docPrefs <const> = app.preferences.document(sprite)
            if docPrefs then
                local bgPref <const> = docPrefs.bg
                if bgPref then
                    bgPref.type = 5
                    bgPref.size = Size(
                        defaults.wBkgCheck,
                        defaults.hBkgCheck)
                end
            end
            sprite.gridBounds = Rectangle(
                0, 0,
                defaults.wBkgCheck,
                defaults.hBkgCheck)

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
        local useTrimAlpha <const> = args.useTrimAlpha --[[@as boolean]]
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
        local pi <const> = math.pi
        local tau <const> = pi + pi
        local phi <const> = (1 + math.sqrt(5)) / 2

        local gridName = "Layer"
        if diagOption == "ARC" then
            local arcMode <const> = args.arcMode
                or defaults.arcMode --[[@as string]]
            local arcStartDeg <const> = args.arcStartDeg
                or defaults.arcStartDeg --[[@as integer]]
            local arcStopDeg <const> = args.arcStopDeg
                or defaults.arcStopDeg --[[@as integer]]

            gridName = string.format(
                "Arc from %d to %d",
                arcStartDeg, arcStopDeg)

            local arcStartRad <const> = math.rad(arcStartDeg)
            local arcStopRad <const> = math.rad(arcStopDeg)
            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            drawArc(context, arcMode,
                xCenter, yCenter,
                xRadius, yRadius,
                arcStartRad, arcStopRad,
                strokeColor, strokeWeight,
                useAntialiasVerif)
        elseif diagOption == "DIMETRIC_GRID" then
            local dimetricCount <const> = args.dimetricCount
                or defaults.dimetricCount --[[@as integer]]

            gridName = string.format("Dimetric Grid %d", dimetricCount)

            local count <const> = 1 + math.max(1, math.abs(dimetricCount))
            local halfEdge <const> = shortEdge * 0.5
            local qrtrEdge <const> = shortEdge * 0.25

            local i = 0
            while i < count do
                local t <const> = i / (count - 1.0)
                local so <const> = t * shortEdge - halfEdge
                local soHalf <const> = 0.5 * so

                local xro0 <const> = so + halfEdge
                local yro0 <const> = soHalf - qrtrEdge
                local xrd0 <const> = so - halfEdge
                local yrd0 <const> = soHalf + qrtrEdge

                local xro1 <const> = -halfEdge - so
                local yro1 <const> = soHalf - qrtrEdge
                local xrd1 <const> = halfEdge - so
                local yrd1 <const> = qrtrEdge + soHalf

                drawLine(context,
                    xCenter + xCorrect * xro0, yCenter + yCorrect * yro0,
                    xCenter + xCorrect * xrd0, yCenter + yCorrect * yrd0,
                    strokeColor, strokeWeight)

                drawLine(context,
                    xCenter + xCorrect * xro1, yCenter + yCorrect * yro1,
                    xCenter + xCorrect * xrd1, yCenter + yCorrect * yrd1,
                    strokeColor, strokeWeight)

                i = i + 1
            end
        elseif diagOption == "EGG" then
            local angEggDeg <const> = args.angEggDeg
                or defaults.angEggDeg --[[@as integer]]

            gridName = string.format("Egg (%d)", angEggDeg)

            local yDsp <const> = 0.22400923773979597

            ---@type number[][]
            local points <const> = {
                -- 0 Right knot
                { 0.7759907622602041,   -0.4285678640058835 - yDsp }, -- rh
                { 0.7759907622602041,   -yDsp },                      -- co
                { 0.7759907622602041,   0.4285678640058835 - yDsp },  -- fh

                -- 1 Top Right knot
                { 0.6124788925312299,   0.8063636657377999 - yDsp }, -- rh
                { 0.3214258980044128,   1.097416660264617 - yDsp },  -- co
                { 0.23277713973922606,  1.1768074267379347 - yDsp }, -- fh

                -- 2 Top knot
                { 0.11882188744996118,  1.224009237739796 - yDsp }, -- rh
                { 0.0,                  1.224009237739796 - yDsp }, -- co
                { -0.11882188744996118, 1.224009237739796 - yDsp }, -- fh

                -- 3 Top left knot
                { -0.23277713973922606, 1.1768074267379347 - yDsp }, -- rh
                { -0.3214258980044128,  1.097416660264617 - yDsp },  -- co
                { -0.6124788925312299,  0.8063636657377999 - yDsp }, -- fh

                -- 4 Left knot
                { -0.7759907622602041,  0.4285678640058835 - yDsp },  -- rh
                { -0.7759907622602041,  -yDsp },                      -- co
                { -0.7759907622602041,  -0.4285678640058835 - yDsp }, -- fh

                -- 5 Bottom knot
                { -0.4285678640058835,  -0.7759907622602041 - yDsp }, -- rh
                { 0.0,                  -0.7759907622602041 - yDsp }, -- co
                { 0.4285678640058835,   -0.7759907622602041 - yDsp }, -- fh
            }

            local angEggRad <const> = math.rad(angEggDeg)
            local cosa <const> = math.cos(angEggRad)
            local sina <const> = math.sin(angEggRad)
            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            local lenPoints <const> = #points
            local i = 0
            while i < lenPoints do
                i = i + 1
                local point <const> = points[i]
                local x <const> = point[1]
                local y <const> = point[2]
                local xRot <const> = cosa * x - sina * y
                local yRot <const> = cosa * y + sina * x
                points[i][1] = xCenter + xRadius * xRot
                -- If you wanted to rotate around base circle, could add
                -- displace here.
                -- points[i][2] = yCenter - yRadius * yRot + yDisplace
                points[i][2] = yCenter - yRadius * yRot
            end

            context:beginPath()
            context:moveTo(points[2][1], points[2][2])
            local j = 0
            while j < lenPoints do
                local idx0 <const> = 1 + (2 + j) % lenPoints
                local idx1 <const> = 1 + (3 + j) % lenPoints
                local idx2 <const> = 1 + (4 + j) % lenPoints
                context:cubicTo(
                    points[idx0][1], points[idx0][2],
                    points[idx1][1], points[idx1][2],
                    points[idx2][1], points[idx2][2])
                j = j + 3
            end
            context:closePath()

            context.strokeWidth = strokeWeight
            context.color = strokeColor
            context:stroke()
        elseif diagOption == "GOLDEN_RECT" then
            gridName = "Golden Rectangle"

            -- Same as phi ^ -1, phi ^ -2, etc.
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
            drawArc(context, "STROKE",
                xConst1, bottom,
                rx, ry,
                pi * 0.5, pi,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawArc(context, "STROKE",
                xConst1, yConst2,
                rx * phiInv, ry * phiInv,
                0.0, pi * 0.5,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawArc(context, "STROKE",
                xConst3, yConst2,
                rx * phiInvE2, ry * phiInvE2,
                pi * 1.5, tau,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawArc(context, "STROKE",
                xConst3, yConst4,
                rx * phiInvE3, ry * phiInvE3,
                pi, pi * 1.5,
                strokeColor, strokeWeight,
                useAntialiasVerif)

            drawArc(context, "STROKE",
                xConst5, yConst4,
                rx * phiInvE4, ry * phiInvE4,
                pi * 0.5, pi,
                strokeColor, strokeWeight,
                useAntialiasVerif)
        elseif diagOption == "HEX_GRID" then
            local rings <const> = args.hexRings
                or defaults.hexRings --[[@as integer]]
            local useDimetric <const> = args.useDimetric --[[@as boolean]]

            gridName = string.format("Hexagon Grid %d", rings)

            local iMax <const> = rings - 1
            local iMin <const> = -iMax

            -- sqrt(3) / 2 = 0.8660254
            local dimScale <const> = useDimetric
                and (1.1547005383793 * xCorrect)
                or xCorrect
            local halfEdge <const> = shortEdge * 0.5
            local radius <const> = halfEdge / (rings * 2 - 1)
            local extent <const> = radius * 1.7320508075688772
            local xRadius <const> = dimScale * radius
            local xHalfExt <const> = dimScale * extent * 0.5
            local xCorrExt <const> = dimScale * extent
            local yRadius <const> = yCorrect * radius
            local yRad1_5 <const> = yCorrect * radius * 1.5
            local orientation <const> = pi * 1.5

            if rings > 1 then
                drawPolygon(
                    context,
                    xCenter, yCenter,
                    dimScale * halfEdge,
                    yCorrect * halfEdge,
                    6, orientation,
                    strokeColor, strokeWeight,
                    useAntialiasVerif)
            end

            local i = iMin - 1
            while i < iMax do
                i = i + 1

                local jMin = iMin
                local jMax = iMax
                if i < 0 then jMin = jMin - i end
                if i > 0 then jMax = jMax - i end
                local iExt <const> = i * xCorrExt

                local j = jMin - 1
                while j < jMax do
                    j = j + 1

                    local x <const> = xCenter + iExt + j * xHalfExt
                    local y <const> = yCenter + j * yRad1_5
                    drawPolygon(
                        context,
                        x, y,
                        xRadius, yRadius,
                        6, orientation,
                        strokeColor, strokeWeight,
                        useAntialiasVerif)
                end
            end
        elseif diagOption == "IN_CIRCLE" then
            gridName = "In Circle"

            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            drawEllipse(
                context,
                xCenter, yCenter,
                xRadius, yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)
        elseif diagOption == "IN_SQUARE" then
            gridName = "In Square"

            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            drawRect(
                context,
                xCenter, yCenter,
                xRadius, yRadius,
                strokeColor, strokeWeight,
                useAntialiasVerif)
        elseif diagOption == "INSCRIBED_POLY" then
            local polyIter <const> = args.polyIter
                or defaults.polyIter --[[@as integer]]
            local sidesPoly <const> = args.sidesPoly
                or defaults.sidesPoly --[[@as integer]]
            local angPolyDeg <const> = args.angPolyDeg
                or defaults.angPolyDeg --[[@as integer]]

            local sidesVerif <const> = math.max(3, math.abs(sidesPoly))
            local angPolyRad <const> = math.rad(270 - angPolyDeg)
            local toTheta <const> = tau / sidesVerif

            local rScalar <const> = math.cos(0.5 * toTheta)

            gridName = string.format("Inscribed Polygon %d (%d)", sidesVerif, angPolyDeg)

            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            local xr = xRadius
            local yr = yRadius
            local ang = angPolyRad

            local i = 0
            while i < polyIter do
                drawPolygon(
                    context,
                    xCenter, yCenter,
                    xr, yr,
                    sidesVerif, ang,
                    strokeColor, strokeWeight,
                    useAntialias)

                xr = xr * rScalar
                yr = yr * rScalar
                ang = ang + toTheta * 0.5

                i = i + 1
            end
        elseif diagOption == "NESTED_CIRCLES" then
            local count <const> = args.nestedCount
                or defaults.nestedCount --[[@as integer]]
            local showMeasure <const> = args.showMeasure --[[@as boolean]]
            local showBottom <const> = args.showBottom --[[@as boolean]]
            local showTop <const> = args.showTop --[[@as boolean]]

            gridName = string.format("Nested Circles %d", count)

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

            local angOffsetRad <const> = math.rad(angOffsetDeg)

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

            ---@type number[][]
            local points <const> = {
                { xCenter + xRadius, yCenter },           -- right edge middle
                { xCenter + xRadius, yCenter - yRadius }, -- top right corner
                { xCenter,           yCenter - yRadius }, -- top edge middle
                { xCenter - xRadius, yCenter - yRadius }, -- top left corner
                { xCenter - xRadius, yCenter },           -- left edge middle
                { xCenter - xRadius, yCenter + yRadius }, -- bottom left corner
                { xCenter,           yCenter + yRadius }, -- bottom edge middle
                { xCenter + xRadius, yCenter + yRadius }, -- bottom right corner
            }
            local lenPoints <const> = #points

            local j = 0
            while j < lenPoints do
                local k <const> = (j + 3) % lenPoints
                drawLine(context,
                    points[1 + j][1], points[1 + j][2],
                    points[1 + k][1], points[1 + k][2],
                    strokeColor, strokeWeight)
                j = j + 1
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
            local angStarRad <const> = math.rad(270 - angStarDeg)
            local toTheta <const> = tau / sidesVerif
            local skip <const> = math.ceil(sidesVerif / 3)

            gridName = string.format("Star %d (%d)", sidesVerif, angStarDeg)

            local xRadius <const> = xCorrect * shortEdge * 0.5
            local yRadius <const> = yCorrect * shortEdge * 0.5

            drawPolygon(
                context,
                xCenter, yCenter,
                xRadius, yRadius,
                sidesVerif, angStarRad,
                strokeColor, strokeWeight,
                useAntialias)

            local i = 0
            while i < sidesVerif do
                local j <const> = (i + skip) % sidesVerif
                local theta0 <const> = i * toTheta - angStarRad
                local theta1 <const> = j * toTheta - angStarRad

                drawLine(context,
                    xCenter + xRadius * cos(theta0),
                    yCenter - yRadius * sin(theta0),
                    xCenter + xRadius * cos(theta1),
                    yCenter - yRadius * sin(theta1),
                    strokeColor, strokeWeight)

                i = i + 1
            end
        elseif diagOption == "VESICA_PISCIS" then
            local angVesicaDeg <const> = args.angVesicaDeg
                or defaults.angVesicaDeg --[[@as integer]]
            local useSeedRatio <const> = args.useSeedRatio --[[@as boolean]]
            local usePivot <const> = args.usePivot --[[@as boolean]]

            gridName = string.format("Vesica Piscis (%d)", angVesicaDeg)

            ---@type number[][]
            local points <const> = useSeedRatio and
                {
                    -- Right
                    { 0.6959615803137228,  -0.1755366634498615 }, -- rh
                    { 1.0,                 0.0 },                 -- co
                    { 0.6959615803137228,  0.1755366634498615 },  -- fh

                    -- Top
                    { 0.3510733268997226,  0.26794919243112276 }, -- rh
                    { 0.0,                 0.26794919243112276 }, -- co
                    { -0.3510733268997226, 0.26794919243112276 }, -- fh

                    -- Left
                    { -0.6959615803137228, 0.1755366634498615 },  -- rh
                    { -1.0,                0.0 },                 -- co
                    { -0.6959615803137228, -0.1755366634498615 }, -- fh

                    -- Bottom
                    { -0.3510733268997226, -0.26794919243112276 }, -- rh
                    { 0.0,                 -0.26794919243112276 }, -- co
                    { 0.3510733268997226,  -0.26794919243112276 }, -- fh
                }
                or {
                    -- Right
                    { 0.7937326154943315,  -0.35726558990816354 }, -- rh
                    { 1.0,                 0.0 },                  -- co
                    { 0.7937326154943315,  0.35726558990816354 },  -- fh

                    -- Top
                    { 0.4125347690113375,  0.5773502691896258 }, -- rh
                    { 0.0,                 0.5773502691896258 }, -- co
                    { -0.4125347690113375, 0.5773502691896258 }, -- fh

                    -- Left
                    { -0.7937326154943315, 0.35726558990816354 },  -- rh
                    { -1.0,                0.0 },                  -- co
                    { -0.7937326154943315, -0.35726558990816354 }, -- fh

                    -- Bottom
                    { -0.4125347690113375, -0.5773502691896258 }, -- rh
                    { 0.0,                 -0.5773502691896258 }, -- co
                    { 0.4125347690113375,  -0.5773502691896258 }, -- fh
                }

            local pivotScalar <const> = usePivot and 0.5 or 1.0
            local xPivot <const> = usePivot and 1.0 or 0.0
            local yPivot <const> = 0.0

            local angVesicaRad <const> = math.rad(angVesicaDeg)
            local cosa <const> = math.cos(angVesicaRad)
            local sina <const> = math.sin(angVesicaRad)
            local xRadius <const> = pivotScalar * xCorrect * shortEdge * 0.5
            local yRadius <const> = pivotScalar * yCorrect * shortEdge * 0.5

            local lenPoints <const> = #points
            local i = 0
            while i < lenPoints do
                i = i + 1
                local point <const> = points[i]
                local x <const> = point[1] + xPivot
                local y <const> = point[2] - yPivot
                local xRot <const> = cosa * x - sina * y
                local yRot <const> = cosa * y + sina * x
                points[i][1] = xCenter + xRadius * xRot
                points[i][2] = yCenter - yRadius * yRot
            end

            context:beginPath()
            context:moveTo(points[2][1], points[2][2])
            local j = 0
            while j < lenPoints do
                local idx0 <const> = 1 + (2 + j) % lenPoints
                local idx1 <const> = 1 + (3 + j) % lenPoints
                local idx2 <const> = 1 + (4 + j) % lenPoints
                context:cubicTo(
                    points[idx0][1], points[idx0][2],
                    points[idx1][1], points[idx1][2],
                    points[idx2][1], points[idx2][2])
                j = j + 3
            end
            context:closePath()

            context.strokeWidth = strokeWeight
            context.color = strokeColor
            context:stroke()
        else
            app.alert {
                title = "Error",
                text = "Unrecognized diagram option."
            }
            return
        end

        local frObjs <const> = sprite.frames
        local lenFrObjs <const> = #frObjs
        local activeLayer <const> = app.layer
            or sprite.layers[1] --[[@as Layer]]
        local activeFrObj <const> = app.frame
            or frObjs[1] --[[@as Frame]]
        local isBkg <const> = activeLayer.isBackground
        local stackIndex <const> = activeLayer.stackIndex
        local hasBkg <const> = sprite.backgroundLayer ~= nil

        local xtl = 0
        local ytl = 0
        local trgImg = image
        if useTrimAlpha then
            local alphaIndex <const> = spriteSpec.transparentColor
            local rect <const> = image:shrinkBounds(alphaIndex)
            if rect.width > 0 and rect.height > 0 then
                xtl = rect.x
                ytl = rect.y

                local trSpec <const> = ImageSpec {
                    width = rect.width,
                    height = rect.height,
                    colorMode = colorMode,
                    transparentColor = alphaIndex
                }
                trSpec.colorSpace = spriteSpec.colorSpace
                trgImg = Image(trSpec)
                trgImg:drawImage(image, Point(-xtl, -ytl), 255, BlendMode.SRC)
            end
        end

        app.transaction("Diagram", function()
            local gridLayer <const> = sprite:newLayer()

            -- There could be an option to choose active or range frames
            -- instead of all. However, the control flow for this is finicky.
            -- Getting those frames outside the transaction immediately above
            -- results in inappropriately offset frames.
            local k = 0
            while k < lenFrObjs do
                k = k + 1
                sprite:newCel(gridLayer, k, trgImg, Point(xtl, ytl))
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
                gridLayer.stackIndex = isBkg and 2 or 1
            elseif layerPlace == "ABOVE" then
                gridLayer.stackIndex = stackIndex + 1
            elseif layerPlace == "BELOW" then
                gridLayer.stackIndex = isBkg and stackIndex + 1 or stackIndex
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