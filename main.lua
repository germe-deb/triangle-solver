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

local trianglesolved = false
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

-- botón de reset
local ui_button_8 = {
    min_x = 25,
    max_x = 75,     -- Esta será ajustada dinámicamente en DrawNavUi
    min_y = 80,
    max_y = 88
}

-- vertices del triangulo
local vertices = {0, 0, 0, 0, 0, 0}
local scaledVertices = {0, 0, 0, 0, 0, 0}
-- local triangulo = {}

local maxInputLength = 10 -- Limitar longitud del texto

local baseX = 0  -- Se actualizará en love.update
local baseY = 0  -- Se actualizará en love.update

-- Modificar las variables iniciales
local TRIANGLE_AREA = {
    x_percent = 90,  -- 75% del ancho de la pantalla
    y_percent = 55,  -- 40% del alto de la pantalla
    start_x = (100 - 90) /2,  -- Comienza en 12.5% del ancho
    start_y = 20     -- Comienza en 30% del alto
}


function love.load()

    trianglesolved = false
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

    -- Pasar la referencia después de requerir ui
    ui.setTriangleArea(TRIANGLE_AREA)
end

function love.update(dt)
    ui.actualizar(dt)
    
    safe_x, safe_y, safe_w, safe_h = love.window.getSafeArea()
    ui_unit.x = safe_w / 100
    ui_unit.y = safe_h / 100

    -- Actualizar las coordenadas base usando las constantes
    baseX = TRIANGLE_AREA.start_x * ui_unit.x
    baseY = TRIANGLE_AREA.start_y * ui_unit.y
    
    -- Actualizar el área usando las constantes
    area = {
        x = TRIANGLE_AREA.x_percent * ui_unit.x, 
        y = TRIANGLE_AREA.y_percent * ui_unit.y
    }
    
    ui.setBaseCoordinates(baseX, baseY)

    -- Obtener las dimensiones del triángulo
    local triWidth, triHeight = ui.GetTriangleDimensions(vertices)

    -- Calcular factores de escala para ancho y alto
    local scaleX = area.x / triWidth
    local scaleY = area.y / triHeight
    
    -- Usar el factor más pequeño para mantener proporciones
    local scaleFactor = math.min(scaleX, scaleY)

    -- Aplicar el factor de escala a los vértices del triángulo
    for i = 1, #vertices do
        scaledVertices[i] = vertices[i] * scaleFactor
    end
    
    if not trianglesolved then
    
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

    if solver.Triangle.angles.A ~= nil and
       solver.Triangle.angles.B ~= nil and
       solver.Triangle.angles.C ~= nil and
       solver.Triangle.sides.a ~= nil and
       solver.Triangle.sides.b ~= nil and
       solver.Triangle.sides.c ~= nil
    then
        trianglesolved = true
    else
        trianglesolved = false
    end

    ui.setTriangleSolved(trianglesolved)

    print("angle A: " .. tostring(solver.Triangle.angles.A))
    print("angle B: " .. tostring(solver.Triangle.angles.B))
    print("angle C: " .. tostring(solver.Triangle.angles.C))
    print("side a: " .. tostring(solver.Triangle.sides.a))
    print("side b: " .. tostring(solver.Triangle.sides.b))
    print("side c: " .. tostring(solver.Triangle.sides.c))
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
    ui.Textocentrado("Triangle Solver", safe_w / 2, safe_h * 0.08, font_scp_32)
    
    -- botones para elegir el tipo de triángulo
    -- DrawTriTypeSelect()
    -- triángulo
    ui.DrawTri()

    -- input, teclado, y enviar
    ui.DrawNavUi()

    -- INTERFAZ DEBUG
    if debug then
        -- mover el cursor hacia abajo
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", 0, 0, safe_w, safe_h)
        love.graphics.setFont(font_scp_16)
        love.graphics.print("trianglesolved: " .. tostring(trianglesolved), 0, 60)
        -- love.graphics.print("safe_y: " .. tostring(safe_y), 0, 80)
        -- love.graphics.print("safe_w: " .. tostring(safe_w), 0, 100)
        -- love.graphics.print("safe_h: " .. tostring(safe_h), 0, 120)
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

    -- DEBUG: Agregar logs para ver las coordenadas
    if debug then
        print("Touch coordinates:", touchX, touchY)
    end

    -- MOVER ESTA SECCIÓN AL PRINCIPIO: Verificar si se tocó el botón de reset (id == 8)
    if trianglesolved then
        local resetX = ui_button_8.min_x * ui_unit.x
        local resetY = ui_button_8.min_y * ui_unit.y
        local resetWidth = (ui_button_8.max_x - ui_button_8.min_x) * ui_unit.x
        local resetHeight = (ui_button_8.max_y - ui_button_8.min_y) * ui_unit.y

        -- DEBUG: Agregar logs para ver el área del botón
        if debug then
            print("Reset button area:", resetX, resetY, resetWidth, resetHeight)
        end

        if touchX >= resetX and 
           touchX <= resetX + resetWidth and
           touchY >= resetY and 
           touchY <= resetY + resetHeight then
            print("Reset button pressed!")  -- DEBUG
            resetValues()
            return
        end
    end

    -- Verificar toques en los vértices y puntos medios del triángulo
    local triWidth, triHeight, originX, originY = ui.GetTriangleDimensions(scaledVertices)
    local offx, offy = ui.Centrado(area.x, area.y, triWidth, triHeight)
    local baseX, baseY = ui.getBaseCoordinates()

    -- CORRECCIÓN: Incluir el offset en las coordenadas de detección
    -- Radio de detección para los círculos
    local hitRadius = 20

    -- Calcular puntos medios con offset
    local midpoints = {
        {(scaledVertices[3] + scaledVertices[5])/2, (scaledVertices[4] + scaledVertices[6])/2},
        {(scaledVertices[1] + scaledVertices[5])/2, (scaledVertices[2] + scaledVertices[6])/2},
        {(scaledVertices[1] + scaledVertices[3])/2, (scaledVertices[2] + scaledVertices[4])/2}
    }

    -- Comprobar toques en los vértices (ángulos) incluyendo offset
    for i = 1, 3 do
        local vertexX = baseX + offx - originX + scaledVertices[i*2-1]
        local vertexY = baseY + offy - originY + scaledVertices[i*2]
        
        local distance = math.sqrt((touchX - vertexX)^2 + (touchY - vertexY)^2)
        if distance <= hitRadius then
            local angleLabels = {"A", "B", "C"}
            ui.selectedInput = angleLabels[i]
            ui.inputText = solver.Triangle.angles[ui.selectedInput] and tostring(solver.Triangle.angles[ui.selectedInput]) or ""
            return
        end
    end

    -- Comprobar toques en los puntos medios (lados) incluyendo offset
    for i, midpoint in ipairs(midpoints) do
        local mpX = baseX + offx - originX + midpoint[1]
        local mpY = baseY + offy - originY + midpoint[2]
        
        local distance = math.sqrt((touchX - mpX)^2 + (touchY - mpY)^2)
        if distance <= hitRadius then
            local sideLabels = {"a", "b", "c"}
            ui.selectedInput = sideLabels[i]
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
                    solver.solveTriangle(solver.Triangle)
                end
            else
                solver.Triangle.sides[ui.selectedInput] = value
                solver.solveTriangle(solver.Triangle)
            end
            
            -- Actualizar los vértices si se resolvió algo nuevo
            vertices = solver.triangleToVertices(solver.Triangle)
            -- Sincronizar con UI y el estado resuelto
            for i = 1, #vertices do
                ui.vertices[i] = vertices[i]
            end
            ui.setTriangleSolved(trianglesolved)  -- Actualizar estado en UI
            ui.resetAnimation()
            
            ui.inputText = ""
            ui.selectedInput = nil
            love.keyboard.setTextInput(false)
            love.keyboard.hide()
        end
    end
end

function resetValues()
    -- Restablecer los valores del triángulo
    solver.resetTriangle(solver.Triangle)
    trianglesolved = false  -- Resetear el estado
    ui.setTriangleSolved(false)  -- Actualizar estado en UI
    
    -- Actualizar los vértices después de restablecer
    vertices = solver.triangleToVertices(solver.Triangle)
    -- Sincronizar con UI
    for i = 1, #vertices do
        ui.vertices[i] = vertices[i]
    end
    ui.resetAnimation()
    ui.inputText = ""
    ui.selectedInput = nil
    love.keyboard.setTextInput(false)
    love.keyboard.hide()

    print("values reseted")
end
