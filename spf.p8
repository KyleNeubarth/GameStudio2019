pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--spf
--a game by kyle neubarth & madeline lamee

sunangle = .25
mousex = 0
mousey = 0

//loaded objects
numrects = 0
numlines = 0
numlemmings = 0
numladders = 0
lines = {}
rects = {}
lemmings = {}
ladders = {}

//level stuff
numlevels = 0
levels = {}
activelevel = 0
lemmingsalive = 0
lemmingsneeded = 0
lemmingswon = 0
winzone = {0,0}
//lemming width, height, velocity
lemmingw = 3
lemmingh = 5
lemmingv = .2

function _init()
	//enable mouse tracking
	poke(0x5f2d, 1)
	addlevel(3,3, {100,106} , { {30,100},{40,100},{50,50} } )
	addlevelrect(50,80,20,10)
	addlevelrect(0,120,128,128)
	loadlevel(1)
	
	addladder(60,80,39)
end

function _update()
	mousex = stat(32)
	mousey = stat(33)
	
	updatesun()
	updatelemmings()
	lemmingtriggers()
end

function _draw()
	//clearscreen
	color(12)
	rectfill(0,0,128,128)
	
	shadows()
	detectshade()
	drawrects()
	drawladders()
	drawlemmings()
	drawsun()
	color(11)
	rect(winzone[1],winzone[2],winzone[1]+16,winzone[2]+16)
	color(0)
	print(lemmings[1].climbing,2,8)
	print(lemmings[2].climbing,2,14)
	print(lemmings[3].climbing,2,20)
	print(numlemmings,32,2)
	if lemmingswon >= lemmingsneeded then
		color(10)
		print("level complete!",64,64)
	end 
end
-->8
--draw functions

function drawsun()
	color(10)
	circfill(64 + 50*cos(sunangle),44 + 30*sin(sunangle),10)
	//print(sunangle,0,0)
end
function drawladders()
	color(4)
	for i=1,numladders do
		l = ladders[i]
		line(l.x,l.y,l.x,l.y+l.h)
	end
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
function detectshade()

	for k=1,numlemmings do
		if lemmings[k].dead == false then
			
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
			else 
				lemmings[k].exposure=0
			end
		end
	end
end
function drawlemmings()
	for k=1,numlemmings do
		if lemmings[k].dead == true then
		color(3)
		//sprite(x,y,animpos+anim)
		else
			if lemmings[k].exposure > 0 then
				color(8)
			else
				color(11)
			end
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
		
		//ladder movement
		
		ny = (lemmings[i].dead) and .4 or .2
		if lemmings[i].climbing == "up" then
			ny *= -1
			ny += lemmings[i].y
			lad = ladders[lemmings[i].ladderid]
			if ny+lemmingh <= lad.y then
				lemmings[i].climbing = "not"
			end
			lemmings[i].y = ny
		else if lemmings[i].climbing == "down" then
			ny += lemmings[i].y
			lad = ladders[lemmings[i].ladderid]
			if ny+lemmingh >= lad.y+lad.h then
				lemmings[i].climbing = "not"
			end
			lemmings[i].y = ny
		else
			
			//check for platform below
			dx = lemmingv*( (lemmings[i].dir == "right") and 1 or -1)
			nx = dx + ( (lemmings[i].dir == "right") and (lemmings[i].x + lemmingw) or lemmings[i].x)
			
			ny = lemmings[i].y+lemmingh+1
			
			platform_below = false
			for j=1,numrects do
				r = rects[j]
				if (ny >= r.y and ny <= r.y+r.h) then
					for k=-1,lemmingw do
						nx = lemmings[i].x + k
						if (nx >= r.x and nx <= r.x+r.w) then
							//there's a platform
							platform_below = true
							goto platform_below
						end
					end
				end
			end
			::platform_below::
			if platform_below == false then
				dy = .4
				ny = .4 + lemmings[i].y+lemmingh
			
				fall_hit = false
				for j=1,numrects do
					r = rects[j]
					if (ny >= r.y and ny <= r.y+r.h) then
						for k=0,lemmingw-1 do
							nx = lemmings[i].x + k
							if (nx >= r.x and nx <= r.x+r.w) then
								//there's a platform
								fall_hit = true
								goto hit_ground
							end
						end
					end
				end
								
				::hit_ground::
				if hit_ground == true then
					dy = -(ny-.4) + r.y+r.h+2
				end
				lemmings[i].y += dy
			else
				//sideways collision
				if lemmings[i].dead == true then
					goto lemming_loop
				end
				dx = lemmingv*( (lemmings[i].dir == "right") and 1 or -1)
				nx = dx + ( (lemmings[i].dir == "right") and (lemmings[i].x + lemmingw) or lemmings[i].x - 1)
				
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
						dx = -(nx-dx) + (lemmings[i].dir == "right" and r.x-1 or r.x+r.w+2)
						lemmings[i].dir = lemmings[i].dir == "right" and "left" or "right"
					end
				end
				
				for m=1,numladders do
					lad = ladders[m]
					if abs(nx - lad.x) < 1 and ( (lemmings[i].dir == "right" and lemmings[i].x < lad.x) or (lemmings[i].dir == "left" and lemmings[i].x > lad.x) ) then
						if (ny+lemmingh >= lad.y and ny <= lad.y+lad.h) then
							if ny > lad.y+lad.h/2 then
									lemmings[i].climbing = "up"
								else
									lemmings[i].climbing = "down"
								end
								lemmings[i].ladderid = m
								lemmings[i].x = lad.x - lemmingw/2
								goto lemming_loop
							end
						end
					end
				
					lemmings[i].x += dx
				end
			end
		end
		::lemming_loop::
	end
end
function lemmingtriggers()
	//end of level
	for i=1,numlemmings do
		l = lemmings[i]
		if l.x >= winzone[1] and l.x+lemmingw <= winzone[1]+16 then
			if l.y >= winzone[2] and l.y+lemmingh <= winzone[2]+16 then
				lemmingsalive-=1
				lemmingswon+=1
				removelemming(i)
				i-=1
			end
		end
		//check exposure
		if lemmings[i].dead == false and lemmings[i].exposure > 100 then
			lemmingsalive-=1
			lemmings[i].dead = true
		end
	end
end
//cursed_function
function removelemming(i)
	if numlemmings > 1 then
		lemmings[i] = lemmings[numlemmings]
	end
	numlemmings-=1
end
-->8
--constructors/add functions

function addladder(x,y,h)
	newladder = {}
	newladder.x = x
	newladder.y = y
	newladder.h = h
	numladders+=1
	ladders[numladders] = newladder
end
function addlemming(x,y)
	newlemming = {}
	newlemming.x = x
	newlemming.y = y
	newlemming.dir = "right"
	//animation frame
	newlemming.anim = 0
	newlemming.climbing = "not"
	newlemming.ladderid = 0
	//if not 0, in the sun
	newlemming.exposure = 0
	//true on death
	newlemming.dead = false
	//frames since death
	newlemming.deathcounter = 0
	newlemming.walkcounter = 0
	newlemming.blinkcounter = 0
	//
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
function reset()
	sunangle = .25
	
	numrects = 0
	numlines = 0
	numlemmings = 0
	lines = {}
	rects = {}
	lemmings = {}
	
	//level stuff
	activelevel = 0
	lemmingsalive = 0
	lemmingsneeded = 0
	lemmingswon = 0
	winzone = {0,0}
end
-->8
--levelsystem
//# lemmings, # lemmings to complte level
function addlevel(numl,nums,win,spawns)
	newlevel = {}
	//must set rects and lines yourself
	newlevel.numrects = 0
	newlevel.numlines = 0
	newlevel.rects = {}
	newlevel.lines = {}
	newlevel.numlemmings = numl
	newlevel.spawnpoints = spawns
	newlevel.numsurvive = nums
	newlevel.winzone = win
	numlevels+=1
	levels[numlevels] = newlevel
end
function addlevelrect(x,y,w,h)
	newrect = {}
	newrect.x = x
	newrect.y = y
	newrect.w = w
	newrect.h = h
	levels[numlevels].numrects+=1
	levels[numlevels].rects[levels[numlevels].numrects] = newrect
end
function loadlevel(i)
	reset()
	level = levels[i]
	activelevel = i
	lemmingsalive = level.numlemmings
	lemmingsneeded = level.numsurvive
	winzone = level.winzone
	for j=1,level.numrects do
		r=level.rects[j]
		addrect(r.x,r.y,r.w,r.h)
	end
	for j=1,level.numlemmings do
		s = level.spawnpoints[j]
		addlemming(s[1],s[2])
	end
end
-->8
--sprite/drawing stuff
function sprite()
	
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
