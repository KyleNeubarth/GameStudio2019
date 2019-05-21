pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--spf
--a game by kyle neubarth & madeline lamee

sunangle = .25
mousex = 0
mousey = 0

numrects = 0
numlines = 0
numlemmings = 0
lines = {}
rects = {}
lemmings = {}

//lemming width, height, velocity
lemmingw = 3
lemmingh = 5
lemmingv = .2

function _init()
	//enable mouse tracking
	poke(0x5f2d, 1)
	addrect(50,80,20,10)
	addrect(100,50,120,128)
	addrect(8,50,28,128)
	addlemming(64,100)
end

function _update()
	mousex = stat(32)
	mousey = stat(33)
	
	updatesun()
	updatelemmings()
end

function _draw()
	//clearscreen
	color(12)
	rectfill(0,0,128,128)
	
	shadows()
	drawrects()
	drawlemmings()
	drawsun()
end
-->8
--draw functions

function drawsun()
	color(10)
	circfill(64 + 50*cos(sunangle),44 + 30*sin(sunangle),10)
	print(sunangle,0,0)
end
function drawrects()
	color(1)
	for i=1,numrects do
		rectfill(rects[i].x,rects[i].y,rects[i].x+rects[i].w,rects[i].y+rects[i].h)
	end
end
function shadows()
	for i=1,numlines do
		x = lines[i].x
		y = lines[i].y
		x2 = lines[i].x2
		y2 = lines[i].y2
		color(0)
		for j=1,130 do
			dx = -j*cos(sunangle)
			dy = -j*sin(sunangle)
			line(x+dx,y+dy,x2+dx,y2+dy)
		end
	end
end
function drawlemmings()

	for k=1,numlemmings do
		//sun detect code
		//must be done in draw
		//detection is after shadows are drawm
		sun = false
		for i=0,lemmingw-1 do
			for j=0,lemmingh-1 do
				if pget(lemmings[k].x+i,lemmings[k].y+j) != 0 then
						sun = true
						goto found_sun
					break
				end
			end
		end
		::found_sun::
		if sun == true then
			lemmings[k].exposure+=1
			color(8)
		else
			color(11)
		end
		
		rectfill(lemmings[k].x,lemmings[k].y,lemmings[k].x+lemmingw,lemmings[k].y+lemmingh)
	end
end
-->8
--update functions
function updatesun()
	angle = coordtoangle(mousex,abs(-mousey+64)-64)
	//circfill(64 + cos(angle)*50,64+sin(angle)*50,3)
	sunangle += .2*(angle-sunangle)
end
function updatelemmings()
	for i=1,numlemmings do
		dx = lemmingv*( (lemmings[i].dir == "right") and 1 or -1)
		nx = dx + ( (lemmings[i].dir == "right") and (lemmings[i].x + lemmingw) or lemmings[i].x)
		
		for j=1,numrects do
			r = rects[j]
			hit = false
			if (nx >= r.x and nx <= r.x+r.w) then
				for k=0,lemmingh-1 do
					ny = lemmings[i].y + k
					if (ny >= r.y and ny <= r.y+r.h) then
						//hits rect
						hit = true
						goto hit_rect
					end
				end
			end
			::hit_rect::
			if hit == true then
				dx = -(nx-dx) + (lemmings[i].dir == "right" and r.x or r.x+r.w)
				lemmings[i].dir = lemmings[i].dir == "right" and "left" or "right"
			end
		end
		
		lemmings[i].x += dx
		
	end
end
-->8
--constructors/add functions

function addlemming(x,y)
	newlemming = {}
	newlemming.x = x
	newlemming.y = y
	newlemming.dir = "right"
	newlemming.exposure = 0
	numlemmings+=1
	lemmings[numlemmings] = newlemming
end
function addrect(x,y,w,h)
	newrect = {}
	newrect.x = x
	newrect.y = y
	newrect.w = w
	newrect.h = h
	addline(x,y,x+w,y)
	addline(x,y,x,y+h)
	addline(x+w,y+h,x+w,y)
	addline(x+w,y+h,x,y+h)
	numrects+=1
	rects[numrects] = newrect
end
function addline(x,y,x2,y2)
	newline = {}
	newline.x = x
	newline.y = y
	newline.x2 = x2
	newline.y2 = y2
	numlines+=1
	lines[numlines] = newline
end
-->8
--utility

function coordtoangle(ax,ay)
	return atan2(ax-64,ay-64)
end
//delete if unused
function round(a)
	if a%1 <= .5 then
		a += 1
	end
	return flr(a)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
