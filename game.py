import pygame
from Raycaster import Raycaster



#MAIN
pygame.init()
screen = pygame.display.set_mode((400, 400), pygame.DOUBLEBUF|pygame.HWACCEL|pygame.HWSURFACE)
screen.set_alpha(None)

r = Raycaster.__new__(Raycaster,screen)
r.load_map('./map.txt')

c = 0
while True:

	screen.fill((0, 0, 0))
	

	try:
		e=pygame.event.get().pop()

		if e.type == pygame.QUIT or (e.type == pygame.KEYDOWN and e.key == pygame.K_ESCAPE):
			break

		if e.type == pygame.KEYDOWN:
			if e.key == pygame.K_LEFT:
				r.left=1
			elif e.key == pygame.K_RIGHT:
				r.right=1
			elif e.key == pygame.K_UP:
				r.up=1
			elif e.key == pygame.K_DOWN:
				r.down=1

		elif(e.type ==pygame.KEYUP):
			if e.key == pygame.K_LEFT:
				r.left=0
			elif e.key == pygame.K_RIGHT:
				r.right=0
			elif e.key == pygame.K_UP:
				r.up=0
			elif e.key == pygame.K_DOWN:
				r.down=0

	except:
		pass
	r.render()
	r.move()	
	

	pygame.display.flip()
