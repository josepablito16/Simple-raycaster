import pygame
from math import pi, cos, sin, atan2
import threading
#python3 setup.py build_ext --inplace


cdef list enemies = [
	{
		"x": 1013,
		"y": 74,
		"texture": pygame.image.load('./img/sprite1.png')
	},
	{
		"x": 266,
		"y": 124,
		"texture": pygame.image.load('./img/sprite2.png')
	},
	{
		"x": 206,
		"y": 274,
		"texture": pygame.image.load('./img/sprite3.png')
	},
	{
		"x": 612,
		"y": 105,
		"texture": pygame.image.load('./img/sprite3.png')
	},
	{
		"x": 1012,
		"y": 405,
		"texture": pygame.image.load('./img/sprite2.png')
	}
]

cdef object arm = pygame.image.load('./img/player.png')


cdef object wall1 = pygame.image.load('./img/wall1.png')
cdef object wall2 = pygame.image.load('./img/wall2.png')
cdef object wall3 = pygame.image.load('./img/wall3.png')


cdef dict textures = {
	"1": wall1,
	"2": wall2,
	"3": wall3
}


cdef class Raycaster:
	cdef int width
	cdef int height
	cdef object screen 
	cdef int blocksize
	cdef dict player 
	cdef list map
	cdef list zbuffer
	cdef public int up
	cdef public int down
	cdef public int left
	cdef public int right
	cdef int maxTick
	cdef float rotationVel
	cdef int moveVel
	cdef dict __dict__

	def __cinit__(self, screen):
		_, _,self.width,self.height = screen.get_rect()
		self.screen = screen
		self.blocksize = 50
		self.player = {
			"x": self.blocksize + 20,
			"y": self.blocksize + 20,
			"a": pi/3,
			"fov": pi/3
		}
		self.map = []
		self.zbuffer = [-float('inf') for z in range(0, self.height)]
		self.up=0
		self.down=0
		self.left=0
		self.right=0
		self.maxTick=30
		self.rotationVel=0.2
		self.moveVel=1

	cpdef void load_map(self, str filename):
		cdef object f
		cdef str line
		with open(filename) as f:
			for line in f.readlines():
				self.map.append(list(line))

	cpdef void point(self, int x, int y,c = None):
		self.screen.set_at((x, y), c)

	cpdef cast_ray(self,double a):
		cdef int d = 0
		cdef double x
		cdef double y
		cdef int i
		cdef int j
		cdef double hitx
		cdef double hity
		cdef double maxhit
		cdef int tx
		while True:
			try:
				x = self.player["x"] + d*cos(a)
				y = self.player["y"] + d*sin(a)

				i = int(x/self.blocksize)
				j = int(y/self.blocksize)

				if self.map[j][i] != ' ':
					hitx = x - i*self.blocksize
					hity = y - j*self.blocksize

					if 1 < hitx < self.blocksize-1:
						maxhit = hitx
					else:
						maxhit = hity

					tx = int(maxhit * 128 / self.blocksize)
					return d, self.map[j][i], tx
				d += 1
			except:
				pass


	cpdef void draw_stake(self,int x,double h, object texture, int tx):
		cdef int start = int((self.height - h)/2)
		cdef int end = int((self.height+ h)/2)
		cdef int y
		cdef int ty
		for y in range(start, end):
			ty = int(((y - start)*texture.get_height())/(end - start))
			c = texture.get_at((tx, ty))
			self.point(x, y, c)

	

	cpdef void draw_sprite(self, dict sprite):
		cdef double sprite_a = atan2(sprite["y"] - self.player["y"], sprite["x"] - self.player["x"]) 
		 
		cdef double sprite_d = ((self.player["x"] - sprite["x"])**2 + (self.player["y"] - sprite["y"])**2)**0.5		
		cdef int sprite_size = int((self.height/sprite_d) * 70)

		cdef int sprite_x = int(self.height*(sprite_a - self.player["a"])/self.player["fov"] + (self.height/2) - sprite_size/2)

		cdef int sprite_y = int((self.height/2) - sprite_size/2)

		cdef int x,y,tx,ty
		for x in range(sprite_x, sprite_x + sprite_size):
			for y in range(sprite_y, sprite_y + sprite_size):
				if 0 < x < self.width and self.zbuffer[x - self.height] >= sprite_d:

					tx = int((x - sprite_x) * sprite["texture"].get_width()/sprite_size)
					ty = int((y - sprite_y) * sprite["texture"].get_height()/sprite_size)
					c = sprite["texture"].get_at((tx, ty))
					if c != (152, 0, 136, 255):
						self.point(x, y, c)
						self.zbuffer[x - self.height] = sprite_d

		

	cpdef void draw_player(self,int xi, int yi,int w = 256, int h = 256):
		cdef int x,y,tx,ty
		for x in range(xi, xi + w):
			for y in range(yi, yi + h):
				tx = int((x - xi) * arm.get_width()/w)
				ty = int((y - yi) * arm.get_height()/h)
				c = arm.get_at((tx, ty))
				if c != (152, 0, 136, 255):
					self.point(x, y, c)


	cpdef void worker1(self,int i):
		cdef double a = self.player["a"] - self.player["fov"]/2+ self.player["fov"]*i/self.height
		cdef int d
		cdef int tx
		cdef double h
		d, c, tx = self.cast_ray(a)
		
		try:
			h = self.height/(d*cos(a-self.player["a"])) * 70
			self.draw_stake(i, h, textures[c], tx)
			self.zbuffer[i] = d
		except:
			pass

	

	cpdef void move(self):
		cdef int dt = pygame.time.Clock().tick(self.maxTick)
		
		
		if self.left:
			self.player["a"] -= pi/(self.rotationVel*dt)
		elif self.right:
			self.player["a"] += pi/(self.rotationVel*dt)
		elif self.up:
			self.player["y"] += int((self.moveVel*dt)*sin(self.player["a"]))
			self.player["x"] += int((self.moveVel*dt)*cos(self.player["a"]))
		elif self.down:
			self.player["y"] -= int((self.moveVel*dt)*sin(self.player["a"]))
			self.player["x"] -= int((self.moveVel*dt)*cos(self.player["a"]))

	cpdef void render(self):

		cdef int i
		cdef object t
		for i in range(0, self.width):
			t=threading.Thread(target=self.worker1,args=(i,))
			t.start()
		t.join()

		cdef dict enemy
		for enemy in enemies:
			self.point(enemy["x"], enemy["y"], (0, 0, 0))
			self.draw_sprite(enemy)
			
		self.draw_player(self.width -256, self.height - 256)