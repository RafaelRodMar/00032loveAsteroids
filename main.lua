--variables
state = "MENU"
gameWidth = 1200
gameHeight = 800
lives = 0
score = 0
isDying = false
font = nil
saveFile = "hiscores.txt"
hiscores = {}

entities = {} --collection of entities

function createEntity(name, tex, x, y, w, h, u, v, curRow, curFrame, nFrames, ang, rad)
    entity = {} --player, asteroids, bullets
    entity.name = name
    entity.texture = tex
    entity.posx = x
    entity.posy = y
    entity.width = w
    entity.height = h
    entity.velx = 0
    entity.vely = 0
    entity.angle = ang
    entity.radius = rad
    entity.alpha = 0
    entity.quads = {}
    entity.currentRow = curRow
    entity.currentFrame = curFrame
    entity.numFrames = nFrames
    entity.thrust = 0
    entity.destroy = false

    if name == "asteroid" then
        entity.velx = love.math.random(8) - 4
        entity.vely = love.math.random(8) - 4
    end

    if nFrames == 1 then
        table.insert(entity.quads, love.graphics.newQuad(u,v,w,h,tex:getWidth(),tex:getHeight()))
        table.insert(entity.quads, love.graphics.newQuad(u,v+40,w,h,tex:getWidth(),tex:getHeight()))
    elseif nFrames > 1 then
        for i=0, entity.numFrames do
            table.insert(entity.quads, love.graphics.newQuad(u,v,w,h,tex:getWidth(), tex:getHeight()))
            u = u + entity.width
        end
    end

    table.insert(entities, entity)
end

function love.load()
    love.window.setMode(1200, 800, {resizable=false, vsync=false})
    love.graphics.setBackgroundColor(1,1,1) --white
    --load font
    font = love.graphics.newFont("assets/fnt/sansation.ttf",25)
    love.graphics.setFont(font)
    --load images
    background = love.graphics.newImage("assets/img/background.jpg")
    fire_blue = love.graphics.newImage("assets/img/fire_blue.png")
    rock = love.graphics.newImage("assets/img/rock.png")
    rock_small = love.graphics.newImage("assets/img/rock_small.png")
    shield = love.graphics.newImage("assets/img/shield.png")
    spaceship = love.graphics.newImage("assets/img/spaceship.png")
    type_B = love.graphics.newImage("assets/img/type_B.png")
    type_C = love.graphics.newImage("assets/img/type_C.png")
    --load sounds
    shipexplosion = love.audio.newSource("assets/snd/explosion+3.wav","static")
    explosion = love.audio.newSource("assets/snd/explosion+6.wav","static")
    gameover = love.audio.newSource("assets/snd/gameover.wav","static")
    laser = love.audio.newSource("assets/snd/laserblasts.wav","static")
    laser:setVolume(0.2)
    explosion:setVolume(0.2)
    shipexplosion:setVolume(0.2)
    gameover:setVolume(0.2)

    info = love.filesystem.getInfo( saveFile, nil )
    if info == nil then
        --create file
        for i=5,1,-1 do
            data = string.format("%05d", i)
            success, errormsg = love.filesystem.append( saveFile, data, 5 )
            hiscores[i] = i
        end
    else
        --read file
        contents, size = love.filesystem.read( saveFile, info.size )
        hiscores[1] = tonumber(string.sub(contents,0,5))
        hiscores[2] = tonumber(string.sub(contents,6,10))
        hiscores[3] = tonumber(string.sub(contents,11,15))
        hiscores[4] = tonumber(string.sub(contents,16,20))
        hiscores[5] = tonumber(string.sub(contents,21,25))
    end
    
end

function writeHiScores()
    
    table.sort(hiscores, function(a,b) return a > b end)

    --remove file
    love.filesystem.remove( saveFile )
    --write the 5 first elements
    for i=1,5 do
        data = string.format("%05d", hiscores[i])
        success, errormsg = love.filesystem.append( saveFile, data, 5 )
    end
end

function love.keypressed(key)
    if state == "GAME" and key == 'space' and not isDying then
        createEntity("bullet", fire_blue, entities[1].posx, entities[1].posy,
        32, 64, 0,0, 0, 1, 16, entities[1].angle, 16)
        cl = laser:clone()
        cl:play()
    end
end

function love.keyreleased(key)
    if state == "MENU" then
        if key == "space" then
            state = "GAME"
            lives = 3
            score = 0

            entities = {}

            --create the player
            createEntity("player", spaceship, gameWidth / 2, gameHeight / 2, 40, 40,
            40, 0, 0, 1, 1, 0, 20)
    
            --create the asteroids
            for i=0, 15 do
                createEntity("asteroid", rock, love.math.random(0,gameWidth), love.math.random(0,gameHeight), 64, 64,
                0,0,0,1,16,0,25)
            end

            return
        end
    end

    if state == "GAMEOVER" then
        if key == 'space' then
            state = "MENU"
            return
        end
    end
end

function updatePlayer(dt)
    if entities[1].thrust then
        entities[1].velx = entities[1].velx + math.cos(math.rad(entities[1].angle - 90)) * 0.2
        entities[1].vely = entities[1].vely + math.sin(math.rad(entities[1].angle - 90)) * 0.2
    else
        entities[1].velx = entities[1].velx * 0.99
        entities[1].vely = entities[1].vely * 0.99
    end

    local maxSpeed = 15
    local speed =  math.sqrt(entities[1].velx * entities[1].velx + entities[1].vely * entities[1].vely)
    if speed > maxSpeed then
        entities[1].velx = entities[1].velx * maxSpeed / speed
        entities[1].vely = entities[1].vely * maxSpeed / speed
    end

    entities[1].posx = entities[1].posx + entities[1].velx * dt * 25
    entities[1].posy = entities[1].posy + entities[1].vely * dt * 25

    if entities[1].posx > gameWidth then entities[1].posx = 0 end
    if entities[1].posx < 0 then entities[1].posx = gameWidth end
    if entities[1].posy > gameHeight then entities[1].posy = 0 end
    if entities[1].posy < 0 then entities[1].posy = gameHeight end
end

function updateBullet(index, dt)
    entities[index].velx = math.cos(math.rad(entities[index].angle - 90)) * 6
    entities[index].vely = math.sin(math.rad(entities[index].angle - 90)) * 6

    entities[index].posx = entities[index].posx + entities[index].velx * dt * 50
    entities[index].posy = entities[index].posy + entities[index].vely * dt * 50

    if entities[index].posx > gameWidth or entities[index].posx < 0 or
        entities[index].posy > gameHeight or entities[index].posy < 0 then
            table.remove(entities, index)
    end
end

function isCollide(a,b)
    if a.posx < b.posx + b.width and
        a.posx + a.width > b.posx and
        a.posy < b.posy + b.height and
        a.posy + a.height > b.posy then
            return true
        end

    return false
end

function love.update(dt)
    if state == "MENU" then
    end

    if state == "GAME" then
        if love.keyboard.isDown( 'left' ) then
            entities[1].angle = entities[1].angle - 300 * dt
        end
        if love.keyboard.isDown( 'right' ) then
            entities[1].angle = entities[1].angle + 300 * dt
        end
        if love.keyboard.isDown( 'up' ) then
            entities[1].thrust = true
        else
            entities[1].thrust = false
        end

        if not isDying then
            updatePlayer(dt)
        end

        for i,v in ipairs(entities) do
            if v.name == "bullet" then
                updateBullet(i,dt)
            end
            if v.name == "asteroid" then
                v.posx = v.posx + v.velx * dt * 15
                v.posy = v.posy + v.vely * dt * 15
                if v.posx > gameWidth then v.posx = 0 end
                if v.posx < 0 then v.posx = gameWidth end
                if v.posy > gameHeight then v.posy = 0 end
                if v.posy < 0 then v.posy = gameHeight end
            end
            if v.numFrames > 1 then
                v.currentFrame = v.currentFrame + dt * 15 --number is speed
                if v.currentFrame >= v.numFrames then
                    v.currentFrame = v.currentFrame - v.numFrames
                    if v.name == "explosion" then
                        table.remove(entities, i)
                    end
                    if v.name == "shipexplosion" then
                        table.remove(entities,i)
                        isDying = false
                    end
                end
            end
        end

        --if player is dying then wait for shipexplosion to end
        if isDying then return end

        for i,v in ipairs(entities) do
            for j,w in ipairs(entities) do
                if v.name == "bullet" and w.name == "asteroid" then
                    if(isCollide(v,w)) then
                        explosion:play()

                        --mark them for being destroyed later
                        v.destroy = true
                        w.destroy = true
                        
                        createEntity("explosion", type_C, w.posx + 32 - 85, w.posy + 32 - 85,
                        171,171,0,0,0,1,48,0,0)
                        
                        --create two little asteroids
                        if w.radius == 25 then
                            createEntity("asteroid", rock_small, w.posx, w.posy, 64, 64, 0,0,0,1,16,0,10)
                            createEntity("asteroid", rock_small, w.posx, w.posy, 64, 64, 0,0,0,1,16,0,10)
                        end

                        score = score + 10
                        break
                    end
                end

                if v.name == "player" and w.name == "asteroid" then
                    if(isCollide(v,w)) then
                        w.destroy = true

                        createEntity("shipexplosion", type_B, w.posx + 20 - 64, w.posy + 20 - 64,
                        128,128,0,0,0,1,64,0,0)

                        shipexplosion:play()
                        isDying = true
                        lives = lives - 1
                        if lives <= 0 then
                            gameover:play()
                            isDying = false
                            table.insert(hiscores, score)
                            writeHiScores()
                            state = "GAMEOVER"
                        end

                        entities[1].posx = gameWidth / 2
                        entities[1].posy = gameHeight / 2
                        entities[1].velx = 0
                        entities[1].vely = 0
                    end
                end
            end
        end

        --destroy marked elements
        for i=#entities, 1, -1 do
            if entities[i].destroy then
                table.remove(entities,i)
            end
        end
    end

    if state == "GAMEOVER" then
    end
end

function love.draw()
    love.graphics.setBackgroundColor(1,1,1)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(background, 0, 0)

    --the states system
    if state == "MENU" then
        love.graphics.print("Asteroids", 500, 300)
        love.graphics.print("press fire to play", 470, 350)
        love.graphics.print("hi scores", 500, 400)
        row = 450
        for i=1,5 do
            love.graphics.print(hiscores[i],580,row)
            row = row + 50
        end
    end

    if state == "GAME" then
        --love.graphics.setColor(1,0,0)
        --love.graphics.print("hola mundo",0,0)
        --love.graphics.print(entities[1].posx,0,20)
        --love.graphics.print(entities[2].posx,0,40)
        love.graphics.setColor(1,1,1)
        for i,v in ipairs(entities) do
            local cFrame = math.floor(v.currentFrame / v.numFrames * #v.quads)
            if cFrame < 1 then 
                cFrame = 1
            elseif cFrame > v.numFrames then
                cFrame = v.numFrames
            end
            if v.name == "player" then
                if not isDying then
                    if v.thrust then
                        love.graphics.draw(v.texture, v.quads[cFrame + 1],v.posx,v.posy, math.rad(v.angle), 1, 1, 20, 20, 0, 0)
                    else
                        love.graphics.draw(v.texture, v.quads[cFrame],v.posx,v.posy, math.rad(v.angle), 1, 1, 20, 20, 0, 0)
                    end
                end
            else    
                love.graphics.draw(v.texture, v.quads[cFrame],v.posx,v.posy, math.rad(v.angle), 1, 1, 20, 20, 0, 0)
            end
        end

        --draw UI
        love.graphics.setColor(1,0,0)
        love.graphics.print("Lives: " .. lives .. "   Score: " .. score, 5, 10)
    end

    if state == "GAMEOVER" then
        love.graphics.print("GAME OVER", 500, 300)
        love.graphics.print("press fire to menu", 470, 350)
    end
end
