-- SPDX-FileCopyrightText: 2024 dpkgluci
--
-- SPDX-License-Identifier: MIT

-- Copilot y Chatgpt han hecho de las suyas en este proyecto!!!
-- variables

math.randomseed(os.time())

trisolver = require("assets/scripts/tri-solver")
-- juego
TriState = 1
local debug = false
local fullscreen = false
local safe_x, safe_y, safe_w, safe_h = 0, 0, 0, 0

local ui_unit = {x = 0, y = 0}

local area = {x = 0, y = 0}

-- fuente
local font_scp_16 = love.graphics.newFont("assets/fonts/SourceCodePro-Regular.otf", 16)
local font_scp_32 = love.graphics.newFont("assets/fonts/SourceCodePro-Regular.otf", 32)

-- teclado de android
local keyboardOpen = false

-- Añadir estas variables al inicio del archivo
local keyboardOffset = 0
local keyboardHeight = 0

local ui_button_1 = {
    min_x = 0,
    max_x = 33.33,  -- safe_w/3
    min_y = 15,     -- safe_h * 0.15
    max_y = 30      -- min_y + buttonsizeH
}

local ui_button_2 = {
    min_x = 33.33,
    max_x = 66.66,
    min_y = 15,
    max_y = 30
}

local ui_button_3 = {
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

-- vertices del triangulo
local vertices = {0, 0, 0, 0, 0, 0}
local scaledVertices = {}
-- local triangulo = {}

local inputText = ""
local selectedInput = nil -- Para saber qué estamos editando (lado o ángulo)
local maxInputLength = 10 -- Limitar longitud del texto

-- Modificar la función DrawTriTypeSelect para usar estas variables
function DrawTriTypeSelect()
    local buttonLabels = {"Rect.", "Equil.", "Escal."}
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
        local displayText = inputText
        if displayText == "" then
            if selectedInput then
                displayText = "editar " .. selectedInput
            else
                displayText = "Pulsa un lado o un vértice"
            end
        else
            if selectedInput then
                displayText = selectedInput .. ": " .. inputText
                -- Añadir el símbolo de grado si es un ángulo
                if selectedInput:match("[ABC]") then
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

    if debug then
        love.graphics.setColor(1,1,1,0.25)
        love.graphics.rectangle("fill", 25*ui_unit.x*0.5, ui_unit.y * 40, area.x, area.y)
    end

    -- Obtener las dimensiones y origen del triángulo
    local triWidth, triHeight, originX, originY = GetTriangleDimensions(scaledVertices)
    local offx, offy = Centrado(area.x, area.y, triWidth, triHeight)
    
    -- Ajustar la traslación considerando el origen del triángulo
    love.graphics.translate(25 * ui_unit.x * 0.5 + offx - originX, ui_unit.y * 40 + offy - originY)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.polygon("fill", scaledVertices)

    -- Calcular puntos medios de los lados
    local midpoints = {
        -- Punto medio del lado a (entre v2 y v3)
        {(scaledVertices[3] + scaledVertices[5])/2, (scaledVertices[4] + scaledVertices[6])/2},
        -- Punto medio del lado b (entre v1 y v3)
        {(scaledVertices[1] + scaledVertices[5])/2, (scaledVertices[2] + scaledVertices[6])/2},
        -- Punto medio del lado c (entre v1 y v2)
        {(scaledVertices[1] + scaledVertices[3])/2, (scaledVertices[2] + scaledVertices[4])/2}
    }

    -- Calcular las dimensiones de los círculos
    local circleunit
    if ui_unit.x > ui_unit.y then
        circleunit = ui_unit.y
    else
        circleunit = ui_unit.x
    end

    -- Dibujar círculos en los vértices si estamos en modo debug
    if debug then
        love.graphics.setColor(1, 0, 0, 0.5)
        for i = 1, 3 do
        love.graphics.circle("fill", scaledVertices[i*2-1], scaledVertices[i*2], 7*circleunit)
        end
    elseif debug == false then
        love.graphics.setColor(0.0, 0.11, 0.16, 1)
        for i = 1, 3 do
        love.graphics.circle("fill", scaledVertices[i*2-1], scaledVertices[i*2], 7*circleunit)
        end
    end

    -- Mostrar valores de los ángulos en los vértices
    love.graphics.setFont(font_scp_16)
    for i = 1, 3 do
        love.graphics.setColor(1, 1, 1, 1)
        local value = "?"  -- Valor por defecto si no hay dato
        if i == 1 then 
            value = "A: " .. (trisolver.Triangle.angles.A and string.format("%.2f", trisolver.Triangle.angles.A) or "?") .. "°"
        elseif i == 2 then 
            value = "B: " .. (trisolver.Triangle.angles.B and string.format("%.2f", trisolver.Triangle.angles.B) or "?") .. "°"
        elseif i == 3 then 
            value = "C: " .. (trisolver.Triangle.angles.C and string.format("%.2f", trisolver.Triangle.angles.C) or "?") .. "°"
        end
        
        -- Mostrar texto cerca del vértice
        Textocentrado(value, scaledVertices[i*2-1], scaledVertices[i*2])
    end

    -- Dibujar círculos en los puntos medios y mostrar valores
    love.graphics.setFont(font_scp_16)
    for i, midpoint in ipairs(midpoints) do
        -- Dibujar círculo
        if debug then
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.circle("fill", midpoint[1], midpoint[2], 7*circleunit)
        elseif debug == false then
        love.graphics.setColor(0.0, 0.11, 0.16, 1)
        love.graphics.circle("fill", midpoint[1], midpoint[2], 7*circleunit)
        end
        
        -- Mostrar valor del lado/ángulo
        love.graphics.setColor(1, 1, 1, 1)
        local value = "?"  -- Valor por defecto si no hay dato
        if i == 1 then 
            value = "a: " .. (trisolver.Triangle.sides.a and string.format("%.2f", trisolver.Triangle.sides.a) or "?")
        elseif i == 2 then 
            value = "b: " .. (trisolver.Triangle.sides.b and string.format("%.2f", trisolver.Triangle.sides.b) or "?")
        elseif i == 3 then 
            value = "c: " .. (trisolver.Triangle.sides.c and string.format("%.2f", trisolver.Triangle.sides.c) or "?")
        end
        
        Textocentrado(value, midpoint[1], midpoint[2])
    end

    love.graphics.pop()
end

function love.load()
    love.window.setDisplaySleepEnabled(true)
    love.window.setFullscreen(fullscreen)

    -- Obtener los argumentos de la línea de comandos
    local arguments = love.arg.parseGameArguments(arg)
    for i, v in ipairs(arguments) do
        if v == "-d" then debug = true end
    end

    -- Inicializar vértices con los valores por defecto del triángulo
    vertices = {
        trisolver.Triangle.vertices.x1, trisolver.Triangle.vertices.y1,
        trisolver.Triangle.vertices.x2, trisolver.Triangle.vertices.y2,
        trisolver.Triangle.vertices.x3, trisolver.Triangle.vertices.y3
    }
end

function love.update(dt)
    safe_x, safe_y, safe_w, safe_h = love.window.getSafeArea()
    ui_unit.x = safe_w / 100
    ui_unit.y = safe_h / 100

    area = {x = 75*ui_unit.x, y = 40*ui_unit.y}

    -- Obtener las dimensiones del triángulo
    local triWidth, triHeight = GetTriangleDimensions(vertices)

    -- Calcular factores de escala para ancho y alto
    local scaleX = area.x / triWidth
    local scaleY = area.y / triHeight
    
    -- Usar el factor más pequeño para mantener proporciones
    local scaleFactor = math.min(scaleX, scaleY)

    -- Aplicar el factor de escala a los vértices del triángulo
    for i = 1, #vertices do
        scaledVertices[i] = vertices[i] * scaleFactor
    end
end

-- Modificar la función love.draw
function love.draw()
    -- Ajustar la posición vertical según el teclado
    love.graphics.push()
    love.graphics.translate(safe_x, safe_y - keyboardOffset)
    
    -- setear el background a "negro"
    love.graphics.setBackgroundColor(0, 0.19, 0.26)
    -- setear la fuente
    love.graphics.setFont(font_scp_16)
    -- setear el color a blanco
    love.graphics.setColor(1, 1, 1, 1)

    -- título
    Textocentrado("Triangle Solver", safe_w / 2, safe_h * 0.08, font_scp_32)
    -- botones para elegir el tipo de triángulo
    DrawTriTypeSelect()
    -- triángulo
    DrawTri()

    -- input, teclado, y enviar
    DrawNavUi()

    -- INTERFAZ DEBUG
    if debug then
        -- mover el cursor hacia abajo
    love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", 0, 0, safe_w, safe_h)
        love.graphics.setFont(font_scp_16)
        love.graphics.print("safe_x: " .. tostring(safe_x), 0, 60)
        love.graphics.print("safe_y: " .. tostring(safe_y), 0, 80)
        love.graphics.print("safe_w: " .. tostring(safe_w), 0, 100)
        love.graphics.print("safe_h: " .. tostring(safe_h), 0, 120)
        love.graphics.print("800px= " .. tostring(love.window.toPixels(800)), 0, 140)
        love.graphics.print("ui_unit.x: " .. tostring(ui_unit.x), 0, 160)
        love.graphics.print("ui_unit.y: " .. tostring(ui_unit.y), 0, 180)

        -- Mostrar información de toques activos
        local touches = love.touch.getTouches()
        for i, id in ipairs(touches) do
            local tx, ty = love.touch.getPosition(id)
            love.graphics.print("Touch " .. i .. ": x=" .. tx .. " y=" .. ty, 0, 200 + i * 20)
        end
    end

    love.graphics.pop()
end

-- Añadir estas funciones para detectar cuando el teclado se muestra/oculta
function love.keyboard.show()
    -- Usar una fracción fija de la altura segura en lugar de getHeight
    keyboardHeight = safe_h * 0.4  -- 40% de la altura segura
    keyboardOffset = keyboardHeight
    keyboardOpen = true
end

function love.keyboard.hide()
    keyboardOffset = 0
    keyboardHeight = 0
    keyboardOpen = false
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        love.event.quit()
    elseif key == "f11" then
        fullscreen = not fullscreen
        love.window.setFullscreen(fullscreen)
    -- elseif key == "o" then
        -- debug = not debug
    elseif key == "backspace" then
        -- Borrar el último carácter si hay texto y el teclado está abierto
        if keyboardOpen and #inputText > 0 then
            inputText = string.sub(inputText, 1, -2)
        end
    end
end

function love.textinput(text)
    if keyboardOpen and #inputText < maxInputLength then
        -- En Android, el backspace puede venir como diferentes caracteres especiales
        local backspaceChars = {
            "\b",      -- Backspace tradicional
            "\127",    -- Delete
            "\8"       -- Otro código de backspace
        }
        
        -- Verificar si el texto es un backspace
        for _, char in ipairs(backspaceChars) do
            if text == char then
                if #inputText > 0 then
                    inputText = string.sub(inputText, 1, -2)
                end
                return
            end
        end
        
        -- Solo permitir números y símbolos matemáticos
        if text:match("[0-9%-%+%.,×÷=%%πθe%(%)]") then
            inputText = inputText .. text
        end
    end
end

-- Añadir esta nueva función
function handleInteraction(x, y)
    -- Ajustar coordenadas relativas al área segura y al offset del teclado
    local touchX = x - safe_x
    local touchY = y - safe_y + keyboardOffset
    
    -- Verificar toques en los botones de tipo de triángulo
    local buttons = {ui_button_1, ui_button_2, ui_button_3}
    for i, button in ipairs(buttons) do
        if touchX >= button.min_x*ui_unit.x and 
           touchX <= button.max_x*ui_unit.x and
           touchY >= button.min_y*ui_unit.y and 
           touchY <= button.max_y*ui_unit.y then
            TriState = i
            return
        end
    end

    -- Verificar toques en los vértices y puntos medios del triángulo
    local triWidth, triHeight, originX, originY = GetTriangleDimensions(scaledVertices)
    local offx, offy = Centrado(area.x, area.y, triWidth, triHeight)
    local baseX = 25 * ui_unit.x * 0.5 + offx - originX
    local baseY = ui_unit.y * 40 + offy - originY
    
    -- Radio de detección para los círculos
    local hitRadius = 20

    -- Calcular puntos medios
    local midpoints = {
        {(scaledVertices[3] + scaledVertices[5])/2, (scaledVertices[4] + scaledVertices[6])/2},
        {(scaledVertices[1] + scaledVertices[5])/2, (scaledVertices[2] + scaledVertices[6])/2},
        {(scaledVertices[1] + scaledVertices[3])/2, (scaledVertices[2] + scaledVertices[4])/2}
    }

    -- Comprobar toques en los vértices (ángulos)
    for i = 1, 3 do
        local vertexX = baseX + scaledVertices[i*2-1]
        local vertexY = baseY + scaledVertices[i*2]
        
        local distance = math.sqrt((touchX - vertexX)^2 + (touchY - vertexY)^2)
        if distance <= hitRadius then
            local angleLabels = {"A", "B", "C"}
            selectedInput = angleLabels[i]
            -- Convertir el valor existente a string si existe
            inputText = trisolver.Triangle.angles[selectedInput] and tostring(trisolver.Triangle.angles[selectedInput]) or ""
            return
        end
    end

    -- Comprobar toques en los puntos medios (lados)
    for i, midpoint in ipairs(midpoints) do
        local mpX = baseX + midpoint[1]
        local mpY = baseY + midpoint[2]
        
        local distance = math.sqrt((touchX - mpX)^2 + (touchY - mpY)^2)
        if distance <= hitRadius then
            local sideLabels = {"a", "b", "c"}
            selectedInput = sideLabels[i]
            -- Convertir el valor existente a string si existe
            inputText = trisolver.Triangle.sides[selectedInput] and tostring(trisolver.Triangle.sides[selectedInput]) or ""
            return
        end
    end

    -- Verificar si se tocó el botón de ocultar teclado (id == 4)
    if (touchX >= ui_button_4.min_x*ui_unit.x and 
       touchX <= ui_button_4.max_x*ui_unit.x and
       touchY >= ui_button_4.min_y*ui_unit.y and 
       touchY <= ui_button_4.max_y*ui_unit.y) or
       (touchX >= ui_button_7.min_x*ui_unit.x and 
       touchX <= ui_button_7.max_x*ui_unit.x and
       touchY >= ui_button_7.min_y*ui_unit.y and 
       touchY <= ui_button_7.max_y*ui_unit.y) then
        if keyboardOpen then
            -- Ocultar teclado y resetear estado de input
            love.keyboard.setTextInput(false)
            love.keyboard.hide()
            selectedInput = nil  -- Resetear la selección
            inputText = ""      -- Limpiar el texto de entrada
        end
        return
    end

    -- Verificar si se tocó el botón de mostrar teclado (id == 5)
    local button6_height = (ui_button_6.max_y - ui_button_6.min_y) * ui_unit.y
    local button6_width = button6_height  -- El ancho será igual al alto
    local button6_x = 99 * ui_unit.x - button6_width
    
    -- Verificar si se tocó el botón de enviar (id == 6)
    if touchX >= button6_x and 
       touchX <= button6_x + button6_width and
       touchY >= ui_button_6.min_y*ui_unit.y and 
       touchY <= ui_button_6.max_y*ui_unit.y then
        -- Aquí iría la lógica del botón enviar
        saveCurrentValue()
        return
    end

    -- Verificar si se tocó el botón de mostrar teclado (id == 5)
    if touchX >= ui_button_5.min_x*ui_unit.x and 
       touchX <= button6_x and  -- El límite derecho es donde empieza el botón 6
       touchY >= ui_button_5.min_y*ui_unit.y and 
       touchY <= ui_button_5.max_y*ui_unit.y then
        if not keyboardOpen then
            love.keyboard.setTextInput(true)
            love.keyboard.show()
        end
        return
    end

end

-- Modificar love.touchpressed para usar la nueva función
function love.touchpressed(id, x, y, dx, dy, pressure)
    handleInteraction(x, y)
end

-- Añadir soporte para ratón
function love.mousepressed(x, y, button, istouch)
    if button == 1 and not istouch then  -- Solo click izquierdo y no es un toque
        handleInteraction(x, y)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  -- Implementar arrastre si lo necesitas
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  -- Implementar acciones al soltar si las necesitas
end

function saveCurrentValue()
    if selectedInput and inputText ~= "" then
        local value = tonumber(inputText)
        if value then
            -- Guardar los vértices actuales antes de cualquier cambio
            local currentVertices = {
                vertices[1], vertices[2],
                vertices[3], vertices[4],
                vertices[5], vertices[6]
            }
            
            if selectedInput:match("[ABC]") then
                -- Verificar que el ángulo sea positivo y menor que 180
                if value <= 0 or value >= 180 then
                    inputText = ""
                    return
                end
                
                -- Calcular la suma de los ángulos existentes (excluyendo el actual)
                local sumExisting = 0
                local angleCount = 0
                for angle, val in pairs(trisolver.Triangle.angles) do
                    if angle ~= selectedInput and val then
                        sumExisting = sumExisting + val
                        angleCount = angleCount + 1
                    end
                end
                
                -- Solo validar si tenemos dos ángulos y su suma es 180
                if angleCount == 1 and (sumExisting + value) == 180 then
                    inputText = ""
                    return
                end
                
                trisolver.Triangle.angles[selectedInput] = value
            else
                trisolver.Triangle.sides[selectedInput] = value
            end
            
            -- Intentar resolver el triángulo
            if trisolver.solveTriangle(trisolver.Triangle) then
                -- Actualizar los vértices si se resolvió el triángulo
                vertices = trisolver.triangleToVertices(trisolver.Triangle)
            else
                -- Si no se pudo resolver, mantener los vértices actuales
                vertices = currentVertices
            end
            
            -- Actualizar los vértices escalados
            local triWidth, triHeight = GetTriangleDimensions(vertices)
            local scaleX = area.x / triWidth
            local scaleY = area.y / triHeight
            local scaleFactor = math.min(scaleX, scaleY)
            
            for i = 1, #vertices do
                scaledVertices[i] = vertices[i] * scaleFactor
            end
            
            inputText = ""
            selectedInput = nil
            love.keyboard.setTextInput(false)
            love.keyboard.hide()
        end
    end
end
