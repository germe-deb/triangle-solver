-- SPDX-FileCopyrightText: 2024 dpkgluci
--
-- SPDX-License-Identifier: MIT

-- Copilot y Chatgpt han hecho de las suyas en este proyecto!!!
-- variables

math.randomseed(os.time())

trisolver = require("assets/scripts/tri-solver")
-- juego
TriState = 1
local debug = true
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

-- vertices del triangulo
local vertices = {0, 0, 0, 0, 0, 0}
local scaledVertices = {}
-- local triangulo = {}

local inputText = ""
local selectedInput = nil -- Para saber qué estamos editando (lado o ángulo)
local maxInputLength = 10 -- Limitar longitud del texto

-- dibujar botones para seleccionar entre los 3 tipos de triángulos
function DrawTriTypeSelect()
  local buttonsizeW = safe_w / 3
  local buttonsizeH = buttonsizeW * 0.7
  if buttonsizeH > safe_h * 0.18 then
    buttonsizeH = safe_h * 0.18
  end
  local buttonposY = safe_h * 0.15
  local buttonLabels = {"Rect.", "Equil.", "Escal."}

  for i = 0, 2 do
    DrawButton(buttonsizeW * i, buttonposY, buttonsizeW, buttonsizeH, 1, 1, 1, i+1, buttonLabels[i + 1])
  end
end

function DrawNavUi()
  DrawButton(1*ui_unit.x, 89*ui_unit.y, 10*ui_unit.x, 10*ui_unit.y, 1, 1, 1, 4, "Hide")
  DrawButton(11*ui_unit.x, 89*ui_unit.y, 78*ui_unit.x, 10*ui_unit.y, 1, 1, 1, 5, "Show Keyboard")
  DrawButton(89*ui_unit.x, 89*ui_unit.y, 10*ui_unit.x, 10*ui_unit.y, 1, 1, 1, 6, "Send")
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
  
  -- setear la fuente grande
  love.graphics.setFont(font_scp_32)
  -- Mostrar el texto de entrada si es el botón 5
  if id == 5 then
      local displayText = inputText
      if displayText == "" then
          if selectedInput then
              displayText = selectedInput .. ": editar..."
          else
              displayText = "Toca para editar"
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

function Textocentrado(texto, x, y, fuente, id)
    love.graphics.push()
    fuente = fuente or font_scp_16
    love.graphics.setFont(fuente)
    
    -- Si estamos en el botón de entrada (ID 5), alinear a la izquierda con margen
    if id == 5 then
        local offsetx = 15*ui_unit.x  -- margen fijo de 10 pixels
        local offsety = fuente:getHeight() / 2
        love.graphics.translate(math.floor(offsetx), math.floor(y - offsety))
    else
        -- Comportamiento normal centrado
        local offsetx = fuente:getWidth(texto) / 2
        local offsety = fuente:getHeight() / 2
        love.graphics.translate(math.floor(x - offsetx), math.floor(y - offsety))
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
    if i == 1 then value = "A: " .. (trisolver.Triangle.angles.A or "?") .. "°"
    elseif i == 2 then value = "B: " .. (trisolver.Triangle.angles.B or "?") .. "°"
    elseif i == 3 then value = "C: " .. (trisolver.Triangle.angles.C or "?") .. "°"
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
    if i == 1 then value = "a: " .. (trisolver.Triangle.sides.a or "?")
    elseif i == 2 then value = "b: " .. (trisolver.Triangle.sides.b or "?")
    elseif i == 3 then value = "c: " .. (trisolver.Triangle.sides.c or "?")
    end
    
    -- Ajustar posición del texto para que esté fuera del triángulo
    local offsetX = 10 * circleunit
    local offsetY = 10 * circleunit
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
    if v == "-d" then
      debug = true
    end
  end

  vertices[1] = math.random(-100, 100)
  vertices[2] = math.random(-100, 100)
  vertices[3] = math.random(-100, 100)
  vertices[4] = math.random(-100, 100)
  vertices[5] = math.random(-100, 100)
  vertices[6] = math.random(-100, 100)

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

  --[[
  -- crazy mode
  vertices[1] = math.random(-100, 100)
  vertices[2] = math.random(-100, 100)
  vertices[3] = math.random(-100, 100)
  vertices[4] = math.random(-100, 100)
  vertices[5] = math.random(-100, 100)
  vertices[6] = math.random(-100, 100)
  ]]
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
    elseif key == "o" then
        debug = not debug
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
        if text:match("[0-9%-%+%.,×÷=%%√πθ°e%(%)]") then
            inputText = inputText .. text
        end
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    -- Ajustar coordenadas relativas al área segura y al offset del teclado
    local touchX = x - safe_x
    local touchY = y - safe_y + keyboardOffset  -- Añadir el offset del teclado
    
    -- Verificar toques en los botones de tipo de triángulo
    local buttonsizeW = safe_w / 3
    local buttonsizeH = buttonsizeW * 0.7
    if buttonsizeH > safe_h * 0.18 then
        buttonsizeH = safe_h * 0.18
    end
    local buttonposY = safe_h * 0.15

    -- Comprobar si el toque está en alguno de los botones
    for i = 0, 2 do
        local buttonX = buttonsizeW * i
        local buttonY = buttonposY
        if touchX >= buttonX and touchX <= buttonX + buttonsizeW and
           touchY >= buttonY and touchY <= buttonY + buttonsizeH then
            TriState = i+1
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
            inputText = trisolver.Triangle.angles[selectedInput] or ""
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
            inputText = trisolver.Triangle.sides[selectedInput] or ""
            return
        end
    end

    -- Verificar si se tocó el botón de ocultar teclado (id == 4)
    if touchX >= 1*ui_unit.x and touchX <= 11*ui_unit.x and
       touchY >= 89*ui_unit.y and touchY <= 99*ui_unit.y then
        if keyboardOpen then
            -- Ocultar teclado
            love.keyboard.setTextInput(false)
            love.keyboard.hide()  -- Añadir esta línea
        end
        return
    end

    -- Verificar si se tocó el botón de mostrar teclado (id == 5)
    if touchX >= 12*ui_unit.x and touchX <= 92*ui_unit.x and
       touchY >= 89*ui_unit.y and touchY <= 99*ui_unit.y then
        if not keyboardOpen then
            love.keyboard.setTextInput(true)
            love.keyboard.show()  -- Añadir esta línea
        end
        return
    end

end

function love.touchmoved(id, x, y, dx, dy, pressure)
  -- Implementar arrastre si lo necesitas
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  -- Implementar acciones al soltar si las necesitas
end
