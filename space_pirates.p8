pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--space_pirate
--by kyle and albert

x = 0 y = 0 rot = 0.25
vel = 0
friction = .98 dead = true start = true
fuel = 50

--bullet structure: x,y,rot,age
numbullets = 0
bullets = {}
bulletvel = 4
bulletmaxage = 50
cooldown = 3
cooldowncurr = 0
wavecooldown = 0
score = 0

--ship size
l = 4
l2 = 3

--zone stuff
zx = 0
zy = 0
complete = true
numasteroids = 0
asteroids = {}

--sound waves
numwaves = 0    waves = {}
numenemies = 0  enemies = {}
numnodes = 0    nodes = {}

newfueltimer = 0
newfuely = 0
newfuelh = 0

--[[
function _update()
   for i=0,5,1 do
     if btnp(i) then new_game() end
   end
end
]]-- 
-- try to have a start of the game 

function _update()
	if dead then
		return
	end
	if (btn(0)) then rot += 0.02 end
	if (btn(1)) then rot -= 0.02 end
	if (rot > 1) then rot -= 1 end
	if (rot < 0) then rot += 1 end
	if (btn(3)) then vel *= .9 end
	
	--collision
	for i=1,numasteroids do
		dist = pyth(x-asteroids[i].x,y-asteroids[i].y)
		if dist > 0 and dist < 3 + asteroids[i].size then
			dead = true
			endtime = time()
			sfx(2)
			--print(pyth(x-asteroids[i].x,y-asteroids[i].y),0,50)
		end
		for j=1,numbullets do
			bulletdist = pyth(bullets[j][1]-asteroids[i].x,bullets[j][2]-asteroids[i].y)
			if bulletdist > 0 and bulletdist <= asteroids[i].size then
				--add wave from bullet
				if bullets[j][6] == true then
					addwave(1,bullets[j][1],bullets[j][2],true)
				else
					addwave(1,bullets[j][1],bullets[j][2])
				end
				if asteroids[i].size > 3 then
					asteroids[i].size -= 1
				else
					if numasteroids != 1 then
						asteroids[i] = asteroids[numasteroids]
					end
					numasteroids -= 1
				end
				killbullet(j)
			end
		end
	end
	for i=1,numenemies do
		for j=1,numwaves do
			dist = pyth(enemies[i].x-waves[j].x,enemies[i].y-waves[j].y)
			if dist > 0 and dist < 2+waves[j].size then
				if enemies[i].alert == false then
					addwave(3,enemies[i].x,enemies[i].y,true)
				end
				if enemies[i].alert == false then
					sfx(9)
					enemies[i].alert = true
				end
			end
		end
		for j=1,numbullets do
		
		end
	end
	
	if (btn(4)) then
		if (cooldowncurr == 0) then
			numbullets += 1
			bullets[numbullets] = {x+cos(rot)*l,y+sin(rot)*l,rot+rnd(.02)-.01,0,bulletvel+vel,0}
			cooldowncurr = cooldown
		end
		sfx(0)
	end
	if cooldowncurr > 0 then
		cooldowncurr -= 1
	end
	if (btn(5)) then
		vel += (3.5-vel)*(1/2.5)*.2
		fuel -= .01
		sfx(3)
	end

	
	for i=1,numbullets do
		if bullets[i][4] > bulletmaxage then
			bullets[i][4] = 0
			killbullet(i)
		end
		bullets[i][1] += bullets[i][5]*cos(bullets[i][3])
		bullets[i][2] += bullets[i][5]*sin(bullets[i][3])
		bullets[i][4] += 1
		
		dist = pyth(x-bullets[i][1],y-bullets[i][2])
		if dist > 0 and dist < 3 then
			dead = true
			endtime = time()
			sfx(2)
		end
	end
	
	if (btn(2)) then 
		if vel < 1.1 then
			vel += (2-vel)* .03
		else
			vel += .04
		end
		sfx(4)
	end
	if (vel > 5) then vel = 5 end
	
	x += cos(rot)*vel
	y += sin(rot)*vel
	
	if vel>.2 then
		if wavecooldown == 10 then
			addwave(vel*.75,x-cos(rot)*3,y-sin(rot)*3)
			wavecooldown=0
		else
			wavecooldown += 1
		end
	end
	
	fuel -= .01*vel
	
	vel *= friction
	
	updatestars()
	dist = pyth(x-zx,y-zy)
	if dist > 300 and complete == true then
		makezone()
	elseif dist < 10 and dist > 0 and complete == false then
		complete = true
		newfueltimer = 50
			newfuely = 94-fuel
			fuel+=5
			fuelcollected += 5
			newfuelh = 5
			sfx(7)
			score += 20
	end
	--soundwave
	for i=1,numwaves do
		waves[i].size = waves[i].size+waves[i].mag
		waves[i].mag *= .95
		if waves[i].mag < .2 then
			waves[i].blink = not waves[i].blink
		end
	end
	for i=1,numwaves do
		if waves[i].mag < .1 then
			killwave(i)
		end
	end
	
	for i=1,numenemies do
		if enemies[i].alert then
			erot = enemies[i].rot
			dest = atan2(x-enemies[i].x,y-enemies[i].y)
			wrap = abs(dest-erot) > .5
			if dest > erot then
				if wrap then
					enemies[i].rot -= .01
				else
					enemies[i].rot += .01
				end
			else
				if wrap then
					enemies[i].rot += .01
				else
					enemies[i].rot -= .01
				end
			end
			enemies[i].rot %= 1
			
			if enemies[i].blink == 0 then
				numbullets += 1
				bullets[numbullets] = {enemies[i].x+cos(enemies[i].rot)*5,enemies[i].y+sin(enemies[i].rot)*5,enemies[i].rot+rnd(.01)-.005,0,bulletvel,1}
				sfx(1)
			end
		end
		for j=1,numbullets do
			dist = pyth(bullets[j][1]-enemies[i].x,bullets[j][2]-enemies[i].y)
			if dist > 0 and dist < 3 then
				addwave(1.5,enemies[i].x,enemies[i].y,true)
				kills += 1
				killenemy(i)
				sfx(5)
				score += 5
			end
		end
		dist = pyth(x-enemies[i].x,y-enemies[i].y)
		if dist > 0 and dist < 5 then
			dead = true
			endtime = time()
			sfx(2)
		end
	end
	for i=1,numnodes do
		dist = pyth(x-nodes[i].x,y-nodes[i].y)
		if dist > 0 and dist < 2 then
			killnode(i)
			newfueltimer = 50
			newfuely = 94-fuel
			fuel+=3
			fuelcollected += 3
			newfuelh = 3
			sfx(7)
			score += 10
		end	
	end
end

function _draw()
	--map(0,0,0,0,16,16)
	-- if start then centerprint('press any button to start',100,94) end
	-- try the begin print of the game 

	if dead then
		--print("you dead",hcenter("you dead"),64)
		ui()	
		return
	end
	cls()
	drawstars()
	if complete then
		color(3)
	else
		color(5)
	end
	rect(-x+54+zx,-y+54+zy,-x+74+zx,-y+74+zy)
	color(6)
	--line(64+cos(rot)*l,64+sin(rot)*l,64-l*cos(rot)-l2*sin(rot),64-l*sin(rot)+l2*cos(rot))
	--line(64+cos(rot)*l,64+sin(rot)*l,64-l*cos(rot)+l2*sin(rot),64-l*sin(rot)-l2*cos(rot))
	--line(64-l*cos(rot)+l2*sin(rot),64-l*sin(rot)-l2*cos(rot),64-l*cos(rot)-l2*sin(rot),64-l*sin(rot)+l2*cos(rot))
	drawship(l,l2,64,64,rot)
	--drawenemy(64,64,rot)
	--bullets
	for i=1,numbullets do
		if bullets[i][6] == 1 then
			color(8)
		else
			color(11)
		end
		--print(bullets[i][1],0,(i-1)*10)
		line(bullets[i][1]+64-x,bullets[i][2]+64-y,bullets[i][1]+64-x+cos(bullets[i][3])*5,bullets[i][2]+64-y+sin(bullets[i][3])*5)
		--circ(bullets[i][1]+64-x,bullets[i][2]+64-y,bullets[i][4])
	end
	for i=1,numwaves do
		if not waves[i].blink then
			if waves[i].enemy then
				color(2)
			else
				color(13)
			end
			circ(waves[i].x+64-x,waves[i].y+64-y,waves[i].size)
		end
	end
	drawasteroids()
	for i=1,numenemies do
		color(6)
		if enemies[i].alert then
			if enemies[i].blink > 10 then
				color(8)
			end
			enemies[i].blink -= 1
			if enemies[i].blink < 0 then
				enemies[i].blink += 20
			end
		end
		drawenemy(enemies[i].x+64-x,enemies[i].y+64-y,enemies[i].rot)
	end
	for i=1,numnodes do
		color(7)
		circ(nodes[i].x+64-x,nodes[i].y+64-y,2)
		color(10)
		circfill(nodes[i].x+64-x,nodes[i].y+64-y,1)
	end
	arrow()
	--print(numenemies,0,0)
	color(5)
	circfill(7,43,5)
	print("f",6,38,6)
	color(5)
	rectfill(2,95,12,43)
	color(15)
	rectfill(3,94,11,44)
	color(10)
	rectfill(3,94,11,94-fuel)
	color(5)
	circfill(12,100,11)
	color(6)
	print(vel,2,115)
	circfill(12,100,10)
	color(8)
	line(12,103,12+8*cos(.5-vel*1/5),103+8*sin(.5-vel*1/5));
	rect(0,0,127,127,1)

	print('score: '..score,80,10,7) -- try to print score 

	if newfueltimer > 0 then
		newfueltimer -= 1
		color(9)
		rectfill(3,newfuely,11,newfuely-newfuelh)
	end
end
-->8
--functions
function drawship(l1,l2,x,y,rot) 
	--line(64, 64, 64+cos(rot)*l, 64+sin(rot)*l)
	--line(64, 64, 64-sin(rot)*2*l2, 64+cos(rot)*2*l2)
	--line(64, 64, 64+sin(rot)*2*l2, 64-cos(rot)*2*l2)
	
	line(x+cos(rot)*l,y+sin(rot)*l,x-l*cos(rot)-l2*sin(rot),y-l*sin(rot)+l2*cos(rot))
	line(x+cos(rot)*l,y+sin(rot)*l,x-l*cos(rot)+l2*sin(rot),y-l*sin(rot)-l2*cos(rot))
	line(x-l*cos(rot)+l2*sin(rot),y-l*sin(rot)-l2*cos(rot),x-l*cos(rot)-l2*sin(rot),y-l*sin(rot)+l2*cos(rot))
	
	
	--line(64+sin(rot)*2*l2, 64-cos(rot)*2*l2, 64+sin(rot)*2*l2-cos(rot)*2*l, 64-cos(rot)*l2-sin(rot)*2*l)
	--line(64-sin(rot)*2*l2, 64+cos(rot)*2*l2, 64-sin(rot)*2*l2-cos(rot)*2*l, 64+cos(rot)*l2-sin(rot)*2*l)
	--line(64+sin(rot)*2*l2-cos(rot)*2*l, 64-cos(rot)*l2-sin(rot)*2*l, 64-sin(rot)*l2-cos(rot)*2*l, 64+cos(rot)*l2-sin(rot)*2*l)
end
function drawenemy(x,y,rot)
	
	circ(x,y,2)
	line(x,y,x+5*cos(rot),y+5*sin(rot))
end

function killbullet(i)
	if numbullets != 1 then
		bullets[i] = bullets[numbullets]
	end
	numbullets -= 1
end
function killwave(i)
	if numwaves != 1 then
		waves[i] = waves[numwaves]
	end
	numwaves -= 1
end
function killenemy(i)
	if numenemies != 1 then
		enemies[i] = enemies[numenemies]
	end
	numenemies -= 1
end
function killnode(i)
	if numnodes != 1 then
		nodes[i] = nodes[numnodes]
	end
	numnodes -= 1
end
function node()
	local self = {}
	angle = rnd(1)
	dist = rnd(30)+30 
	self.x = zx + cos(angle)*dist
	self.y = zy + sin(angle)*dist
	return self
end
function enemy()
	local self = {}
	angle = rnd(1)
	dist = rnd(80)+30
	self.rot = rnd(1)
	self.x = zx + cos(angle)*dist
	self.y = zy + sin(angle)*dist
	self.alert = false
	self.blink = 20
	return self
end
function asteroid()
	local self = {}
	self.size = rnd(5)+5
	angle = rnd(1)
	dist = rnd(120)+20
	self.x = zx + cos(angle)*dist
	self.y = zy + sin(angle)*dist
	return self
end
function soundwave(mag,mx,my,enemy)
	local self = {}
	self.x = mx+0
	self.y = my+0
	self.mag = mag+0
	--self.mag = mag
	self.size = 0
	self.blink = false
	self.enemy = enemy
	return self
end
function addwave(mag,mx,my)
	numwaves+=1
	waves[numwaves] = soundwave(mag,mx,my,false)
end
function addwave(mag,mx,my,enemy)
	numwaves+=1
	waves[numwaves] = soundwave(mag,mx,my,enemy)
end

function drawasteroids()
	for i=1,numasteroids do
		circfill(asteroids[i].x+64-x,asteroids[i].y+64-y,asteroids[i].size,5)
	end
end

function hcenter(s)
  return 64-#s*2
end

function pyth(ax,ay)
	ax = flr(ax)
	ay = flr(ay)
	if ax>ay then
		nx = ax/ay
		ny = 1
		return sqrt((nx^2)+(ny^2))*abs(ay)
	else
	 ny = ay/ax
	 nx =1
	 return sqrt((nx^2)+(ny^2))*abs(ax)
	end
end

function makezone()
	numasteroids = 0
	numnodes = 0
	numenemies = 0
	
	angle = .5 + zoneangle() + rnd(.5)-.25
	dist = rnd(400)+400
	zx = x+cos(angle)*dist
	zy = y+sin(angle)*dist
	complete = false
	for i=1,flr(rnd(12)+6) do
		numasteroids += 1
		asteroids[numasteroids] = asteroid()
	end
	for i=1,flr(rnd(8)+3) do
		numenemies += 1
		enemies[numenemies] = enemy()
	end
	for i=1,flr(rnd(4)+2) do
		numnodes += 1
		nodes[numnodes] = node()
	end
end

al = 8
al2 = 5

function arrow()
	--print(zx,0,0)
	--print(zy,0,6)
	--print(pyth(x-zx,y-zy),0,0)
	dist = pyth(x-zx,y-zy)
	if dist > 150 and complete == false then
		angle = zoneangle()
		color(8)
		circ(64+50*cos(angle),64+50*sin(angle),10*150/dist)
		
	end	
end

function zoneangle()
	dx = x - zx
	dy = y - zy
	angle = .5 + atan2(dx,dy)
	return angle
	--circ(64+32*cos(angle),64+32*sin(angle),10)
end
-->8
--star back grounds 

savel = .2
sbvel = .4
scvel = .6

function _init()
 -- init variables
 stars={}
 star_cols={1,2}
 starsb={}
 star_colsb={5,6}
 starsc={}
 star_colsc={7,12}

 -- create starfield
 for i=1,#star_cols do
  for j=1,8 do -- the density of the stars 
   local s={
    x=rnd(128),
    y=rnd(128),
    z=i,
    c=star_cols[i]
   }
   add(stars,s)
    local sb={
    x=rnd(128),
    y=rnd(128),
    z=i,
    c=star_colsb[i]
   }
   add(starsb,sb)
    local sc={
    x=rnd(128),
    y=rnd(128),
    z=i,
    c=star_colsc[i]
   }
   add(starsc,sc)
  end 
 end
end

function updatestars()
 -- move stars
 for s in all(stars) do
	 --if btn(0) then s.x += 1 end -- create the response of the background 
  --if btn(1) then s.x -= 1 end
  --if btn(2) then s.y += 1 end
  --if btn(3) then s.y -= 1 end
  s.x -= cos(rot)*vel*savel
  s.y -= sin(rot)*vel*savel
  -- wrap star around the screen
  if s.y>128 then
   s.y=0
   s.x=rnd(128)
  end
  if s.x>128 then
   s.x=0
   s.y=rnd(128)
  end
  if s.y<0 then
   s.y=128
   s.x=rnd(128)
  end
  if s.x<0 then
   s.x=128
   s.y=rnd(128)
  end
 end
  -- move stars
 for sb in all(starsb) do
   --if btn(0) then sb.x += 2 end -- create the response of the background layer b
   --if btn(1) then sb.x -= 2 end
   --if btn(2) then sb.y += 2 end
   --if btn(3) then sb.y -= 2 end
  	sb.x -= cos(rot)*vel*sbvel
  	sb.y -= sin(rot)*vel*sbvel
  -- wrap star around the screen
  if sb.y>128 then
   sb.y=0
   sb.x=rnd(128)
  end
  if sb.x>128 then
   sb.x=0
   sb.y=rnd(128)
  end
  if sb.y<0 then
   sb.y=128
   sb.x=rnd(128)
  end
  if sb.x<0 then
   sb.x=128
   sb.y=rnd(128)
  end
 end
  -- move stars
 for sc in all(starsc) do
   --if btn(0) then sc.x += 3 end -- create the response of the background for layer c
   --if btn(1) then sc.x -= 3 end
   --if btn(2) then sc.y += 3 end
   --if btn(3) then sc.y -= 3 end
  	sc.x -= cos(rot)*vel*scvel
  	sc.y -= sin(rot)*vel*scvel
  -- wrap star around the screen
  if sc.y>128 then
   sc.y=0
   sc.x=rnd(128)
  end
  if sc.x>128 then
   sc.x=0
   sc.y=rnd(128)
  end
  if sc.y<0 then
   sc.y=128
   sc.x=rnd(128)
  end
  if sc.x<0 then
   sc.x=128
   sc.y=rnd(128)
  end
 end
end

function drawstars()
 cls()
 -- draw stars
 for s in all(stars) do
  pset(s.x,s.y,s.c)
 end
 for sb in all(starsb) do
  pset(sb.x,sb.y,sb.c)
 end
 for sc in all(starsc) do
  pset(sc.x,sc.y,sc.c)
 end
end
-->8
--ui
uistate = ""
dwavesize = 0

--score vars
fuelcollected = 0
kills = 0
starttime = 0
endtime = 0

keyblink = 0

function newgame()
	sfx(8)	
	start = false
	
	dwavesize = 0
	fuelcollected = 0
	kills = 0
	starttime = 0
	endtime = 0
	
	x = 0 y = 0 rot = 0.25
	vel = 0
	friction = .98 dead = false
	fuel = 50
	
	numbullets = 0
	bullets = {}
	bulletvel = 4
	bulletmaxage = 50
	cooldown = 3
	cooldowncurr = 0
	wavecooldown = 0
	score = 0
	
	--zone stuff
zx = 0
zy = 0
complete = true
numasteroids = 0
asteroids = {}

--sound waves
numwaves = 0    waves = {}
numenemies = 0  enemies = {}
numnodes = 0    nodes = {}

newfueltimer = 0
newfuely = 0
newfuelh = 0
end

function anykey()
	if keyblink > 15 then
		color(6)
		print("-press any key to start-",hcenter("-press any key to start-"),104)
	end
	if keyblink < 1 then
		keyblink += 30
	end
	keyblink-= 1
	for i=1,5 do
		if btnp(i) then newgame() end
	end
end

function ui()
	if start == true then
		cls()
		vel = 5
		updatestars()
		drawstars()
		map(0,0,0,0,16,16)
		color(6)
	print("a game by",hcenter("a game by"),68)
	color(10)
	print("albert jin",hcenter("albert jin"),74)
	color(6)
	print("and",hcenter("and"),80)
	color(10)
	print("kyle neubarth",hcenter("kyle neubarth"),86)
	
		anykey()
	elseif dead == true then
		dwavesize+=1
		color(13)
		circ(64,64,dwavesize+1)
		color(0)
		circfill(64,64,dwavesize)
		if (dwavesize >= 30) then
			color(8)
			print("wasted",hcenter("wasted"),54)
		end
		color(6)
		if dwavesize >= 50 then
			print('picked up '.. fuelcollected .. ' units of fuel',hcenter('picked up '.. fuelcollected .. ' units of fuel'),64)
		end
		if dwavesize >= 60 then
			print('blasted ' .. kills .. ' sentries',hcenter('blasted ' .. kills .. ' sentries'),74)
		end
		if dwavesize >= 70 then
			print('survived '..flr(endtime-starttime)..' seconds',hcenter('survived '..flr(endtime-starttime)..' seconds'),84)
		end
		if dwavesize > 80 then
			color(10)
			print('your score is '..score..'!',hcenter('your score is '..score..'!'),94)
			anykey()
		end
	end
end
__gfx__
00000000666666660066666666600666666666006666666660066666666600000006666666660066006666666660066666666600666666666600666666666000
00000000666666660066666666600666666666006666666660066666666600000006666666660066006666666660066666666600666666666600666666666000
00700700660000000066000006600660000066006600000000066000000000000006600000660066006600000660066000006600000066000000660000000000
00077000660000000066000006600660000066006600000000066000000000000006600000660066006600000660066000006600000066000000660000000000
00077000660000000066000006600660000066006600000000066000000000000006600000660066006600000660066000006600000066000000660000000000
00700700660000000066000006600660000066006600000000066666660000000006600000660066006666666660066000006600000066000000666666600000
00000000666666660066666666600666666666006600000000066666660000000006666666660066006666666660066666666600000066000000666666600000
00000000666666660066666666600666666666006600000000066000000000000006666666660066006660000000066666666600000066000000660000000000
00000000000000660066000000000660000066006600000000066000000000000006600000000066006666600000066000006600000066000000660000000000
00000000000000660066000000000660000066006600000000066000000000000006600000000066006606666000066000006600000066000000660000000000
00000000000000660066000000000660000066006600000000066000000000000006600000000066006600066660066000006600000066000000660000000000
00000000666666660066000000000660000066006666666660066666666600000006600000000066006600000660066000006600000066000000666666666000
00000000666666660066000000000660000066006666666660066666666600000006600000000066006600000660066000006600000066000000666666666000
__map__
2122232421222324212223242122232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132333431323334313233343132333400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2122232122232424212223242122232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132333132333434313233343132333410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4142434142434444414243444142434420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5152535451525354515253545152535430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000102030405060708090a0b0c0d0e0f40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001112131415161718191a1b1c1d1e1f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6162636465666768414243444142434470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7172737475767778515253545152535480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2122232423242324212122232423242223240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132333433343334313132333433343233340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4142434443444344414142434443444243440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5152535453545354515152535453545253540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002a150271502515022150211501f1501d1501c1501a1501915018150171501515014150131501215011150101500f1500e1500d1500c1500b1500a1500915009150081500715007150061500515005150
000100002b2502825026250242502325022250212501f2501d2501c2501a250192501725015250132501225011250102500f2500e2500c2500c2500a250092500825007250062500525004250032500225002250
00020000396503b6503b6503b6503b6503b6503b6503a6503965037650346502f6502b65026650206501c650196501665013650116500f6500e6500b650096500865006650066500465004650036500265001650
0002000008020054200a12006320090200952009420090200752006320091200142005120025200532009020072200c42008020063200b020065200b220022200602001320040200e3200942007420081200d220
000500000311005110041100411003110031100211002110011100111000110001100011000110001100011000110001100011000110001100011000110001100111000110001100011000110001100011000110
000200000465006650096500a6500d65012650166501c65021650286502c6502e6503365035650376503765037350376503765035650313502e65029650233501d650196501665013650116500f6500e6500d650
00010000082501135013350173501b3501d3501e3502035020350213502135020350203501f3501e350172501c350152501935011250163500e2501435012350113500f3500d3500b35009350083500325003250
0001000009050090500a0500a0500a0500a0500b0500c0500c0500d0500e0500e0500f0501105012050140501505017050190501b0501e050200502305025050280502b0502d0503005033050360503a0503c050
00020000000000e050160500000000000220500000026050000002a050000000000030050000003405000000330500000000000340500000032050000002d0500000025050000001f05000000000001705000000
01030000185511855118551185511c5511c5511c5511c551185511855118551185511c5511c5511c5511c551185511855118551185511c5511c5511c5511c5510000000000000000000000000000000000000000
