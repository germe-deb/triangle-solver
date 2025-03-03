-- SPDX-FileCopyrightText: 2025 dpkgluci
--
-- SPDX-License-Identifier: MIT

-- Copilot y Chatgpt han hecho de las suyas en este proyecto!!!
-- variables

math.randomseed(os.time())

-- lick
local lick = require "lib/lick/lick"
lick.updateAllFiles = true
lick.clearPackages = true

lick.reset = true
lick.debug = true

-- otros archivos
local solver = require("assets/scripts/solver")
local ui = require "assets/scripts/ui"

-- juego
TriState = 3
local debug = false
ui.debug = debug
local fullscreen = false
local safe_x, safe_y, safe_w, safe_h = 0, 0, 0, 0

local ui_unit = {x = 0, y = 0}
local area = {x = 0, y = 0}

-- fuente
local font_scp_16 = love.graphics.newFont("assets/fonts/SourceCodePro-Regular.otf", 16)
local font_scp_32 = love.graphics.newFont("assets/fonts/SourceCodePro-Regular.otf", 32)

-- Platform detection
local platform = love.system.getOS()

if platform == "Windows" or platform == "Linux" or platform == "OS X" then
     platform = "desktop"
elseif platform == "Android" or platform == "iOS" then
     platform = "mobile"
end


-- teclado de android
local keyboardOpen = false

-- Añadir estas variables al inicio del archivo
local keyboardOffset = 0
local keyboardHeight = 0

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

-- vertices del triangulo
local vertices = {0, 0, 0, 0, 0, 0}
local scaledVertices = {0, 0, 0, 0, 0, 0}
-- local triangulo = {}

local maxInputLength = 10 -- Limitar longitud del texto

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
        solver.Triangle.vertices.x1, solver.Triangle.vertices.y1,
        solver.Triangle.vertices.x2, solver.Triangle.vertices.y2,
        solver.Triangle.vertices.x3, solver.Triangle.vertices.y3
    }

    -- Sincronizar los vértices con el módulo UI
    for i = 1, #vertices do
        ui.vertices[i] = vertices[i]
    end
end

function love.update(dt)
    ui.actualizar()

    
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
    

    -- Verificar y resolver ángulos automáticamente
    local count = 0
    local sum = 0
    local missing = nil
    
    -- Contar ángulos conocidos y calcular suma
    for angle, value in pairs(solver.Triangle.angles) do
        if value then
            count = count + 1
            sum = sum + value
        else
            missing = angle
        end
    end
    
    -- Si tenemos exactamente 2 ángulos, calcular el tercero
    if count == 2 and missing and sum < 180 then
        solver.Triangle.angles[missing] = 180 - sum
        -- Actualizar vértices después de resolver el nuevo ángulo
        vertices = solver.triangleToVertices(solver.Triangle)
    end
end

-- Modificar la función love.draw
function love.draw()
    -- Ajustar la posición vertical según el teclado
    love.graphics.push()
    love.graphics.translate(safe_x, safe_y - keyboardOffset)
    
    -- setear el background a azul profundo
    love.graphics.setBackgroundColor(0, 0.19, 0.26)
    -- setear la fuente
    love.graphics.setFont(font_scp_16)
    
    -- título
    -- setear el color a blanco
    love.graphics.setColor(1, 1, 1, 1)
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
    if platform == "mobile" then
        -- Usar una fracción fija de la altura segura en lugar de getHeight
        keyboardHeight = safe_h * 0.4  -- 40% de la altura segura
        keyboardOffset = keyboardHeight
    end
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
        if keyboardOpen and #ui.inputText > 0 then
            ui.inputText = string.sub(ui.inputText, 1, -2)
        end
    end
end

function love.textinput(text)
    if keyboardOpen and #ui.inputText < maxInputLength then
        -- En Android, el backspace puede venir como diferentes caracteres especiales
        local backspaceChars = {
            "\b",      -- Backspace tradicional
            "\127",    -- Delete
            "\8"       -- Otro código de backspace
        }
        
        -- Verificar si el texto es un backspace
        for _, char in ipairs(backspaceChars) do
            if text == char then
                if #ui.inputText > 0 then
                    ui.inputText = string.sub(ui.inputText, 1, -2)
                end
                return
            end
        end
        
        -- Solo permitir números y símbolos matemáticos
        if text:match("[0-9%-%+%.,×÷=%%πθe%(%)]") then
            ui.inputText = ui.inputText .. text
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
            ui.selectedInput = angleLabels[i]
            -- Convertir el valor existente a string si existe
            ui.inputText = solver.Triangle.angles[ui.selectedInput] and tostring(solver.Triangle.angles[ui.selectedInput]) or ""
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
            ui.selectedInput = sideLabels[i]
            -- Convertir el valor existente a string si existe
            ui.inputText = solver.Triangle.sides[ui.selectedInput] and tostring(solver.Triangle.sides[ui.selectedInput]) or ""
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
            ui.selectedInput = nil  -- Resetear la selección
            ui.inputText = ""      -- Limpiar el texto de entrada
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
    if ui.selectedInput and ui.inputText ~= "" then
        local value = tonumber(ui.inputText)
        if value then
            if ui.selectedInput:match("[ABC]") then
                if value > 0 and value < 180 then
                    solver.Triangle.angles[ui.selectedInput] = value
                    -- Intentar resolver el triángulo después de añadir un ángulo
                    solver.solveTriangle(solver.Triangle)
                end
            else
                solver.Triangle.sides[ui.selectedInput] = value
                -- Intentar resolver el triángulo después de añadir un lado
                solver.solveTriangle(solver.Triangle)
            end
            
            -- Actualizar los vértices si se resolvió algo nuevo
            vertices = solver.triangleToVertices(solver.Triangle)
            -- Sincronizar con UI
            for i = 1, #vertices do
                ui.vertices[i] = vertices[i]
            end
            
            ui.inputText = ""
            ui.selectedInput = nil
            love.keyboard.setTextInput(false)
            love.keyboard.hide()
        end
    end
end
