pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
wormspeed=1.5
wormlength = 0
wormseglen = flr(8 / wormspeed)
maxlength = 500*wormseglen
lastname = "..."

ranks={
	{"d.y.e.worm", "do you even worm", 0},
	{"m.wormless", "mostly wormless", 300},
	{"wormless", "wormless", 550},
	{"part worm", "part worm", 800},
	{"n.y.wormin", "now you're worming", 1200},
	{"cert.worm", "certified worm", 2000},
	{"wormtastic","wormtastic", 3000},
	{"worminator","worminator", 4000},
	{"wormlord","wormlord", 5000}
}

toplist={
	{"tic", 2000, 0},
	{"tac", 1500, 0},
	{"tod", 1250, 0},
	{"k.b", 1000, 0},
	{"ilk", 500, 0},
	{"pco", 400, 0},
	{"ate", 300, 0},
	{"o.o", 200, 0},
	{".v.", 100, 0},
	{".x.", 50, 0},
}

leveldata={
	{x=72,y=0,sx=64,sy=64,bonus=400},
	{x=88,y=0,sx=32,sy=64,bonus=500},
	{x=40,y=0,sx=64,sy=64,bonus=650},
	{x=56,y=0,sx=64,sy=64,bonus=800},
	{x=40,y=16,sx=(52-40)*8,sy=(27-16)*8,bonus=1000}
}

local data_hiscore = 0
local data_toplist = 1

local scrolltext = "                               press z or x to start worming"
local s_title = 1
local s_game = 2
local s_gameover = 3
local s_leveldone = 4
local s_newgame = 5
local s_splash = 6

gamestate = s_title

gamestates = {}

local namectab = 
	"abcdefghijklmnopqrstuvwxyz."

function ord(c)
	for i=1,#namectab do
		if sub(namectab,i,i) == c then
			return i
		end
	end
	
	return 0
end

function chr(i)
	return sub(namectab, i, i)
end

function savetoplist()
	for i=1,10 do
		local offs=(i-1)*(3+2)+data_toplist
		-- 3 letters, 2 bytes for score
		dset(offs, ord(sub(toplist[i][1],1,1)))
		dset(offs+1, ord(sub(toplist[i][1],2,2)))
		dset(offs+2, ord(sub(toplist[i][1],3,3)))
		dset(offs+3, toplist[i][2])
		dset(offs+4, toplist[i][3])
	end
end

function loadtoplist()
	for i=1,10 do
		local offs=(i-1)*(3+2)+data_toplist
		-- 3 letters, 2 bytes for score
		--print(dget(offs))
		if dget(offs) > 0 then
			local name = ""
			
			name = chr(dget(offs))..chr(dget(offs+1))..chr(dget(offs+2))
			
			toplist[i][1] = name
			toplist[i][2] = dget(offs+3)
			toplist[i][3] = dget(offs+4)
		end
	end
end

function drawtoplist()
	local x = 18
	local y = 22
	local toplistcol={
		7, 10, 9, 8, 14, 4, 2, 3, 13, 5
	}
	
	local title = "t o p   h a t s"
	
	shadtext(title,
		64-#title*4/2, 9, 10, 2)
	
	for i=1,#toplist do
		local xx = x+4
		if i >= 10 then
			xx -= 4
		end
		
		local sc = 0
		
		if i <= 3 then
			sc = 4
		end
		
		shadtext(i..".", xx, y, toplistcol[i], sc)
		shadtext(toplist[i][1], x + 16-3, y, toplistcol[i], sc)
		
		local score = ""..toplist[i][2]
				
		shadtext(score, x + 14 + 4 * 3 + 2 + 4 * 5 - #score*4, y, toplistcol[i], sc)
		shadtext(getrank(toplist[i][2],true), x + 14 + 4 * 3 + 2 + 4 * 5 + 4, y, 6, sc)
		y+=6
		
		if i == 3 then
			y += 2
		end	
	end
end

function addtopscore(name,score)
	local temp = {}
	local c = 0
	local added = false
	for s in all(toplist) do
		if not added and score > s[2] then
			add(temp,{name,score})
			added = true
			c += 1
		end
		
		if c >= 10 then
			break
		end
		add(temp,s)
		c+=1
	end
	toplist = temp
end

function getrank(score,short)
	local br = ranks[1]
	for r in all(ranks) do
		if r[3] <= score then
			br = r
		end
	end
	
	if short then
		return br[1]
	else
		return br[2]
	end
end

function changestate(state)
	gamestate = state
	
	if gamestates[state].init != nil then
		gamestates[state].init()
	end
end

function doparticles()
	for p in all(particles) do
		p.ttl -= 1
		
		if p.ttl <= 0 then
			del(particles,p)
		end
		
		p.x += p.dx
		p.y += p.dy
		p.z += p.dz
		
		if p.z < 0 then
			p.z = 0
			p.dz *= -0.7
			if abs(p.dz) <= 0.75 then
				p.dz = 0
			end
		else
			p.dz -= 0.3
		end
		
	end
end

function addparticle(t,x,y,z,dx,dy,dz,ttl)
	if not ttl then
	 ttl = rnd()*200+50
	end
	add(particles,{t=t,x=x,y=y,z=z,dx=dx,dy=dy,dz=dz,ttl=ttl})
end

function drawparticles()
	for p in all(particles) do
		zspr(p.t,p.x,p.y,p.z)
	end
end

function _init()
	cartdata("i_k_wormnomnom")
	highscore = dget(data_hiscore)
	loadtoplist()
	changestate(s_splash)
	--toplist[1][1]="abc"
	--savetoplist()
end

function inittitle()
	scrollx = 0	
	frame=0
	music(0)
	dset(data_hiscore,highscore)
	savetoplist()	
end

function initgameover()
	startdelay=30*2
	newtopscore = false
	topscoreletter = 1
	topscorename = lastname	

	for t in all(toplist) do
		if t[2] < points then 
			newtopscore = true
			break
		end
	end
	
	--addtopscore("yay", points)
end


function setstart()
	wormspeed=1.5
	levelcompdelay = 0
	showextend = 0
	playtime=0
	fruitnotify=0
	head={x=leveldata[level].sx-4,
		y=leveldata[level].sy,
		d=0.25,z=256,poop=0}
	worm={}
	for i=0,maxlength do
		add(worm,{x=head.x,y=head.y-8,d=0,z=64,poop=0})
	end
	
	local hat = nil
	
	if not hashat then
		for f in all(fruits) do
			if f.s == 3 then
				hat = f
				break
			end
		end
		if hat != nil then
			fruits={hat}
		end
	else
		fruits={}
	end
	
	
	poop={}
	flowers={}
	killed=false
	startdelay=30*3
	wormidx=1
	
	if neededfruit <= fruitseat then
		changestate(s_leveldone)
	else
		addfruit()
	end
end

function initlevel()
	hashat = true
	addedextend = false
	fruitnotify=0
	fruitseat = 0
	levelbonus = leveldata[level].bonus
	leveloffx=leveldata[level].x
	leveloffy=leveldata[level].y
	scoremultiplier=1
	startdelay = 3 * 30
	killed=false
	particles={}
	startdelay=30*3
	fruits={}
	poop={}
	flowers={}

	setstart()
	
	wormidx=1
	wormlength = 0

	growworm(1)

end

function resetextend()
	extendsprites={
		82,83,84,82,85,86
	}
	extendletters={
		false,false,false,false,false,false
	}
end

function updateextend(l)
	for i=1,6 do
		if l == extendsprites[i] and
			not extendletters[i] then
			extendletters[i] = true
			showextend = 30*1.5
			break
		end
	end
	
	local complete = true
	
	for i=1,6 do
		if not extendletters[i] then 
			complete = false
			break
		end
	end
	
	if complete then
		lives += 1
		resetextend()
		extralifecounter=30*2
	end
end

function initgame()
	extralifecounter=0
	totflowers = 0
	lavactr=0
	jump=0
	tries=0
	appear=0
		
	leveloffx=leveldata[level].x
	leveloffy=leveldata[level].y
	scoremultiplier=1
	
	initlevel()	
	
end

function initnewgame()
	music(-1, 1000)
	
	resetextend()
	lives = 3
	points = 0 
	level = 1
	visuallevel = 1
	neededfruit=12
	
	gameframes = 0
	
	timeline={}

	changestate(s_game)
end

function addfruit(extend)

	if not extend then
		local st = {4,7,8}
		s=st[flr(rnd()*#st)+1]
	else
		while true do
			local i = flr(rnd()*6)+1
			if not extendletters[i] then
				s = extendsprites[i]
				break
			end
		end
	end
	
	local x
	local y
	
	while true do
	 x =  rnd()*112+4
	 y = rnd()*112+4
		
		local tryagain = false
		
		for p in all(poop) do
			if (abs(p.x - x) < 7 and
				abs(p.y - y) < 7)
				 then
				tryagain=true
				break
			end
		end
		
		if (abs(head.x - x) < 16 and
				abs(head.y - y) < 16) then
				tryagain = true
		end
		
		if fget(mget(leveloffx+(x+4)/8,leveloffy+(y+4)/8),0) then
			tryagain = true
		end
		
		if not tryagain then
			break
		end
	end
	
	local ttl = nil
	local dz = 1
	
	if extend then 
		ttl = 30*5
		dz = 2
	end
	
	add(fruits,{x=x,y=y,z=128,dz=dz,s=s,ttl=ttl})
end

function growworm(l)
	wormlength += wormseglen*l
	
	
	if wormlength > maxlength then
		wormlength = maxlength
	end
end


function updatetitle()
	if btnp(4) or btnp(5) then
		changestate(s_newgame)
	end
	
	scrollx += 1
	frame += 1
	
	if scrollx/4 > #scrolltext then
		scrollx= 0 
	end
end

function scroll(dx,dy)
	for f in all(fruits) do
		f.x += dx
		f.y += dy
	end
	
	for f in all(poop) do
		f.x += dx
		f.y += dy
	end
	
	for b in all(worm) do
		b.x += dx
		b.y += dy
	end
	
	head.x += dx
	head.y += dy
end

function zspr(s,x,y,z,_fx,_flash)
	local fx = _fx or false
	local flash = _flash or false
	add(drawq,{s,x,y,z,fx,flash})
	--spr(s,x,y-z,1,1,fx)
end

function nextlevel()
	level += 1
	visuallevel += 1
	neededfruit += 6
	if level > #leveldata then
		level = 1
		neededfruit -= 10
	end
	initlevel()
end


function drawtimeline()
	color(7)
	local y = 0
	local x = 0
	for t in all(timeline) do
		line(t[1]*127/gameframes,127-t[2]/10,
			x,127-y)
		y=t[2]/10
		x = t[1]*127/gameframes
	end
end

function updatefruit()
	for f in all(fruits) do
		if f.ttl != nil then
			f.ttl -= 1
			if f.ttl <= 0 then
				del(fruits,f)
			end
		end
	
		f.z += f.dz
			
		if f.z < 0.7 then 
 		f.z = 0
			f.dz *= -0.3
			if abs(f.dz) > 0.1 then
			sfx(17)
			end
		end
			
		if f.z > 0.7 then
			f.dz -= 0.4
		end
	end
end

function updategame()
	if levelcompdelay > 0 then
		wormspeed *= 0.95
		levelcompdelay -= 1
		if levelcompdelay <= 0 then
			changestate(s_leveldone)
			return
		end
	end

	if showextend > 0 then
		showextend -= 1
	end
	
	if extralifecounter > 0 then
		extralifecounter -= 1
	end
	
	if appear < 128 then
		appear += 1+appear/4
	end
	--scroll(0,0)
	
	if fruitnotify > 30*10 then
		fruitnotify=0
	else
		fruitnotify += 1
	end
	
	if startdelay <= 0 and levelbonus > 0 then
		levelbonus -= 0.2
		if levelbonus < 0 then
			levelbonus = 0
		end
	end
	
	if startdelay > 0 then
		startdelay -= 1
		if startdelay <= 0 then
			music(16, 0, 1+2)
		end
	else
		gameframes+=1/30
	end
	
	scoremultiplier = 1.0 + #flowers / 5

	doparticles()
	dolava()
		
	if not killed then
	
	if startdelay <= 0 then
	head.x += cos(head.d)*wormspeed
	head.y += -sin(head.d)*wormspeed
	end
	
	head.z += jump
	
	if playtime > 30 then
	if head.z < 3 and checkselfcollision() then
		killworm(true)
		return
	end
	end
	
	if startdelay <= 0 then
	playtime += 1
	end
	
	
	if head.z < 2 then
		if fget(mget(leveloffx+(head.x+4)/8,leveloffy+(head.y+4)/8),0) then
			if lavactr > 2 then 
				for i=0,3 do
					addparticle(94,head.x,head.y,0,rnd()*2-1,rnd()*1.5-0.75,rnd()*1.5+0.75,rnd()*20+10)
				end
				killworm()
		
				return
			else
				lavactr+=1
			end
		else
			lavactr=0
		end
	end
	
	updatefruit()
	
	if head.z <= 0 then
		head.z = 0
		jump *= -0.25
		--addparticle(head.x,head.y,0,rnd()*2-1,rnd()*2-1,3)
		if abs(jump) < 0.3 then
			jump = 0
		else
			sfx(1)
		end
		
		for f in all(flowers) do
			if abs(f.x-head.x) < 6 and
				abs(f.y-head.y) < 6 then
				del(flowers,f)
				sfx(14)
				for i=0,3 do
					addparticle(67,f.x,f.y,0,rnd()-0.5,rnd()-0.5,rnd()+1,rnd()*10+10)
				end
			end
		end
		
		local addfruitb = false
		
		for f in all(fruits) do
			if f.z < 4 and abs(f.x-head.x) < 8 and
					abs(f.y-head.y) < 8 then
					del(fruits,f)
					sfx(14)
					updateextend(f.s)
					
					if f.s == 3 then
						hashat = true
						addpoints(-flr(-(20 * scoremultiplier)), true)
					else
						for i=0,3 do
							addparticle(67,f.x,f.y,0,rnd()-0.5,rnd()-0.5,rnd()+1,rnd()*10+10)
						end
										
						if f.s < 82 or f.s > 86 then
							addpoints(-flr(-(10 * scoremultiplier)), true)
							addfruitb = true
							fruitseat += 1
							growworm(1)
						
							if fruitseat >= neededfruit then
								levelcompdelay=30
								music(-1, 1000)
							end
						end
					
					end
			end
		end
		
		if addfruitb and fruitseat < neededfruit then
			fruitnotify=0
			addfruit()
			add(poop,{rock=false,x=head.x,y=head.y,hide=wormlength+4,frame=0})
			head.poop = wormseglen
			
			if not addedextend and rnd() < 0.15 then
				addfruit(true)
				addedextend = true
			end
		end
	else
		jump -= 0.27
	end
	
	for p in all(poop) do
		if p.hide <= 0 then
			if head.z < 3 and abs(p.x - head.x) < 3 and
				abs(p.y - head.y) < 3 then
				for i=0,5 do
					addparticle(68,p.x,p.y,0,rnd()*2-1,rnd()*2-1,rnd()*2,30)
				end
				sfx(2)
				killworm(true)
				return
			end
			if not p.rock then
				p.frame += 0.020
				if p.frame >= 4 then
					del(poop,p)
					add(flowers,{t=flr(rnd()*3),x=p.x, y=p.y})
					totflowers += 1
					if #flowers > 6 and totflowers % 10 == 0 then
						addedextend = false
					end
					sfx(12)
				end
			end
		else
			p.hide -= 1
			if p.hide == 0 then
				for i=0,2 do
					addparticle(68,p.x,p.y,0,rnd()*2-1,rnd()*2-1,rnd()*0.5+1.75,20+rnd()*10)
				end
				sfx(2)
			end
		end
	end
	
	if head.poop > 0 then
		head.poop -= 1
	end
	
	if head.z < 2 then	
	-- makes jumping help
	-- turning when on the edge
	-- of screen -> more fun
	
	if head.x > 126 or head.x < -6 or
		head.y > 126 or head.y < -6 then
		killworm()
		return
	end		
	end
			
	--if btnp(5) then
	--	growworm(1)
	--end
	
	if startdelay <= 0 then	
		if btn(0) or btn(2) then
			head.d -= 0.02
		elseif btn(1) or btn(3) then
			head.d += 0.02
		end
		
		if (btnp(4) or btnp(5)) and head.z <= 2 then
			jump = 3
			sfx(0)
		end
	end
	
	while head.d < 0 do
		head.d += 1
	end
	
	worm[wormidx].x = head.x
	worm[wormidx].y = head.y
	worm[wormidx].z = head.z
	worm[wormidx].d = head.d
	worm[wormidx].poop = head.poop

	wormidx += 1
	if wormidx > #worm then
	 wormidx = 1
	end
		
	end
end

function checkselfcollision()
	local i = wormidx-wormlength-1
	local l = 0
	local wl = #worm
	
	while i < 1 do
		i += wl
	end	
		
	for b in all(worm) do
		if l > 2 then
			if worm[i].z < 4 and abs(worm[i].x-head.x)<3 and
				abs(worm[i].y-head.y)<3
			then
				return true
			end
		end
		
		i += 4
		if i > wl then
			i -= wl
		end
		
		l += 4
		
		if l > wormlength - 16 then
			break
		end
	end
	
	return false
end

function drawtitle()
	camera()
	cls()
	
	palt()
	local yo = 0
	local xo = 0
	local t = frame/100
	for y=0,127 do
		for x=0,127,16 do
		local zo = cos(y/512+x/1024+t*0.1)
		local yo = cos(y/1024+x/512+t*0.25+zo*0.5)*zo*16+16
		local xo = (sin(y/256+x/256+t)*yo+32)%32
		clip(x,y,16,1)
		map(16,y/8,xo-32,y-y%8,24,1)
		end
	end
	clip()
	palt(0,false)
	palt(15,true)
	
	if frame % (10 * 30) < 5 * 30 then
		map(0,0,0,8,16,16)
	else
		map(0,16,0,8,16,16)
		drawtoplist()

	end
	
	--clip(34,89,60,8)
	local offs = flr(scrollx/4)
	local subtext = sub(scrolltext,offs,offs+32)

	-- normal colored center
	clip(10+4,89,100,6)
	color(1)
	print(subtext,6-scrollx%4,90)
	color(10)
	print(subtext,6-scrollx%4,89)
	
	-- dim colored edges
	local ctab = {{2,9},{1,15}}
	local x = 0
	for c in all(ctab) do
	clip(10+x,89,4,6)
	color(c[1])
	print(subtext,6-scrollx%4,90)
	color(c[2])
	print(subtext,6-scrollx%4,89)
	clip(18+100-4-x,89,4,6)
	color(c[1])
	print(subtext,6-scrollx%4,90)
	color(c[2])
	print(subtext,6-scrollx%4,89)
	x+=4
	end
	clip()
	
	--[[if highscore > 0 then
		local text="high score: "..highscore
		shadtext(text,64-((#text)*4/2),98,10,2)
	
		text="("..getrank(highscore,false)..")"
		shadtext(text,64-((#text)*4/2),98+6,9,2)
	end--]]
	
	shadtext("ilkkke", 18, 114,7,0)
	shadtext("kometbomb", 82, 114,7,0)
end

function shadtext(text,x,y,tc,sc)
	color(sc)
	print(text,x,y+1)
	color(tc)
	print(text,x,y)
end

function drawgame()
	cls()
	if gamestate == s_game then
		camera()
		if tries == 0 then
			clip(64-appear/2,64-appear/2,appear,appear)
		else
			clip()
		end
	end
	
	--color(5)
	--rectfill(0,0,127,127)
	palt()
	map(leveloffx,leveloffy,0,0,16,16)

	drawq={}
	
	local fruitflash = fruitnotify > 8*30 and fruitnotify % 2 == 0
	local fruitarrow = fruitnotify > 8*30 
	
	for f in all(fruits) do
		if f.ttl != nil and f.ttl < 30*1.5 and f.ttl % 2 == 0 then
			zspr(f.s,f.x,f.y,f.z,false,true)
		else
			zspr(f.s,f.x,f.y,f.z,false,fruitflash)
		end
		
		if fruitarrow then
			zspr(98,f.x,f.y,f.z+cos(fruitnotify/15)*2+9,false)
		end
	end
	
	for f in all(flowers) do
		local fspr = {65,80,81}
		zspr(fspr[f.t+1],f.x,f.y,0)
	end
	
	for p in all(poop) do
		if not p.rock then
			if p.hide <= 0 then
				zspr(56+flr(p.frame),p.x,p.y,0)
			end
		else
			zspr(66,p.x,p.y,0)
		end
	end
		
	drawparticles()
	
	if not killed then

	local i = wormidx-wormlength-1
	local l = 0
	local wl = #worm
	
	while i < 1 do
		i += wl
	end
	
	
		
	for b in all(worm) do
			if l == wormlength then
				local rt = {
					{12,false},
					{13,false},
					{14,false},
					{13,true},
					{12,true},
					{11,true},
					{10,false},
					{11,false}
				}
				
				local r = rt[1 + flr(8*worm[flr(wormidx-1-1+wl)%wl+1].d+(1/8))%8]
			
				--print(worm[i].d)
				--stop()
				
				local z = worm[(i-2-1)%wl+1].z
				
				if jump > 0 then
					z = worm[i].z
				end
				
				zspr(r[1],worm[i].x,worm[i].y,worm[i].z,r[2])
				if hashat then
					zspr(3,worm[i].x,1+worm[i].y,z+5)
				end
			else
				if worm[i].poop > 0 then
				zspr(9,worm[i].x,worm[i].y,worm[i].z)
				else
				zspr(1,worm[i].x,worm[i].y,worm[i].z)
				end
			end
		
		i += wormseglen
		if i > wl then
			i -= wl
		end
		
		l += wormseglen
		
		if l > wormlength then
			break
		end
	end
	
	end

	sort(drawq)
	
	palt()
	palt(0,false)
	palt(5,true)
	
	for s in all(drawq) do
		if s[1] != 3 and s[1] != 68 and s[1] != 5 and s[1] !=67 and s[1] !=94 then
			local i = flr(s[4] / 32)
			if i < 4 then
				spr(60+3-i,s[2],s[3])
			end
		end
	end
	
	for s in all(drawq) do
		if s[6] then
			for i=1,15 do
				if i != 5 and i != 1 then pal(i,7)
				end
			end
		else
			pal()
			palt()
			palt(0,false)
			palt(5,true)
		end
		spr(s[1],s[2],s[3]-s[4],1,1,s[5])
	end
	pal()
	palt(0,false)
	palt(5,true)
	
	clip()

	if startdelay > 0 and startdelay < 30*2 and gamestate == s_game then
  rectfill(44-4,48,44+45-4,48+8,0)
  spr(96,40-4,46)
  spr(97,86-4,46)
  local text
  if tries == 0 and startdelay > 30*1 then
  text = "level "..visuallevel
  else
  
  text = "get ready!"
  end
		shadtext(text, 64-((#text)*4/2), 50, 10, 0)
	end
	
	--shadtext(-flr(-levelbonus),64-48,0,7,0)

	local mult = scoremultiplier*10

	spr(99,64+40-8+2,0)
	shadtext(neededfruit-fruitseat,64+40+1,1,7,0)
	
	local pointstxt = (""..points)
	
	--shadtext(levelbonus,64-32,1,10,0)
	shadtext(points,64-(#pointstxt*4/2),1,10,0)
	
	spr(100,0,0,2,1)
	shadtext(flr(mult/10).."."..(mult%10),16,1,7,0)
	
	spr(95,116,0)
	shadtext(lives,124,1,7,0)
		
	if showextend > 0 or extralifecounter > 0 then
		for i=1,6 do
			if extendletters[i] or (extralifecounter > 0 and extralifecounter % 4 < 2) then
				spr(extendsprites[i],i*12+64-(6*12/2)-8,119)
			else
				spr(102,i*12+64-(6*12/2)-8,119)
			end
		end
	end
end

function killworm(throwhat) 
	music(-1, 100)
	sfx(13)
	tries += 1
	killed = true
	
	local i = wormidx-wormlength-1
	local l = 0
	local wl = #worm
	
	while i < 1 do
		i += wl
	end
	
	for b in all(worm) do
			for c=0,3 do
			addparticle(5, worm[i].x+rnd()*4-2,worm[i].y+rnd()*4-2,0,rnd()*2-1,rnd()*2-1,rnd()*4,60+rnd()*30)
			end
		
		i += wormseglen
		if i > wl then
			i -= wl
		end
		
		l += wormseglen
		
		if l > wormlength then
			break
		end
	end
	
	--addparticle(3,head.x,head.y,4,0,0,4,1000)
	
	local hat = {s=3,x=head.x,y=head.y,z=4,dx=0,dy=0,dz=4}
	
	if lives == 1 then
		lives = 0
		changestate(s_gameover)
	else
		lives -= 1
		setstart()
	end
	
	if throwhat and hashat then
		add(fruits,hat)
		hashat = false
	end
end

function ribbon(x,y,w,h)
	rectfill(x-4,y,x+w+3,y+h,0)
	spr(96,x-4-4,y-2)
	spr(97,x+w,y-2)
	 
end

function drawgameover()
	camera()
	drawgame()
	if startdelay < 1*30 then
		rectfill(44-4,48+8-16,44+45-4,48+8+8-16,0)
	 spr(96,40-4,46+8-16)
	 spr(97,86-4,46+8-16)
		shadtext("game over", 46, 50+8-16, 10, 0)
		
		local text = getrank(points,false)
		local w = #text*4 + 4
		
		shadtext("rank:", 64-5*4/2+2,48+8,7,0)
		
		rectfill(64-w/2,48+8+24-16,64+w/2,48+8+8+24-16,0)
	 spr(96,64-w/2-4,46+8+24-16)
	 spr(97,64+w/2-3,46+8+24-16)
	 
		shadtext(text, 64-w/2+3, 50+8+24-16, 10, 0)

	end
	
	if startdelay < 1*30 then
		if newtopscore then
			local text = "enter your initials:"
		
			ribbon(64-#text*4/2-8,112,#text*4+16,8)
		
			shadtext(text, 64-(#text+3)*4/2, 112+2, 9, 0)
			shadtext(topscorename, 64+(#text+3)*4/2-3*4, 112+2, 12, 0)
			spr(124,64+(#text+3)*4/2-4*4+topscoreletter*4-2,112-8)
			spr(125,64+(#text+3)*4/2-4*4+topscoreletter*4-2,112+8)
		else
			local text = "press z to continue"
		
			shadtext(text, 64-(#text)*4/2, 112, 7, 1)
		end
	end
	
	--drawtimeline()
end

function dolava()
	local x = flr(rnd()*16)
	local y = flr(rnd()*16)
	
	if rnd() > 0.15 then
		return
	end
	
	if fget(mget(x+leveloffx,leveloffy+y),1) then
		for i=0,3 do
			addparticle(94,x*8+4,y*8+4,0,rnd()*1-0.5,rnd()*1-0.5,1.5+rnd()*2,25+rnd()*15)
		end
	end
end

function initleveldone()
	origdonepoints = flr(levelbonus)
	donepoints = flr(levelbonus * scoremultiplier)
	addtimelinepoints(donepoints)
 pause=30*1.5
 donetimer = 0
 donescroll=0
end

function drawleveldone()
	camera(0,donescroll)
	--pal(5,7)
	drawgame()
	clip()
	
	--rectfill(0,0,127,4,7)
	--rectfill(0,106,127,127,7)
	--rectfill(0,0,4,127,7)
	--rectfill(123,0,127,127,7)
	
	rectfill(44-4,48,44+45-4,48+8,0)
 spr(96,40-4,46)
 spr(97,86-4,46)
	shadtext("right on!", 46, 50, 10, 0)

	rectfill(44-36-3,48+16,44+45+36-4,48+8+16,0)

	spr(96,40-36-3,46+16)
 spr(97,86+36-4,46+16)
 local text = "time bonus "..origdonepoints.." x "..scoremultiplier..
 	" = "..flr(scoremultiplier*origdonepoints)
	shadtext(text, 64-(#text*4/2), 50+16, 10, 0)
end

function addtimelinepoints(p)
	add(timeline,{gameframes,-flr(-(points+p))})
end

function addpoints(p,addtimeline)
	points = -flr(-(points+p))
	if addtimeline then
		addtimelinepoints(p)
	end
	highscore = max(highscore,points)
end

function updateleveldone()
	if pause > 0 then
		pause -= 1
		return
	end
	
	local ps = 5
	
	if btn(4) or btn(5) then
		ps = donepoints
	end
	
	if flr(donepoints) > 0 then
		addpoints(-flr(-(min(ps,donepoints))), false)

		donepoints -= ps
		
		sfx(16)
	else 
		donetimer += 1
		if donetimer > 30 then
			donescroll += donescroll/4+1
		end
		if donetimer > 30*2 then
			nextlevel()
			
			changestate(s_game)
		end
	end
end

function updategameover()
	doparticles()
	dolava()
	
	updatefruit()
	
	if startdelay > 0 then
		startdelay -= 1
	end
	
	if startdelay < 1*30 and not newtopscore then
		if startdelay <= 0 and (btnp(4) or btnp(5)) then
			changestate(s_title)
		end
	else
		if btnp(2) or btnp(3) then
			local tt = {}
			
			for i=1,3 do
				tt[i] = ord(sub(topscorename, i, i))
			end
			
			local d = 1
			
			if btnp(2) then
				d = -1
			end
						
			tt[topscoreletter] = 
				((tt[topscoreletter] - 1 + d + #namectab) % #namectab) + 1
			
			topscorename = chr(tt[1])..chr(tt[2])..chr(tt[3])
			
			sfx(14)
				
		elseif btnp(5) then
			if topscoreletter > 1 then
				topscoreletter -= 1
				
				topscorename = sub(sub(topscorename, 1, topscoreletter).."...", 1, 3)
			end
			sfx(2)
		elseif btnp(4) then
			topscoreletter += 1
			if topscoreletter > 3 then
				addtopscore(topscorename, points)
				
				newtopscore = false
				startdelay = 1
				
				lastname = topscorename
				
				sfx(1)
			else
				sfx(17)
			end
		end
	end
end

function _update()
	gamestates[gamestate].update()
end

function _draw()
	gamestates[gamestate].draw()
end

function sort(a)
  for i=1,#a do
    local j = i
    while j > 1 and 
   		(a[j-1][3] > a[j][3]) do
      a[j],a[j-1] = a[j-1],a[j]
      j = j - 1
    end
  end
end


function updatesplash()
	splashdelay -= 1
	
	if splashdelay <= 0 then
		changestate(s_title)
	end
end

function initsplash()
	splashdelay = 30*2.5
end

function drawsplash()
	cls()
	pal()
	map(104,0,64-7*8/2,64-6*8/2,11,5)
end



gamestates[s_title]={x=1,draw=drawtitle,update=updatetitle,init=inittitle}
gamestates[s_game]={draw=drawgame,update=updategame,init=initgame}
gamestates[s_gameover]={draw=drawgameover,update=updategameover,init=initgameover}
gamestates[s_newgame]={draw=drawgame,update=nil,init=initnewgame}
gamestates[s_leveldone]={draw=drawleveldone,update=updateleveldone,init=initleveldone}
gamestates[s_splash]={draw=drawsplash,update=updatesplash,init=initsplash}

__gfx__
555555555ccccc55555555555511115555a555555555555555555555555425555555555557777755588888855888885558880055588888555888888555555555
55555555cc77ccc5555555555511115555bb555555555555555555555ba2bab5559aaa9577777775888998888899880588899885889988058889988855555555
55555555cc77ccc5555555555512115555b3b555555cc55555555555baaaaaab59aaaa9477777775888998888899880588899885889988058889988855555555
55555555ccccccc5555555555001000555b5388555c7cc5555dd5555baaaaabb59aaaa9177777775888888888888888588888885888888858888888855555555
555555553ccccc35553b55550101001058858f8855cccc5555d62555bbbbbbbb99aaa99167777765888888888888888588880085880088858008800855555555
555555553333333555332325020100108f8888e85553355555555555bbbbbbbba999994166666665888888888888888588880085880088858008800855555555
55555555533333555555555501d2211088e8188155511555555555553bbbbbb39999941556666655588888855888885558888855588888555888888555555555
5555555555555555555555555000000518811115555555555555555513bbbb315111115555555555555555555555555555555555555555555555555555555555
fbbbbbbfff3bb3ffff3bbbbbbbbbb3ffbbbbb3ff112dd21111222211ffffffff00111100888888888888888880000008f88888888888888fffff28888882ffff
fbbbbbbff3baab3ff3aabbbbbbbbaa3fbbbbaa3f1122221111222211ffffffff00111100889999888888888882000008f88000888800088ffff8888888888fff
fbbbbbbffbbaabbffbaabbbbbbbbaabfbbbbaabf1122221111222211ffffffff00000000899999988888888888200288f800c008800c008fff888888888888ff
fbbbbbbffbbbbbbffbbbbbbbbbbbbbbfbbbbbbbf112222111122221111111111222dd222899999988888888888899888f80000088000008ff28888888888882f
fbbbbbbffbbbbbbffbbbbbbbbbbbbbbfbbbbbbbf11222211112222111111111122222222889999888888888888888888f80020088002008ff88888888888888f
fbbbbbbffbbbbbbffbbbbbbbbbbbbbbfbbbbbb3f11222211112222111111111122222222888888888888888888888888f82000288200028ff88888888888888f
fbbbbbbffbbbbbbffbbbbbbbbbbbbbbfbbbbb30f11222211112222110000000000000000888888888888888888888888f88222888822288ff88888888888888f
fbbbbbbffbbbbbbffbbbbbb33bbbbbbfffffffff1122221111222211ffffffffffffffff888888888888888888888888f88888888888888ff88888888888888f
fbbbbbbffbbbbbbffbbbbbb33bbbbbbf124d4dddddddddddddd4d421fffffff022222222222222220fffffffffffff000ffffff000fffffff88888888888888f
bbbbbbbbfbbbbbbffbbbbbbbbbbbbbbf224444444444444444444422ff2111110221000000001220111112fffffff02210f00f01220ffffff88888888888888f
bbbbbbbbfbbbbbbffbbbbbbbbbbbbbbf224444444444444444444422ff0211111022111001112201111120fffffff02211022011220ffffff88888888888888f
bbbbbbbbfbbbbbbffbbbbbbbbbbbbbbf224444444444444444444422fff02111110221100112201111120ffffffff01111011011110ffffff88888888888888f
bbbbbbbbfbbbbbbffbbbbbbbbbbbbbbf224444444444444444444422ffff011111102210012201111110fffffffff01110f00f01110ffffff28888888888882f
bbbbbbbbfbbaabbffbaabbbbbbbbaabf224444444444444444444422ffff111111110220022011111111ffffffffff000ffffff000ffffffff888888888888ff
bbbbbbbbf3baab3ff3aabbbbbbbbaa3f224444444444444444444422fff11111111112200221111111111ffffffffffffffffffffffffffffff8888888888fff
bbbbbbbbff3bb3ffff3bbbbbbbbbb3ff244d4dddddddddddddd4d442ff2222222222221001222222222222ffffffffffffffffffffffffffffff28888882ffff
bbbbbbbbfffffffffffffffffccccffffffccfff2222222200000000101010105552225555522255555555555555555555555555555555555555555555555555
bbbbbbbbffc77fffc7f77f7cfccccffffffccfff0000000000000000000000005524925555249255552223355b3553bb55555555555555555555555555555555
bbbbbbbbfc7ccfff7cfccfc7f00ccffffffccfffffffffff000000001010101052494255524943555249b3555532b35555555555555555555555555555555555
bbbbbbbbfccccfffccfccfccfffccffffffccfffffffffff00000000000000005244442552444425524433255333332555555555555555555555555555555555
bbbbbbbbfccccfffccccccccfffccffffffccfffffffffff000000001010101022444212224442122233421233bb321255555555555555555511155551111155
bbbbbbbbfccccfffccccccccfffccffffffccfffffffffff0000000000000000249944422433444223b3344233bb344255555555551111555111115511111115
bbbbbbbbfccccfffccccccccfffccffffffccfffffffffff0000000010101010244444422433443223333433233334b355111555511115555111115511111115
fbbbbbbffccccfff2cccccc2fff00ffffff00fffffffffff00000000000000005222221552222215522222135222223355555555555555555511155551111155
555555558fe58fe855d666555555555555555555ffffffff55cccccccd555dcccccccc55d0e888888888888888888e0dd0e888888888888888888e0d55555555
55555555eee8eee85d6667d55555555555555555c2ffdccf565022222dcccd2222220565d2e888888888888888888e2dd0e888888888888888888e0d55555555
555555558ee288816666dd555555555555522555ccdfccccd5020222225222122220205d5d2e8888888888888888e2d5d0e888888888888888888e0d55555555
55225255188aa8ee766d66515557755555294255dccccccfd0002222225222122222000d5d0e8888888888888888e0d5d0e888888888888888888e0d55555555
52222525efe288eed77d67d15557755555249255fcccccdfd002eeeee85228eeeeee200d5d0e8888888888888888e0d5d2e888888888888888888e2d55d25555
55555555eee8fe88ddddddd15551155555511555f2cccc1fd02e88888eeeee888888e20d5d0e8888888888888888e0d5d2e888888888888888888e2d55555555
555555558e88eee15dd5dd515555555555555555ccccc2ffd0e888888888888888888e0dd22e8888888888888888e22d5d8e888888dddd888888e8d555555555
555555555111221515d5d5155555555555555555fdcd1fffd0e888888888888888888e0dd0e888888888888888888e0d55dddddddd5555dddddddd5555555555
5fc55fc597a597a95777775557777755577777555777775557777755888888888888888888888e0550e888888888888888888888888888885555555558858855
ccc5ccc5aaa9aaa97ccccc757cc7cc757ccccc757cc77c757cccc775888888888888888888888e0550e888888888888888888888888888885555555589888885
5cc155519aa889917cc777757cc7cc7577ccc7757ccc7c757cc77c75888888888888888888888e2552e888888888888888888888888ee8885558855588888885
155995cc198998aa7cccc77577ccc77577ccc7757cc7cc757cc77c75888888888888888888888e8558e8888888888888888ee88888e88e88558a885588888885
cfc155cca79289aa61177765611711656611166561177165611771658888888888888888888888eeee888888888ee88888e88e8888e88e885588e85508888805
ccc5fc55aaa97a9961111165611611656611166561166165611116658888888888888888888888888888888888888888888ee888888ee8885558855550888055
5c55ccc19a99aaa15666665556666655566666555666665556666655888888888888888888888888888888888888888888888888888888885555555555000555
51112215511122155555555555555555555555555555555555555555888888d22d88888888888888888888888888888888888888888888885555555555555555
5000000000000005557777555555555555555555555555555777775500000eaaaaaaae0000eaaaaaaae000000000aaa44444aaa00aa44aaa44aa0000bbbbbbbb
500001000010000555722755555ba5555ee5ee5555555555755555750000eaaaaaaaaae00eaaaaaaaaae00000000eaaaaaaaaae00eaaaaaaaaae0000bbbbbbbb
50001000000100055578875555b0b5555e989e5555757555755555750000aaa44444aaa00aa44aaa44aa000000000eaaaaaaae0000eaaaaaaae00000bbbbbbbb
50010000000010055788887558e5b555508a805555070555755555750000aa4444444aa00aa444a444aa00000005cbbbbbbbbbbbbbbbbbbbbbbc5000bbbbbbbb
50010000000010055078870558858e555ef8fe5555707555655555650000aa44aaa44aa00aaa44444aaa000000cbbbbbbbbbbbbbbbbbbbbbbbbbbc00bbbbbbbb
500100000000100555077055500588555ee0ee5555050555655555650000aa44aaa44aa00aaaa444aaaa00000cbbbbbbbbbbbbbbbbbbbbbbbbbbbbc0bbbbbbbb
500100000000100555500555555500555005005555555555566666550000aa44aaa44aa00aaa44444aaa00005bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5bbbbbbbb
500100000000100555555555555555555555555555555555555555550000aa4444444aa00aa444a444aa0000cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcbbbbbbbb
bbbbbbbbcbbbbbbbbbbbbbbbbbbbbbbc000000000000000000000000000000000000000000000000000000000000000055555555555555550000000000000000
555555555bbbbbbbbbbbbbbbbbbbbbb5000000000000000000000000000000000000000000000000000000000000000055555555555555550000000000000000
bbbbbbbb0cbbbbbbbbbbbbbbbbbbbbc00000000000000000000000000000000000000000000000000000000000000000555555555eeeee550000000000000000
bbbbbbbb00cbbbbbbbbbbbbbbbbbbc000888880888808888800088888088888088888000888880888880888880888820555e5555508880550000000000000000
bbbbbbbb0005cbbbbbbbbbbbbbbc5000088888088880888880008888808888808888800088888088888088888088888055e8e555550805550000000000000000
bbbbbbbb00000000000000000000000008888800000088800000888880880880888000008888808808808808808808805e888e55555055550000000000000000
bbbbbbbb000000000000000000000000008880088880888880000888008888808888800008880088888088888088888050000055555555550000000000000000
bbbbbbbb000000000000000000000000008880088880888880000888008808808888800008880088888088088088888055555555555555550000000000000000
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
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101030101010100000000000000000101030103030300000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000015000000000000003636373736363737363637373636373736363737363637370f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f574d4d4d585d4a4b4f400f0f0f0f0f490f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f494b0f0f0f0f0f0f00006768696a000000000000000000000000000000000000
000000000000000016000000000000003636373736363737363637373636373736363737363637370f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4b0f0f0f4c585b4b0f0f0f0f0f0f4f490f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f465a4b0f0f0f0f0f0f00006b6c6d6e000000000000000000000000000000000000
000000000000001718170000000000003737363637373636373736363737363637373636373736360f0f0f0f0f0f0f0f060f0f0f46480f0f4e0f060f0f4c584b0f0f0f0f0f060f490f0f0f0f0f0f060f0f0f0f0f400f0f0f0f0f0f0f0f0f0f49574e0f0f400f0f0f00006f70706f000000000000000000000000000000000000
003132000000001e191f0000000000003737363637373636373736363737363637373636373736360f0f020f0f0f0f0f0f0f0f465a4b0f0f0f0f0f0f0f0f494b0f4f0f0f0f0f465a0f0f0f46480f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f494b0f0f0f0f0f0f0f000071727273000000000000000000000000000000000000
003334001111111c1a1d1214123013003636373736363737363637373636373736363737363637370f0f0f020f0f0f0f0f0f0f495b4b0f0f0f0f0f0f0f0f49594747474747475a5c0f0f0f4c4e0f0f0f0f0f0f0f0f060f0f0f0f0f0f0f0f0f494b0f0f0f0f060f0f7475767778797a7b00000000000000000000000000000000
000000002220232e1b2f2100212121003636373736363737363637373636373736363737363637370f4f0f0f0f0f0f0f0f0f0f495c4b0f0f400f0f4f0f0f49574d4d4d4d4d5857580f0f4f0f0f0f0f0f0f0f0f0f4f0f0f0f0f0f4f0f4647475a4b0f0f0f4f0f0f0f000000000000000000000000000000000000000000000000
121311000000002b2c2d0000000000003737363637373636373736363737363637373636373736360f0f0f0f0f0f0f0f0f0f0f4c4d4e0f0f0f0f0f0f0f465a4e0f0f0f0f0f4c595a0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4c4d4d4d4e0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000
101010121312301312131112131230133737363637373636373736363737363637373636373736360f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4f480f0f0f0f494b0f0f0f0f4f0f0f4c580f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f400f0f4f0f0f0f0f0f0f000000000000000000000000000000000000000000000000
212223222321212121222322232121213636373736363737363637373636373736363737363637370f0f0f46480f0f0f0f0f0f0f0f0f0f0f4b4f0f0f465a4b0f0f0f020f0f0f0f490f0f0f0f0f0f0f0f0f0f4647480f0f0f0f0f0f0f0f0f0f0f0f0f46480f0f0f0f000000000000000000000000000000000000000000000000
000000000000000000000000000000003636373736363737363637373636373736363737363637374747475a5947480f0f0f0f0f0f0f0f0f594747475a5d4b0f0f0f06020f0f0f490f020f0f0f0f0f0f0f0f495c4b0f0f0f0f020f0f0f0f0f4647475a4e0f0f0f0f000000000000000000000000000000000000000000000000
002425252525252525252525252526003737363637373636373736363737363637373636373736364d4d4d4d585d4b0f0f0f0f0f0f0f0f0f574d4d4d4d584b0f0f020f0240020f490f0f0f0f4f0f0f0f0f0f4c5859480f0f02400f0f4f0f0f49574d4e0f0f0f0f0f000000000000000000000000000000000000000000000000
2728353535353535353535353535292a3737363637373636373736363737363637373636373736360f0f0f0f4c584b0f0f0f0f0f0f020f0f4b0f0f0f0f494b0f0f0f0f0f020f0f490f0f0f0f0f0f0f0f0f0f0f4c4d4e0f0f0f0f0f0f0f0f0f494b0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000
000000000000000000000000000000003636373736363737363637373636373736363737363637370f0f0f020f494b0f0f0f0f06400f0f0f4b0f060f0f4c59480f0f0f4f0f0f465a0f0f0f4f0f0f0f0f0f0f0f0f020f4f0f0f0f0f4f0f0f0f494b0f0f0f020f4f0f000000000000000000000000000000000000000000000000
004500000000000000450000000000003636373736363737363637373636373736363737363637370f0f400f0f494b0f0f0f0f0f0f0f0f0f4b0f0f0f0f4f495948400f0f0f465a5c0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f020f494b0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000
000000000000000000000000000000003737363637373636373736363737363637373636373736360f0f0f0f0f4959480f0f4f0f0f0f0f0f4b0f0f0f0f0f495b59474747475a5d4a0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4959480f0f0f060f0f000000000000000000000000000000000000000000000000
0000000000000000000000000000000037373636373736363737363637373636373736363737363647474747475a5c4b0f0f0f0f0f0f0f0f5947474747475a4a4a4a4a4a4a4a4a5b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f495c4b0f0f0f0f0f0f000000000000000000000000000000000000000000000000
002425252525252525252525252526000000000000000000000000000000000000000000000000000f0f0f0f0f0f495b4a4b0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2728353535353535353535353535292a0000000000000000000000000000000000000000000000000f0f0f0f0f465a4a4a4b0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000f020f0f0f494a4a5c4b0f0f400f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003200000000000000000000000031000000000000000000000000000000000000000000000000000f0f0f0f0f494a4a4a4b0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003400000000000000000000000033000000000000000000000000000000000000000000000000000f0f0f0f0f4c585d4a4b0f0f0f060f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000f0f4f0f0f0f494a4a59474747474747000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000004747474747475a57584a574d4d585b4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003100000000000000000000000032000000000000000000000000000000000000000000000000004d4d4d4d4d584a595a4a4b020f494a4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003300000000000000000000000034000000000000000000000000000000000000000000000000000f0f0f0f0f4c584a4a4a4b0f4f494a4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000f020f0f0f0f495c4a5b5947475a4a4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002425252525252525252525252526000000000000000000000000000000000000000000000000000f0f0f0f400f4c4d58574d4d4d4d4d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2728353535353535353535353535292a0000000000000000000000000000000000000000000000000f0f0f0f0f0f0f0f4c4e0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000f4f46480f0f0f0f0f0f0f0f020f4f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004500000000000000450000000000000000000000000000000000000000000000000000000000000f0f495947480f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000f0f4c4d4d4e0f0f0f0f0f0f0f060f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000c5700d4700947008470054700677003770037700477004770057700577006770087700a7700d7701077013770174701a4701f470234702d470344703a470027002d200342003b200000000000000000
000100002a7702277018770147700d77008770027700177000000000000000000000197700f770057700277001770000000000000000000000000000000000000000000000000000000000000000000000000000
0102000018270002030c2700020300270002030c270002030c2000000000203000000020300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070000185730c1730000000000306360000000000000003c643246003c5713c5503c613000000c67000000185730c17300000000000c573001030000000000186300000000000000003c643000003063400000
010e00000c0700c0721b0721b002301063050618072000003c4013c400160721600218072000001b0720000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001d60505202180700c00030106305060c070000002e1062e50616070000001707017000180700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000000000000180000000000000180000000000000180000000018070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070000185730c173000000000030636000000000000000306360000000000306363060600000306360000000000306360000000000306360000000000000000000000000000000000000000000000000000000
010e00001d07000000000001d07000000000001d070000001d0701d000000000000000000000001d0701b07016070160700000016070160700000017070170701707017000000000000000000000001607000000
01070000185730c1730000000000306360000000000000003c643246003c5013c5003c613000000c67000000185730c17300000000000c573001030000000000186300000000000000003c643000003063400000
010e000016072160720000016072160720000017072170721707217000000000000000000000001b0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070000185730c1730000000000306360000000000000003c643246003c5013c5003c613000000c67000000185730c17300000000000c573001030000000000186000000000000000003c603000003063400000
000300000107003070080700e0701607020070320703f0701d0002200028000340003e000190001c00020000240002a0002f00032000390003a00030000000000000000000000000000000000000000000000000
000200002b27030270352702c270342703a27031270362702b2703c270262702f27032270352703027033270382702177017770117700d7700a76009760087500574003730027200271002720027200171001700
00030000300703f030210400000002000000002101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001507318000150751800230625000001507500000150730000015072213063562500000150750000015073180001507518000306250000015075000001507300000150750000035625000001507500000
000100001d04029030350500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001857010070030600105001510010000100001000000000000000000000000a01007010060100270001700000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001a073180001a0751800230625000001a075000001a073131061a0750000024625000001a075000001a073180001a0751800024625000001a075000001a073000001a0750000035625000001a07500000
010a00001c073180001c0751800230625000001c075000001c073131061c0750000024625000001c075000001a073180001a0751800024625000001a075000001a073000001a0750c63535625000001a07500000
010a0000022150222502212022220e2120e2200221002225022150e221022150e2250e21502215022150e220022150222502212022220e2120e2200221002225022150e221092150922507215072150521505220
010a000007215072250721207222132121322007210072250721513221072151322513215072150721513220072150722507212072221321213220072100722507215132210921515225002150c215002150c220
010a00000921509225092120922215212152200921009225092151522109215152251521509215092151522007215072250721207222072120722013210072250721507221072151322513215112150e2150c220
010a0000022150222502212022220e2120e2200221002225022150e221022150e2250e21502215022150e220022150222502212022220e2120e22002210022250223002230072300723009230092300c2300c230
010a00001507318000150751800230625000001507500000150730000015072356353562500000150753563515073180001507518000306250000015075000000033000330023300233004330043300533005330
000a00000c175180000c0751800230615000000c075000000f175000000f07500000356150000011075000000c175180000c0751800030615000000c075000000f175000000f0750000035615000001107500000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 03044344
00 03054344
00 03044344
00 07064344
00 03044344
00 03054344
00 03044344
00 07064344
00 09084344
02 0b0a4344
01 0f144344
00 0f144344
00 12154344
00 0f144344
00 13164344
02 18174344
03 19424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

