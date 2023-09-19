viewer.mode = FULLSCREEN

-- Define collision groups
GROUP_SPHERE1 = 1<<1
GROUP_SPHERE2 = 1<<2

function setup()
    -- Set up the 3D scene
    scene = craft.scene()
    
    -- Create the first sphere (static)
    sphere1 = scene:entity()
    sphere1.position = vec3(0, 0, 0)
    sphere1.model = craft.model.icosphere(1, 3)
    sphere1.material = craft.material(asset.builtin.Materials.Standard)
    sphere1.material.diffuse = color(255, 0, 0)
    rb1 = sphere1:add(craft.rigidbody, STATIC)
    sphere1:add(craft.shape.sphere, 1)
    rb1.group = GROUP_SPHERE1
    
    -- Create the second sphere (dynamic)
    sphere2 = scene:entity()
    sphere2.position = vec3(0, 5, 0)
    sphere2.model = craft.model.icosphere(1, 3)
    sphere2.material = craft.material(asset.builtin.Materials.Standard)
    sphere2.material.diffuse = color(0, 0, 255)
    rb2 = sphere2:add(craft.rigidbody, DYNAMIC)
    sphere2:add(craft.shape.sphere, 1)
    rb2.group = GROUP_SPHERE2
    
    viewer = scene.camera:add(OrbitViewer, sphere1.position, 23, 6, 800)
end

function update(dt)
    -- Use sphereCast to check for collisions
    local hitInfo = scene.physics:spherecast(sphere2.position, vec3(0, -1, 0), 1.5, 1, ~0, ~GROUP_SPHERE2)
    
    if hitInfo and hitInfo.entity == sphere1 then
        print("Spheres are touching! ", hitInfo.point)
    end
end

function touched(t)
    
end

function draw()
    update(DeltaTime)
    scene:update(DeltaTime)
    scene:draw()
end

