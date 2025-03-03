-- Estructura para almacenar los datos del triángulo
local Triangle = {
    -- Ángulos (en grados)
    angles = {
        A = nil,  -- Ángulo A (vértice 1)
        B = nil,  -- Ángulo B (vértice 2)
        C = nil   -- Ángulo C (vértice 3)
    },
    
    -- Lados (en unidades arbitrarias)
    sides = {
        a = nil,  -- Lado a (opuesto al vértice A)
        b = nil,  -- Lado b (opuesto al vértice B)
        c = nil   -- Lado c (opuesto al vértice C)
    },
    
    -- Coordenadas de los vértices
    vertices = {
        x1 = 0, y1 = 0,      -- Vértice A
        x2 = 100, y2 = 0,    -- Vértice B
        x3 = 50, y3 = 100    -- Vértice C
    }
}

-- Teorema del seno
local function lawOfSines(triangle)
    local changed = false
    
    -- Caso 1: lado a, ángulos A y B -> lado b
    if triangle.sides.a and triangle.angles.A and triangle.angles.B and not triangle.sides.b then
        triangle.sides.b = triangle.sides.a * math.sin(math.rad(triangle.angles.B)) / math.sin(math.rad(triangle.angles.A))
        changed = true
    end
    
    -- Caso 2: lado b, ángulos A y B -> lado a
    if triangle.sides.b and triangle.angles.A and triangle.angles.B and not triangle.sides.a then
        triangle.sides.a = triangle.sides.b * math.sin(math.rad(triangle.angles.A)) / math.sin(math.rad(triangle.angles.B))
        changed = true
    end
    
    -- Caso 3: lado c, ángulos A y C -> lado a
    if triangle.sides.c and triangle.angles.A and triangle.angles.C and not triangle.sides.a then
        triangle.sides.a = triangle.sides.c * math.sin(math.rad(triangle.angles.A)) / math.sin(math.rad(triangle.angles.C))
        changed = true
    end
    
    -- Caso 4: lado c, ángulos B y C -> lado b
    if triangle.sides.c and triangle.angles.B and triangle.angles.C and not triangle.sides.b then
        triangle.sides.b = triangle.sides.c * math.sin(math.rad(triangle.angles.B)) / math.sin(math.rad(triangle.angles.C))
        changed = true
    end
    
    -- Nuevo Caso 5: lado a, ángulos A y C -> lado c
    if triangle.sides.a and triangle.angles.A and triangle.angles.C and not triangle.sides.c then
        triangle.sides.c = triangle.sides.a * math.sin(math.rad(triangle.angles.C)) / math.sin(math.rad(triangle.angles.A))
        changed = true
    end
    
    -- Nuevo Caso 6: lado b, ángulos B y C -> lado c
    if triangle.sides.b and triangle.angles.B and triangle.angles.C and not triangle.sides.c then
        triangle.sides.c = triangle.sides.b * math.sin(math.rad(triangle.angles.C)) / math.sin(math.rad(triangle.angles.B))
        changed = true
    end
    
    return changed
end

-- Teorema del coseno
local function lawOfCosines(triangle)
    local changed = false
    
    -- Caso 1: lados a, b y ángulo C -> lado c
    if triangle.sides.a and triangle.sides.b and triangle.angles.C and not triangle.sides.c then
        local C_rad = math.rad(triangle.angles.C)
        triangle.sides.c = math.sqrt(triangle.sides.a^2 + triangle.sides.b^2 - 2*triangle.sides.a*triangle.sides.b*math.cos(C_rad))
        changed = true
    end
    
    -- Caso 2: lados a, c y ángulo B -> lado b
    if triangle.sides.a and triangle.sides.c and triangle.angles.B and not triangle.sides.b then
        local B_rad = math.rad(triangle.angles.B)
        triangle.sides.b = math.sqrt(triangle.sides.a^2 + triangle.sides.c^2 - 2*triangle.sides.a*triangle.sides.c*math.cos(B_rad))
        changed = true
    end
    
    -- Caso 3: lados b, c y ángulo A -> lado a
    if triangle.sides.b and triangle.sides.c and triangle.angles.A and not triangle.sides.a then
        local A_rad = math.rad(triangle.angles.A)
        triangle.sides.a = math.sqrt(triangle.sides.b^2 + triangle.sides.c^2 - 2*triangle.sides.b*triangle.sides.c*math.cos(A_rad))
        changed = true
    end
    
    -- Caso 4: tres lados -> ángulos
    if triangle.sides.a and triangle.sides.b and triangle.sides.c then
        if not triangle.angles.A then
            local cosA = (triangle.sides.b^2 + triangle.sides.c^2 - triangle.sides.a^2) / (2*triangle.sides.b*triangle.sides.c)
            triangle.angles.A = math.deg(math.acos(cosA))
            changed = true
        end
        if not triangle.angles.B then
            local cosB = (triangle.sides.a^2 + triangle.sides.c^2 - triangle.sides.b^2) / (2*triangle.sides.a*triangle.sides.c)
            triangle.angles.B = math.deg(math.acos(cosB))
            changed = true
        end
        if not triangle.angles.C then
            local cosC = (triangle.sides.a^2 + triangle.sides.b^2 - triangle.sides.c^2) / (2*triangle.sides.a*triangle.sides.b)
            triangle.angles.C = math.deg(math.acos(cosC))
            changed = true
        end
    end
    
    return changed
end

-- Convertir lados y ángulos a vértices
local function triangleToVertices(triangle)
    -- Verificar que tengamos los datos mínimos necesarios
    if not (triangle.sides.c and triangle.sides.b and triangle.angles.A) then
        -- Devolver los vértices actuales como tabla
        return {
            triangle.vertices.x1, triangle.vertices.y1,
            triangle.vertices.x2, triangle.vertices.y2,
            triangle.vertices.x3, triangle.vertices.y3
        }
    end

    -- Si tenemos los datos necesarios, calcular los nuevos vértices
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

local function angleSolver(triangle)
    local changed = false
    local angles = triangle.angles
    
    -- Caso 1: tenemos A y B, calcular C
    if angles.A and angles.B and not angles.C then
        angles.C = 180 - angles.A - angles.B
        changed = true
    end
    
    -- Caso 2: tenemos A y C, calcular B
    if angles.A and angles.C and not angles.B then
        angles.B = 180 - angles.A - angles.C
        changed = true
    end
    
    -- Caso 3: tenemos B y C, calcular A
    if angles.B and angles.C and not angles.A then
        angles.A = 180 - angles.B - angles.C
        changed = true
    end
    
    return changed
end

local function solveTriangle(triangle)
    -- Resolver ángulos primero, siempre
    angleSolver(triangle)
    
    -- Luego intentar resolver los lados
    local changed = lawOfSines(triangle)
    changed = lawOfCosines(triangle) or changed
    
    -- Verificar si está todo resuelto
    local solved = true
    for _, v in pairs(triangle.angles) do
        if not v then solved = false break end
    end
    for _, v in pairs(triangle.sides) do
        if not v then solved = false break end
    end
    
    return solved
end

return {
    Triangle = Triangle,
    solveTriangle = solveTriangle,
    triangleToVertices = triangleToVertices,
    angleSolver = angleSolver  -- Exportar angleSolver
}