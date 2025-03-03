-- archivo que va a construir toda la ui.

local ui = {}

-- variables

local solver = require "assets/scripts/solver"

local fullscreen = false
local safe_x, safe_y, safe_w, safe_h = 0, 0, 0, 0

local ui_unit = {x = 0, y = 0}
local area = {x = 0, y = 0}

-- Add these tables to store vertices
ui.vertices = {0, 0, 0, 0, 0, 0}
ui.scaledVertices = {0, 0, 0, 0, 0, 0}

-- Add these as module variables
ui.inputText = ""
ui.selectedInput = nil

-- fuente
local font_scp_16 = love.graphics.newFont("assets/fonts/SourceCodePro-Regular.otf", 16)
local font_scp_32 = love.graphics.newFont("assets/fonts/SourceCodePro-Regular.otf", 32)

--[[
vertices = {
    solver.Triangle.vertices.x1, solver.Triangle.vertices.y1,
    solver.Triangle.vertices.x2, solver.Triangle.vertices.y2,
    solver.Triangle.vertices.x3, solver.Triangle.vertices.y3
}]]

local ui_button_1 = { -- botón para establecer el triángulo en Rectángulo
    min_x = 0,
    max_x = 33.33,  -- safe_w/3
    min_y = 15,     -- safe_h * 0.15
    max_y = 30      -- min_y + buttonsizeH
}

local ui_button_2 = { -- botón para establecer el triángulo en Equilátero
    min_x = 33.33,
    max_x = 66.66,
    min_y = 15,
    max_y = 30
}

local ui_button_3 = { -- botón para establecer el triángulo en Escaleno
    min_x = 66.66,
    max_x = 100,
    min_y = 15,
    max_y = 30
}

local ui_button_4 = { -- ocultar teclado 1
    min_x = 1,
    max_x = 99,
    min_y = 101,
    max_y = 135
}

local ui_button_5 = {
    min_x = 1,
    max_x = 89,     -- Esta será ajustada dinámicamente en DrawNavUi
    min_y = 89,
    max_y = 99
}

local ui_button_6 = {
    min_x = 89,     -- Esta será ajustada dinámicamente en DrawNavUi
    max_x = 99,
    min_y = 89,
    max_y = 99
}

local ui_button_7 = { -- ocultar teclado 2
    min_x = 0,
    max_x = 100,
    min_y = 31,
    max_y = 88
}

-- funciones auxiliares:

function DrawTriTypeSelect()
    local buttonLabels = {"Rectángulo", "Equilátero", "Escaleno"}
    local buttons = {ui_button_1, ui_button_2, ui_button_3}
    
    for i, button in ipairs(buttons) do
        DrawButton(button.min_x*ui_unit.x, button.min_y*ui_unit.y,
                  (button.max_x-button.min_x)*ui_unit.x,
                  (button.max_y-button.min_y)*ui_unit.y,
                  1, 1, 1, i, buttonLabels[i])
    end
end

-- Modificar la función DrawNavUi
function DrawNavUi()
    -- Botón Hide (id == 4)
    DrawButton(ui_button_4.min_x*ui_unit.x, ui_button_4.min_y*ui_unit.y, 
               (ui_button_4.max_x-ui_button_4.min_x)*ui_unit.x, 
               (ui_button_4.max_y-ui_button_4.min_y)*ui_unit.y, 
               0, 0.19, 0.26, 4, "Toca para volver")

    -- Calcular el ancho del botón 6 (igual a su alto)
    local button6_height = (ui_button_6.max_y - ui_button_6.min_y) * ui_unit.y
    local button6_width = button6_height  -- El ancho será igual al alto
    
    -- Ajustar la posición X del botón 6
    local button6_x = 99 * ui_unit.x - button6_width
    
    -- Ajustar el ancho del botón 5 para que termine donde empieza el botón 6
    local button5_width = button6_x - (ui_button_5.min_x * ui_unit.x)
    
    -- Dibujar botón 5 (Show Keyboard)
    DrawButton(ui_button_5.min_x*ui_unit.x, ui_button_5.min_y*ui_unit.y,
               button5_width,
               (ui_button_5.max_y-ui_button_5.min_y)*ui_unit.y,
               1, 1, 1, 5, "Show Keyboard")
    
    -- Dibujar botón 6 (Set)
    DrawButton(button6_x, ui_button_6.min_y*ui_unit.y,
               button6_width,
               (ui_button_6.max_y-ui_button_6.min_y)*ui_unit.y,
               1, 1, 1, 6, "Set")
end

-- pos x, pos y, ancho, alto, r, g, b, id, texto
function DrawButton(x, y, w, h, r, g, b, id, text)
    love.graphics.push("all")

    local offsetx, offsety = Centrado(w, h, w*0.95, h*0.95)

    if id <= 3 and id == TriState then
        love.graphics.setColor(r,g,b, 0.2)
        love.graphics.rectangle("fill", x + offsetx, y + offsety, w*0.95, h*0.95)
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(r,g,b, 1)
        love.graphics.rectangle("fill", x + offsetx, y + offsety, w*0.95, h*0.95)
        love.graphics.setColor(0, 0.19, 0.26, 1)
    end

    if id == 4 then
        love.graphics.setColor(1,1,1,1)
    end
    
    -- setear la fuente grande
    love.graphics.setFont(font_scp_32)
    -- Mostrar el texto de entrada si es el botón 5
    if id == 5 then
        local displayText = ui.inputText
        if displayText == "" then
            if ui.selectedInput then
                displayText = "editar " .. ui.selectedInput
            else
                displayText = "Pulsa un lado o un vértice"
            end
        else
            if ui.selectedInput then
                displayText = ui.selectedInput .. ": " .. ui.inputText
                -- Añadir el símbolo de grado si es un ángulo
                if ui.selectedInput:match("[ABC]") then
                    displayText = displayText .. "°"
                end
            end
        end
        -- Usar fuente más pequeña para textos largos
        local fuente = (#displayText > 10) and font_scp_16 or font_scp_32
        Textocentrado(displayText, x + w/2, y + h/2, fuente, id)
    else
        Textocentrado(text, x + w/2, y + h/2)
    end
    love.graphics.pop()
end

-- función generada por copilot
function GetTriangleDimensions(vertices)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    -- Encontrar los valores extremos
    for i = 1, #vertices, 2 do
        local x, y = vertices[i], vertices[i + 1]
        minX = math.min(minX, x)
        maxX = math.max(maxX, x)
        minY = math.min(minY, y)
        maxY = math.max(maxY, y)
    end

    -- Calcular dimensiones y origen
    local width = maxX - minX
    local height = maxY - minY
    local originX = minX
    local originY = minY

    return width, height, originX, originY
end

-- Centra un objeto dentro de un contenedor, devolviendo los offsets en X e Y.
-- contW Ancho del contenedor.
-- contH Alto del contenedor.
-- bjW Ancho del objeto.
-- objH Alto del objeto.
-- aliX (Opcional) Alineación horizontal (0: izquierda, 1: derecha; por defecto 0.5).
-- aliY (Opcional) Alineación vertical (0: arriba, 1: abajo; por defecto 0.5).
-- return offX, offY: Desplazamientos en X e Y para alinear el objeto según lo indicado.
function Centrado(contW, contH, objW, objH, aliX, aliY)
  -- por defecto alinear al centro en X y Y.
  aliX = aliX or 0.5
  aliY = aliY or 0.5

  local offX = (contW - objW) * aliX
  local offY = (contH - objH) * aliY

  return offX, offY
end

function Textocentrado(texto, x, y, fuente, id, bold)
    love.graphics.push()
    fuente = fuente or font_scp_16
    love.graphics.setFont(fuente)
    
    -- Si estamos en el botón de entrada (ID 5), alinear a la izquierda con margen
    if (id == 5) then
        local offsetx = 6*ui_unit.x  -- margen fijo de 10 pixels
        local offsety = fuente:getHeight() / 2
        love.graphics.translate(math.floor(offsetx), math.floor(y - offsety))
    else
        -- Comportamiento normal centrado
        local offsetx = fuente:getWidth(texto) / 2
        local offsety = fuente:getHeight() / 2
        love.graphics.translate(math.floor(x - offsetx), math.floor(y - offsety))
    end
    
    if bold then

    end
    love.graphics.print(texto)
    love.graphics.pop()
end

function DrawTri()
    love.graphics.push()

    if ui.debug then
        love.graphics.setColor(1,1,1,0.25)
        love.graphics.rectangle("fill", 25*ui_unit.x*0.5, ui_unit.y * 40, area.x, area.y)
    end

    -- Obtener las dimensiones y origen del triángulo
    local triWidth, triHeight, originX, originY = GetTriangleDimensions(ui.scaledVertices)
    local offx, offy = Centrado(area.x, area.y, triWidth, triHeight)
    
    -- Ajustar la traslación considerando el origen del triángulo
    love.graphics.translate(25 * ui_unit.x * 0.5 + offx - originX, ui_unit.y * 40 + offy - originY)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.polygon("fill", ui.scaledVertices)

    -- Calcular puntos medios de los lados
    local midpoints = {
        -- Punto medio del lado a (entre v2 y v3)
        {(ui.scaledVertices[3] + ui.scaledVertices[5])/2, (ui.scaledVertices[4] + ui.scaledVertices[6])/2},
        -- Punto medio del lado b (entre v1 y v3)
        {(ui.scaledVertices[1] + ui.scaledVertices[5])/2, (ui.scaledVertices[2] + ui.scaledVertices[6])/2},
        -- Punto medio del lado c (entre v1 y v2)
        {(ui.scaledVertices[1] + ui.scaledVertices[3])/2, (ui.scaledVertices[2] + ui.scaledVertices[4])/2}
    }

    -- Calcular las dimensiones de los círculos
    local circleunit
    if ui_unit.x > ui_unit.y then
        circleunit = ui_unit.y
    else
        circleunit = ui_unit.x
    end

    -- Dibujar círculos en los vértices si estamos en modo debug
    if ui.debug then
        love.graphics.setColor(1, 0, 0, 0.5)
        for i = 1, 3 do
        love.graphics.circle("fill", ui.scaledVertices[i*2-1], ui.scaledVertices[i*2], 7*circleunit)
        end
    elseif ui.debug == false then
        love.graphics.setColor(0.0, 0.11, 0.16, 1)
        for i = 1, 3 do
        love.graphics.circle("fill", ui.scaledVertices[i*2-1], ui.scaledVertices[i*2], 7*circleunit)
        end
    end

    -- Mostrar valores de los ángulos en los vértices
    love.graphics.setFont(font_scp_16)
    for i = 1, 3 do
        love.graphics.setColor(1, 1, 1, 1)
        local value = "?"  -- Valor por defecto si no hay dato
        if i == 1 then 
            -- value = "A: " .. (solver.Triangle.angles.A and string.format("%.2f", solver.Triangle.angles.A) or "?") .. "°"
            value = "A: " .. (solver.Triangle.angles.A and string.format("%.1f", solver.Triangle.angles.A) or "?") .. "°"
        elseif i == 2 then
            -- value = "B: " .. (solver.Triangle.angles.B and string.format("%.2f", solver.Triangle.angles.B) or "?") .. "°"
            value = "B: " .. (solver.Triangle.angles.B and string.format("%.1f", solver.Triangle.angles.B) or "?") .. "°"
        elseif i == 3 then
            -- value = "C: " .. (solver.Triangle.angles.C and string.format("%.2f", solver.Triangle.angles.C) or "?") .. "°"
            value = "C: " .. (solver.Triangle.angles.C and string.format("%.1f", solver.Triangle.angles.C) or "?") .. "°"
        end
        
        -- Mostrar texto cerca del vértice
        Textocentrado(value, ui.scaledVertices[i*2-1], ui.scaledVertices[i*2])
    end

    -- Dibujar círculos en los puntos medios y mostrar valores
    love.graphics.setFont(font_scp_16)
    for i, midpoint in ipairs(midpoints) do
        -- Dibujar círculo
        if ui.debug then
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.circle("fill", midpoint[1], midpoint[2], 7*circleunit)
        elseif ui.debug == false then
        love.graphics.setColor(0.0, 0.11, 0.16, 1)
        love.graphics.circle("fill", midpoint[1], midpoint[2], 7*circleunit)
        end
        
        -- Mostrar valor del lado/ángulo
        love.graphics.setColor(1, 1, 1, 1)
        local value = "?"  -- Valor por defecto si no hay dato
        if i == 1 then 
            value = "a: " .. (solver.Triangle.sides.a and string.format("%.2f", solver.Triangle.sides.a) or "?")
        elseif i == 2 then 
            value = "b: " .. (solver.Triangle.sides.b and string.format("%.2f", solver.Triangle.sides.b) or "?")
        elseif i == 3 then 
            value = "c: " .. (solver.Triangle.sides.c and string.format("%.2f", solver.Triangle.sides.c) or "?")
        end
        
        Textocentrado(value, midpoint[1], midpoint[2])
    end

    love.graphics.pop()
end

-- funciones que necesitan ser actualizadas constantemente

function ui.actualizar()
    safe_x, safe_y, safe_w, safe_h = love.window.getSafeArea()
    ui_unit.x = safe_w / 100
    ui_unit.y = safe_h / 100

    area = {x = 75*ui_unit.x, y = 40*ui_unit.y}

    -- Use ui.vertices instead of vertices
    local triWidth, triHeight = GetTriangleDimensions(ui.vertices)

    -- Calcular factores de escala para ancho y alto
    local scaleX = area.x / triWidth
    local scaleY = area.y / triHeight
    
    -- Usar el factor más pequeño para mantener proporciones
    local scaleFactor = math.min(scaleX, scaleY)

    -- Aplicar el factor de escala a los vértices del triángulo
    for i = 1, #ui.vertices do
        ui.scaledVertices[i] = ui.vertices[i] * scaleFactor
    end

end

return ui