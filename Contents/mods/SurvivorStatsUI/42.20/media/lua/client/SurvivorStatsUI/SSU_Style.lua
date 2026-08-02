SSU_Style = SSU_Style or {}

SSU_Style.colors = {
    accent = { r = 0.39, g = 0.78, b = 0.38 },
    header = { r = 0.075, g = 0.078, b = 0.072, a = 0.97 },
    body = { r = 0.13, g = 0.125, b = 0.105, a = 0.94 },
    row = { r = 0.18, g = 0.17, b = 0.14, a = 0.34 },
    border = { r = 0.31, g = 0.29, b = 0.24, a = 0.86 },
    text = { r = 0.91, g = 0.90, b = 0.83 },
    dim = { r = 0.66, g = 0.66, b = 0.61 },
}

function SSU_Style.drawWindow(element, width, height, headerHeight)
    local c = SSU_Style.colors
    -- Cantos discretamente arredondados sem depender de texturas externas.
    element:drawRect(2, 0, width - 4, headerHeight, c.header.a, c.header.r, c.header.g, c.header.b)
    element:drawRect(0, 2, width, headerHeight - 2, c.header.a, c.header.r, c.header.g, c.header.b)
    if height > headerHeight then
        element:drawRect(0, headerHeight, width, height - headerHeight - 2, c.body.a, c.body.r, c.body.g, c.body.b)
        element:drawRect(2, height - 2, width - 4, 2, c.body.a, c.body.r, c.body.g, c.body.b)
    end
    element:drawRect(0, headerHeight - 1, width, 1, 0.72, c.border.r, c.border.g, c.border.b)
    element:drawRectBorder(2, 0, width - 4, height, c.border.a, c.border.r, c.border.g, c.border.b)
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
