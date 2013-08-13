A [LÖVE](http://www.love2d.org)ly little Snake clone
====================================================

This article will show how to make a Snake using [LÖVE](http://www.love2d.org)
and the [Lua](http://www.lua.org) programming language. It is a guided tour
through [sneik.lua](sneik.lua), a single file implementation of the game,
that tries to introduce the engine, the language and some general game programming
concepts along the way. The article assumes some very basic programming experience.

For a blazing introduction to Lua, check out
[Lua in 15 minutes](http://tylerneylon.com/a/learn-lua/). This text will also cover
some of the more particular language features.

Baby steps
----------

To start off, we declare some global variables. Values that "belong together", like
the pixel size and cherry position are kept in [tables](http://lua-users.org/wiki/TablesTutorial).
These can be thought of as containers where you can put named values.

```lua

counter = 0     -- 
tick = 10       -- How many frames between each logic update (see below)
dead = false    -- If the player is alive or dead
curtain = 0     -- The position of the game-over curtain

pixel = {       -- Since one pixel is tiny on a modern display, we're going to
   width=10,    -- scale them up. This keeps track of the pixel width and height
   height=20    -- for convenience.
}

field = {       -- The size of the game field
   width=40;
   height=30;
}

cherry = {      -- The position of the cherry
   posx = 0;
   posy = 0
}

next = {        -- The next position of the snake's head
   posx = 0;
   posy = 0
}

isDown = {}     -- This is reserved space that will be used later. :-)
```

Getting functional
------------------

Next, we will define a bunch of utillity functions.

First off, we need a way to kill the snake if he goes outside the field or crashes
into himself:

```lua

function die()
   tick = 5
   dead = true
end
```

The following function will be used to create a part of the snake. Since the snake
will grow every time it eats the cherry, we need a way to represent it so that it
can be any length. The most convenient way of doing this is making our snake a
[linked list](http://en.wikipedia.org/wiki/Linked_list). This means that it is the
responsibility of each part of the snake to know where the next is.

The tail of the snake will know that it has no next bit. In addition to keeping
track of the next bit, each piece will also keep track of its position.

In this implementation, each part of the snake is a **table** containing its
x and y coordinates (stored in the table as **posx** and **posy**) and the address
of another table that contains the next part (in **next_bit**).

```lua
function makePiece(x, y, nxt)

   return {posx=x; posy=y; next_bit=nxt}

end
```

We're going to need a way to check if a coordinate (defined by **posx** and **posy**)
is covered by the snake. Since each part of the snake only keeps track of its next part,
we need to start at the head and move backwards until we find a crash (or the end of the
snake). We do this by a [recursive](http://en.wikipedia.org/wiki/Recursion) function;
meaning a function that calls itself.

```lua
function checkTouchesPiece(p, posx, posy)

   if p.posx == posx and p.posy == posy then
      return true
   elseif p.next_bit ~= nil then
      checkTouchesPiece(p.next_bit, posx, posy)
   else
      return false
   end

end
```

The next function gives us a random position within the **field** defined at the start.
You may notice that it returns two values. In Lua, this works wonderfully. The following
function will show how you catch them.

```lua
function getRandomPoint()
   return math.random(0, field.width - 1), math.random(0, field.height - 1)
end
```

At the start of the game, and when the player picks up a cherry, we're going to have
to move the cherry to a random position. Here we make use of the two functions we defined
above.

```lua
function moveCherry(h)

   local nextx, nexty = getRandomPoint()

   -- This will be inefficient for very big snakes:
   while checkTouchesPiece(h, nextx, nexty) do
      nextx, nexty = getRandomPoint()
   end

   cherry.posx = nextx
   cherry.posy = nexty
   
end
```

The following function does two things; it will move the snake, but to save us having
to move along the whole length of the snake twice, it will also check if the head
crashes into the body, and kill the snake if it does.

The parameters are the part to check ( **p** ), the position of the previous part checked
( **lastx** and **lasty** ), and the position of the head ( **headx**, **heady** ).

Like **checkTouchesPiece**, the function is *recursive*; it depends on itself to check
the next part of the snake.

```lua
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
```

The next function will move the head of the snake. While there is no difference between
the head and any other part of the snake in memory (it's a position and the address of
the next part), it needs some special handling. We will need to:

 * Calculate the next position of the snake
 * Check if the next position holds a cherry. If it is, we need to grow the snake.
 * Check if the new position is outside the bounds of the field, and kill it if it is.

Note that the function returns the head of the snake. If a cherry has been eaten, we
create a new head, bolt it on the front and return that instead. Why should become clear
later.

```lua
function moveSnake(h)

   local nextx = h.posx + next.posx
   local nexty = h.posy + next.posy

   if nextx == cherry.posx and nexty == cherry.posy then
      return makePiece(nextx, nexty, h)
   else
      movePiece(h.next_bit, h.posx, h.posy, h.posx, h.posy)

      h.posx = nextx
      h.posy = nexty

      if h.posx < 0 or h.posx >= field.width then
         die()
      end
      
      if h.posy < 0 or h.posy >= field.height then
	 die()
      end

      return h
   end

end
```

Pushing pixels
--------------

The next set of functions will deal with drawing. The first ones up are just
helpers meant to make the following code shorter and more readable.

Keeping functions short and readable, and avoiding duplication
(called good [factoring](http://en.wikipedia.org/wiki/Code_refactoring)) is important
to save yourself headaches once the program grows. If you find yourself copying and
pasting the same code in several places, you should stop and create a helper function!

See if you can follow what these do:

```lua
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
```

Next is the function for drawing the snake. You should be used to our *recursive* tricks
by now. See how clear our helpers made it:

```lua
function drawPiece(p)

   fillRectangle(p.posx, p.posy)

   if p.next_bit ~= nil then
      drawPiece(p.next_bit)
   end

end
```

The next ones are for use in our *easter egg*:

```lua
function setPixelSize()
   -- Hint: setMode changes the size of the window.
   love.graphics.setMode((field.width + 4) * pixel.width,
			 (field.height + 4) * pixel.height)
end

function togglePixelSize()

   pixel.width = math.random(2, 30)
   pixel.height = math.random(2, 30)

   setPixelSize()

end
```

Handling input
--------------

As you will see later, games are centered around **loops**. Usually there may be
60 iterations per second, but there may be more (or less). If we wanted to respond
to a key press, we could run our code when the key is down. However, if the user
held it down for a second, it would be called a lot of times!

The next function and the **isDown** table we set aside at the start helps us keep
track of when a key has been **pressed**. By pressed, we mean that the key was down
the last time we checked, but not anymore.

```lua
function wasPressed(k)

   if isDown[k] and not love.keyboard.isDown(k) then
      isDown[k] = false
      return true
   elseif love.keyboard.isDown(k) then
      isDown[k] = true
   end
   
   return false

end
```

Setting the table(s)
--------------------

We're nearing the end now, and just need one final helper before we're ready to put it
all together.

```lua
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
```
