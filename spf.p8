pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--spf
--a game by kyle neubarth & madeline lamee

sunangle = .25
mousex = 0
mousey = 0
mouseval = 0

//loaded objects
numrects = 0
numlines = 0
numlemmings = 0
numladders = 0
lines = {}
rects = {}
lemmings = {}
ladders = {}
numbuttons = 0
enablebuttons = true
buttons = {}

//level stuff
numlevels = -1
levels = {}
activelevel = 0
uistate = "menu"

wintimer = 0

lemmingsalive = 0
lemmingsneeded = 0
lemmingswon = 0
winzone = {0,0}
//lemming width, height, velocity
lemmingw = 8
lemmingh = 7
lemmingv = .2

function _init()
	//enable mouse tracking
	poke(0x5f2d, 1)
	addlevel(1,1, {-100,-100}, { {-10,1} })
	
	//
	addlevel(3,3, {100,106} , { {30,100},{40,100},{50,50} } )
	addlevelrect(50,80,20,10)
	addlevelrect(0,120,128,128)
	addlevelladder(60,80,39)

	loadassets(0)
	addbutton(64,94,30,10,"start","start",true)

end

function _update()
	mousex = stat(32)
	mousey = stat(33)
	mouseval = stat(34)
	
	updatesun()
	
	if uistate == "play" then
		updatelemmings()
		lemmingtriggers()
	else if enablebuttons then
		buttonstuff()
		//what?
		end
	end
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
	
	drawbuttons()
	
	if uistate == "load" then
		circtransition()
		if circtimer == 50 then
			clearbuttons()
			if activelevel > 0 then
				loadassets(activelevel)
			else
				reset()
				addbutton(30,64,30,10,"start","start",true)
			end
		end
		if circtimer > 110 then
			//uistate = "play"
			circtimer = 0
			if activelevel > 0 then
				uistate = "play"
			else 
				uistate = "menu"
				enablebuttons = true
			end
		end
	end
	if uistate == "play" then
		//color(0)
		//print("wow this level is fun",2,8)
		if lemmingsneeded > lemmingswon + lemmingsalive then
			if wintimer > 30 then
				lose()
				wintimer = 0
			else
				wintimer += 1
			end
		end
		if lemmingsneeded <= lemmingswon then
			if wintimer > 30 then
				win()
				wintimer = 0
			else
				wintimer += 1
			end
		end
		if lemmingswon >= lemmingsneeded then
			color(10)
			print("level complete!",64,64)
		end 
	end
	if uistate == "win" then
		popup()
	end
	if uistate == "lose" then
		popup()
	end
	spr(0,mousex-2,mousey-2)
end
-->8
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
	if uistate != "play" then
		return
	end
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

//syntax: sprite(pixelpos,x,y,numframes, numtilesx, numtilesy)		
	
	for k=1,numlemmings do
		//lemming is dead
		if lemmings[k].dead == true then
			
			//falling to ash
			
			if(lemmings[k].deathcounter == 13) then
				
				spr(12,lemmings[k].x, lemmings[k].y)
			else
				sprite(9,flr(lemmings[k].walkcounter/3),lemmings[k].x, lemmings[k].y)
	 		lemmings[k].deathcounter = 4*3
				lemmings[k].deathcounter += 1
			end
		//lemming is not dead
		else
		
			//lemming is in the sun
			if lemmings[k].exposure > 0 then
				//blinking
				sprite(3,flr(lemmings[k].walkcounter/6),lemmings[k].x, lemmings[k].y)
				lemmings[k].walkcounter %= 6*3
				lemmings[k].walkcounter += 1
				
			//lemming is safe
			else
				
				//walking
				sprite(0,flr(lemmings[k].walkcounter/3),lemmings[k].x, lemmings[k].y)
				lemmings[k].walkcounter %= 3*3
				lemmings[k].walkcounter += 1
				
			end
		end
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
		if lemmings[i].dead == true and lemmings[i].climbing == "up" then
			lemmings[i].climbing = "down"
		end
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
				
				//print jumping animation
				//sprite(l.x, l.y-16,16,16, )
				
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
--utility

function hcenter(s)
  return 64-#s*2
end

function coordtoangle(ax,ay)
	return atan2(ax-64,ay-64)
end
function reset()
	sunangle = .25
	
	numrects = 0
	numlines = 0
	numlemmings = 0
	numladders = 0
	lines = {}
	rects = {}
	lemmings = {}
	ladders = {}
	
	//level stuff
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
	newlevel.numladders = 0
	newlevel.rects = {}
	newlevel.lines = {}
	newlevel.ladders = {}
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
function addlevelladder(x,y,h)
	newladder = {}
	newladder.x = x
	newladder.y = y
	newladder.h = h
	levels[numlevels].numladders+=1
	levels[numlevels].ladders[levels[numlevels].numladders] = newladder
end
function loadassets(i)
	reset()
	level = levels[i]
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
	for j=1,level.numladders do
		l = level.ladders[j]
		addladder(l.x,l.y,l.h)
	end
end
-->8
--sprite/drawing stuff
--[[function sprite(pixelpos,frame,x,y,numtilesx,numtilesy)
	
	 xcount = 1
	 ycount = 1

		//loop traverses tiles in x direction
		while(xcount<=numtilesx)	do
			//loop traverses tiles in y direction
			while(ycount<=numtilesy)	do
				//print pixel tiles at that  position
				spr(pixelpos+frame,x,y)
				
				//increment y dir
				ycount = ycount +1
				pixelpos = pixelpos + 16
			end
			
			//increment x dir
			xcount=xcount+1
			pixelpos = pixelpos + 1
			
		end
		xcount = 1;
		ycount = 1;
		pixelpos = pixelpos+numtilesx
			
	
end
]]

function sprite(start, frame, x, y )
	spr(start+frame, x,y)
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
--ui
timer = 0
popuptimer = 0
function popup()
	popuptimer += .2*(1-popuptimer)
	timer+=1
	buttons[1].w = 80*popuptimer
	buttons[1].x = 64-buttons[1].w/2
	buttons[1].h = 20*popuptimer
	buttons[1].y = 64-buttons[1].h/2
	if popuptimer > .95 then
		s = (uistate == "win") and "you win!" or "you lose!"
		buttons[1].text = s
	end
	if timer == 50 then
	 s1 = "menu"
	 s2 = (uistate == "win") and "next" or "restart"
		addbutton(44,94,32,10,s1,"tomenu",true)
		addbutton(84,94,32,10,s2,s2,true)
	end
end
function popupinit()
	timer = 0
	popuptimer = 0
	addbutton(64,64,0,0,"","",false)
end
circtimer = 0
function circtransition()
	color(0)
	for i=1,18 do
		for j=1,18 do
			size = 0
			if circtimer <= 50 then
				size = min((i+j)+circtimer-50,7)
			else
				size = max(( (16-i)+(16-j) )+60-circtimer,-1)
			end
			circfill(i*8-12,j*8-12,size)
		end
	end
	
	circtimer+=1
end

function addbutton(x,y,w,h,text,command,can)
	newbutton = {}
	newbutton.x = x-w/2
	newbutton.y = y-h/2
	newbutton.w = w
	newbutton.h = h
	newbutton.text = text
	newbutton.command = command
	newbutton.canmouseover = can
	newbutton.mouseover = false
	numbuttons+=1
	buttons[numbuttons] = newbutton
end
function drawbuttons()
	for i=1,numbuttons do
		b = buttons[i]
		if (b.mouseover == true) and b.canmouseover then
		 color(6)
		else
			color(13)
		end
		rectfill(b.x,b.y,b.x+b.w,b.y+b.h)
		color(0)
		rect(b.x,b.y,b.x+b.w,b.y+b.h)
		print(b.text,hcenter(b.text)-63+b.x+b.w/2,b.y+b.h/2-2)
	end
end
function buttonstuff()
	for i=1,numbuttons do
		b = buttons[i]
		if i > numbuttons then
			return
		end
		if mousex >= b.x and mousex < b.x+b.w then
			if mousey >= b.y and mousey < b.y+b.h then
				buttons[i].mouseover = true
				if mouseval == 1 then
					//press button!
					processcommand(b.command)
					if numbuttons == 0 then
						return
					end
				end
			else
				buttons[i].mouseover = false
			end
		else
			buttons[i].mouseover = false
		end
	end
end
function processcommand(c)
	if c == "start" then
		activelevel = 1
		uistate = "load"
		enablebuttons = false
	end
	if c == "tomenu" then
		activelevel = 0
		uistate = "load"
		enablebuttons = false
		//addbutton(30,64,30,10,"start","start",true)
	end
	if c == "next" then
		activelevel += 1
		uistate = "load"
		enablebuttons = false
	end
	if c == "restart" then
		uistate = "load"
		enablebuttons = false
	end
end
function lose()
	uistate = "lose"
	popupinit()
	circtimer = 0
	enablebuttons = true
end
function win()
	uistate = "win"
	popupinit()
	circtimer = 0
	enablebuttons = true
end
function clearbuttons()
	buttons = {}
	numbuttons = 0
end
__gfx__
00999000009990000099900000999000009990000099900000999000009990000099900000999000000000000000000000000000000000000000000000000000
09999900099999000999990009999900099999000999990009999900099999000999990009999900009990000000000000000000000000000000000000000000
09f1f10009f1f10009f1f10009f1f10009e1e1000981810009e1e1000981810009f1f10009515100099999000099900000000000000000000000000000000000
09ffff0009ffff0009ffff0009ffff0009eeee000988880009eeee000988880009ffff0009555500095151000999990000005000000000000000000000000000
03333333003333330333330003333333003333330333330003333333003333330333330003333333095555000951510000055500000000000000000000000000
f033330f003f330ff0333000f033330f003e330e80333000e033330e00383308f033300050333305033333330955550000555500000000000000000000000000
0030030000600300003f00000030030000300300003800000030030000300300003f000000300300503553050355555305555550000000000000000000000000
00f00f000f000f0000f0000000f00f000e000e000080000000e00e000800080000f0000000500500055555505555555555555555000000000000000000000000
00000000000000000000000000000000800a008000800000800a0080008000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000a0000000000090000080000000009000008000000000000000000000000000000000000000000000000000000000000000000
0000000000000000900a0000000000000a0090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a000000000009000000000000000000a000080000000000a000080000000000000000000000000000000000000000000000000000000000000000
000a0000000000000a00900000000000009990000000800000000000000080000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000a00000099999000000090000000000000009000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000009990000000000009f1f1000000000000999000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a00000099999000000090009ffff000a000a000999990000000a000000000000000000000000000000000000000000000000000000000000000000
009990000000000009f1f10000000000033333330000000009f1f100000000000099900000000000000000000000000000000000000000000000000000000000
099999000000000009ffff000a000a00f033330f0008000009ffff00000000000999990000000000000000000000000000000000000000000000000000000000
09f1f1000000000003333333000000000030030000000000033333330000000009f1f10000000000000000000000000000000000000000000000000000000000
09ffff000a000a00f033330f0000000000f00f0000008000f033330f0000800009ffff0000000000000000000000000000000000000000000000000000000000
03333333000000000030030000000000000000000000000000300300000000000333333300000000000000000000000000000000000000000000000000000000
f033330f0000000000f00f0000000000000000000000000000f00f0000000000f033330f00000000000000000000000000000000000000000000000000000000
00300300000000000000000000000000000000000000000000000000000000000030030000000000000000000000000000000000000000000000000000000000
00f00f000000000000000000000000000000000000000000000000000000000000f00f0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009990000099900000999000009990000099900000999000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099999000999990009999900099999000999990009999900000000000000000000000000000000000000000000000000000000000000000000000000
0000000009f1f10009e1e1000981810009e1e1000981810009f1f100000000000000000000000000000000000000000000000000000000000000000000000000
0000000009ffff0009eeee000988880009eeee000988880009ffff00000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330033333303333300033333330033333303333300000000000000000000000000000000000000000000000000000000000000000000000000
00000000f033330f003e330e80333000e033330e00383308f0333000000000000000000000000000000000000000000000000000000000000000000000000000
000000000030030000300300003800000030030000300300003f0000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f00f000e000e000080000000e00e000800080000f00000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000300000000000000003000000000000000003000000000000030000000000000030000000000000030000000000000000000000000000000300000000
00003333330000000000033333300000000000033333300000000333333000000000333333000000000333333000000000033330000000000003333330000000
00003333330000000000033333300000000000033333300000000333333000000000333333000000000333333000000000333330000000000003333330000000
003bbbb0b03330000003bbbb0b033300000003bbbb0b03330003bbbb0b033300003bbbb0b033300003bbbb0b033300000bbb0b033300000003bbbb0b03330000
33b4430bbbb03300033b4430bbbb0330000033b4430bbbb0033b4430bbbb033033b4430bbbb033033b4430bbbb0330034430bbbb033000003b4430bbbb033000
0bb34b034bbb033000bb34b034bbb033000bb34b034bbb0300bb34b034bbb0330bb34b034bbb0330bb34b034bbb0330bb34b034bbb033000bb34b034bbb03300
00400404004000000004004040040000000040040400400000040040400400000040040400400000004004040040000000400404004000000040040400400000
00000404400000000000004044000000000000404400000000000040440000000000040440000000000004044000000000000404400000000000040440000000
00000044000000000000000440000000000000044000000000000004400000000000004400000000000000440000000000000044000000000000004400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
00000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000400000000
