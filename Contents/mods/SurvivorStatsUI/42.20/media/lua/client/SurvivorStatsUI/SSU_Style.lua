SSU_Style = SSU_Style or {}

SSU_Style.colors = {
    accent = { r = 0.39, g = 0.78, b = 0.38 },
    header = { r = 0.075, g = 0.078, b = 0.072, a = 0.84 },
    body = { r = 0.13, g = 0.125, b = 0.105, a = 0.68 },
    row = { r = 0.18, g = 0.17, b = 0.14, a = 0.24 },
    border = { r = 0.31, g = 0.29, b = 0.24, a = 0.72 },
    text = { r = 0.91, g = 0.90, b = 0.83 },
    dim = { r = 0.66, g = 0.66, b = 0.61 },
}

local function drawRoundedFill(element, x, y, width, height, color)
    if width < 8 or height < 8 then
        element:drawRect(x, y, width, height, color.a, color.r, color.g, color.b)
        return
    end
    element:drawRect(x + 3, y, width - 6, 1, color.a, color.r, color.g, color.b)
    element:drawRect(x + 2, y + 1, width - 4, 1, color.a, color.r, color.g, color.b)
    element:drawRect(x + 1, y + 2, width - 2, 1, color.a, color.r, color.g, color.b)
    element:drawRect(x, y + 3, width, height - 6, color.a, color.r, color.g, color.b)
    element:drawRect(x + 1, y + height - 3, width - 2, 1, color.a, color.r, color.g, color.b)
    element:drawRect(x + 2, y + height - 2, width - 4, 1, color.a, color.r, color.g, color.b)
    element:drawRect(x + 3, y + height - 1, width - 6, 1, color.a, color.r, color.g, color.b)
end

local function drawRoundedBorder(element, width, height, color)
    element:drawRect(3, 0, width - 6, 1, color.a, color.r, color.g, color.b)
    element:drawRect(1, 1, 2, 1, color.a, color.r, color.g, color.b)
    element:drawRect(width - 3, 1, 2, 1, color.a, color.r, color.g, color.b)
    element:drawRect(0, 2, 1, height - 4, color.a, color.r, color.g, color.b)
    element:drawRect(width - 1, 2, 1, height - 4, color.a, color.r, color.g, color.b)
    element:drawRect(1, height - 2, 2, 1, color.a, color.r, color.g, color.b)
    element:drawRect(width - 3, height - 2, 2, 1, color.a, color.r, color.g, color.b)
    element:drawRect(3, height - 1, width - 6, 1, color.a, color.r, color.g, color.b)
end

function SSU_Style.drawWindow(element, width, height, headerHeight)
    local c = SSU_Style.colors
    drawRoundedFill(element, 0, 0, width, height, c.body)

    -- Cabecalho com cantos superiores arredondados.
    element:drawRect(3, 0, width - 6, 1, c.header.a, c.header.r, c.header.g, c.header.b)
    element:drawRect(2, 1, width - 4, 1, c.header.a, c.header.r, c.header.g, c.header.b)
    element:drawRect(1, 2, width - 2, 1, c.header.a, c.header.r, c.header.g, c.header.b)
    element:drawRect(0, 3, width, math.max(0, headerHeight - 3), c.header.a, c.header.r, c.header.g, c.header.b)

    element:drawRect(0, headerHeight - 1, width, 1, 0.58, c.border.r, c.border.g, c.border.b)
    drawRoundedBorder(element, width, height, c.border)
end

function SSU_Style.drawRow(element, x, y, width, height, alternate)
    local c = SSU_Style.colors
    local alpha = alternate and c.row.a or c.row.a * 0.45
    element:drawRect(x, y, width, height, alpha, c.row.r, c.row.g, c.row.b)
end

function SSU_Style.drawProgressBar(element, x, y, width, height, progress)
    local c = SSU_Style.colors
    progress = math.max(0, math.min(tonumber(progress) or 0, 1))
    element:drawRect(x, y, width, height, 0.88, 0.055, 0.055, 0.05)
    element:drawRectBorder(x, y, width, height, 0.72, c.border.r, c.border.g, c.border.b)
    local fill = math.floor((width - 4) * progress)
    if fill > 0 then
        element:drawRect(x + 2, y + 2, fill, height - 4, 0.96, c.accent.r, c.accent.g, c.accent.b)
    end
end

function SSU_Style.drawTrendArrow(element, x, y, direction)
    if direction ~= 1 and direction ~= -1 then return end

    local r, g, b = 0.38, 0.82, 0.40
    if direction < 0 then r, g, b = 0.88, 0.32, 0.26 end

    -- Seta desenhada em pixels para nao depender de glifos da fonte.
    if direction > 0 then
        element:drawRect(x + 3, y,     2, 2, 1, r, g, b)
        element:drawRect(x + 2, y + 2, 4, 2, 1, r, g, b)
        element:drawRect(x + 1, y + 4, 6, 2, 1, r, g, b)
        element:drawRect(x + 3, y + 6, 2, 5, 1, r, g, b)
    else
        element:drawRect(x + 3, y,     2, 5, 1, r, g, b)
        element:drawRect(x + 1, y + 5, 6, 2, 1, r, g, b)
        element:drawRect(x + 2, y + 7, 4, 2, 1, r, g, b)
        element:drawRect(x + 3, y + 9, 2, 2, 1, r, g, b)
    end
end
