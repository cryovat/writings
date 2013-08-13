-- This should be called "main.lua" and put in a folder called "sneik".

counter = 0

pixel = {
   width=10,
   height=20
}

field = {
   width=40;
   height=30;
}

cherry = {
   posx = 0;
   posy = 0
}

next = {
   posx = 0;
   posy = 0
}

dead = false
curtain = 0
tick = 10

isDown = {}

function die()
   tick = 5
   dead = true
end

function makePiece(x, y, nxt)

   return {posx=x; posy=y; next_bit=nxt}

end

function checkTouchesPiece(p, posx, posy)

   if p.posx == posx and p.posy == posy then
      return true
   elseif p.next_bit ~= nil then
      checkTouchesPiece(p.next_bit, posx, posy)
   else
      return false
   end

end

function getRandomPoint()
   return math.random(0, field.width - 1),math.random(0, field.height - 1)
end

function moveCherry(h)

   local nextx, nexty = getRandomPoint()

   while checkTouchesPiece(h, nextx, nexty) do
      nextx, nexty = getRandomPoint()
   end

   cherry.posx = nextx
   cherry.posy = nexty

   print(nextx, nexty)

end

function movePiece(p, lastx, lasty, headx, heady)

   if p.posx == headx and p.posy == heady then
      die()
   elseif p.next_bit ~= nil then
      movePiece(p.next_bit, p.posx, p.posy, headx, heady)
   end

   p.posx = lastx
   p.posy = lasty

   return nil

end

function moveSnake(h)

   local nextx = h.posx + next.posx
   local nexty = h.posy + next.posy

   if nextx == cherry.posx and nexty == cherry.posy then
      return makePiece(nextx, nexty, h)
   else
      movePiece(h.next_bit, h.posx, h.posy, h.posx, h.posy)

      h.posx = nextx
      h.posy = nexty

      if h.posx < 0 or h.posx >= field.width or
	 h.posy < 0 or h.posy >= field.height then
	 die()
      end

      return h
   end

end

function setColorWhite()
   love.graphics.setColor(255,255,255,255)
end

function setColorRed()
   love.graphics.setColor(255,0,0,255)
end

function setColorDarkGreen()
   love.graphics.setColor(0,40,0,255)
end

function setColorGreen()
   love.graphics.setColor(0,255,0,255)
end

function fillRectangle(x, y, w, h)

   love.graphics.rectangle("fill",
			   x * pixel.width,
			   y * pixel.height,
			   (w or 1) * pixel.width,
			   (h or 1) * pixel.height)

end

function drawPiece(p)

   fillRectangle(p.posx, p.posy)

   if p.next_bit ~= nil then
      drawPiece(p.next_bit)
   end

end

function setPixelSize()
   love.graphics.setMode((field.width + 4) * pixel.width,
			 (field.height + 4) * pixel.height)
end

function togglePixelSize()

   pixel.width = math.random(2, 30)
   pixel.height = math.random(2, 30)

   setPixelSize()

end

function resetGame()

   local p4 = makePiece(4, 4, nil)
   local p3 = makePiece(4, 5, p4)
   local p2 = makePiece(4, 6, p3)
   local p1 = makePiece(5, 6, p2)
   head = makePiece(6, 6, p1)

   next.posx = 1
   next.posy = 0

   moveCherry(head)

   counter = 0
   curtain = 0
   dead = false

end

function wasPressed(k)

   if isDown[k] and not love.keyboard.isDown(k) then
      isDown[k] = false
      return true
   elseif love.keyboard.isDown(k) then
      isDown[k] = true
   end

end

function love.load()
   setPixelSize()
   love.graphics.setCaption("sneik")
   resetGame()
end

function love.update()

   if wasPressed("r") then
      resetGame()
      return
   end

   if wasPressed("p") then
      togglePixelSize()
      return
   end

   if love.keyboard.isDown("up") then
      next.posx = 0
      next.posy = -1
   elseif love.keyboard.isDown("down") then
      next.posx = 0
      next.posy = 1
   elseif love.keyboard.isDown("left") then
      next.posx = -1
      next.posy = 0
   elseif love.keyboard.isDown("right") then
      next.posx = 1
      next.posy = 0
   end

   if counter < tick then
      counter = counter + 1
   elseif dead then
      counter = 0
      curtain = math.min(field.height, curtain + 1)
   else
      counter = 0
      local h =  moveSnake(head)
      if h ~= head then
	 head = h
	 moveCherry(head)
      end
   end

end

function love.draw()

   setColorWhite()

   fillRectangle(1,1, field.width + 2, field.height + 2)

   love.graphics.push()
   love.graphics.translate(2 * pixel.width, 2 * pixel.height)

   setColorDarkGreen()

   fillRectangle(0, 0, field.width, field.height)

   setColorGreen()

   fillRectangle(cherry.posx, cherry.posy)

   setColorWhite()

   drawPiece(head)

   setColorGreen()

   fillRectangle(0, 0, field.width, curtain)

   love.graphics.pop()

end
