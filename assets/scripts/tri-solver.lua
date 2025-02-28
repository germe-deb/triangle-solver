-- Estructura para almacenar los datos del triángulo
local Triangle = {
    sides = {a = nil, b = nil, c = nil},
    angles = {A = nil, B = nil, C = nil},
    vertices = {x1 = 0, y1 = 0, x2 = 0, y2 = 0, x3 = 0, y3 = 0}
}

-- Teorema del seno
local function lawOfSines(triangle)
    if triangle.sides.a and triangle.angles.A and triangle.angles.B then
        triangle.sides.b = triangle.sides.a * math.sin(math.rad(triangle.angles.B)) / math.sin(math.rad(triangle.angles.A))
    end
    -- ... implementar otros casos
end

-- Teorema del coseno
local function lawOfCosines(triangle)
    if triangle.sides.a and triangle.sides.b and triangle.angles.C then
        local C_rad = math.rad(triangle.angles.C)
        triangle.sides.c = math.sqrt(triangle.sides.a^2 + triangle.sides.b^2 - 2*triangle.sides.a*triangle.sides.b*math.cos(C_rad))
    end
    -- ... implementar otros casos
end

-- Convertir lados y ángulos a vértices
local function triangleToVertices(triangle)
    -- Colocar primer vértice en el origen
    triangle.vertices.x1 = 0
    triangle.vertices.y1 = 0
    
    -- Segundo vértice a distancia 'c' sobre el eje X
    triangle.vertices.x2 = triangle.sides.c
    triangle.vertices.y2 = 0
    
    -- Tercer vértice usando trigonometría
    local A_rad = math.rad(triangle.angles.A)
    triangle.vertices.x3 = triangle.sides.b * math.cos(A_rad)
    triangle.vertices.y3 = triangle.sides.b * math.sin(A_rad)
    
    return {
        triangle.vertices.x1, triangle.vertices.y1,
        triangle.vertices.x2, triangle.vertices.y2,
        triangle.vertices.x3, triangle.vertices.y3
    }
end

-- Intentar resolver el triángulo con los datos disponibles
local function solveTriangle(triangle)
    local solved = false
    local iterations = 0
    local max_iterations = 3
    
    while not solved and iterations < max_iterations do
        local previous_state = {}
        for k,v in pairs(triangle) do previous_state[k] = v end
        
        lawOfSines(triangle)
        lawOfCosines(triangle)
        
        -- Verificar si hemos resuelto todo
        solved = true
        for _,v in pairs(triangle.sides) do
            if not v then solved = false break end
        end
        for _,v in pairs(triangle.angles) do
            if not v then solved = false break end
        end
        
        iterations = iterations + 1
    end
    
    return solved
end

return {
    Triangle = Triangle,
    solveTriangle = solveTriangle,
    triangleToVertices = triangleToVertices
}