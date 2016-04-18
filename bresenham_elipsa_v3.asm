# Realizuje algorytm Bresenhama na obrazie BMP (24-bitowy) na dowolnej wielkości obrazu
#
# autor: Grzegorz Kuśmirek
# grupa 3I3
#
# $t0 - bajty wczytanego obrazu		$s0 -
# $t1 - x początkowe			$s1 - xi
# $t2 - y początekowe			$s2 - szerokość wiersza obrazu (w bajtach)
# $t3 - x końcowe			$s3 - wartość koloru B
# $t4 - y końcowe			$s4 - wartość koloru G
# $t5 - dx				$s5 - wartość koloru R
# $t6 - dy				$s6 - adres na początek pamięci z bajtami obrazu
# $t7 - ai				$s7 - liczba bajtów obrazu
# $t8 - bi
# $t9 - d
#
#######################################################################################
				
		.data
blad_wczyt:	.asciiz "Blad wczytania pliku. Program zakancza dzialanie\n"
text1:		.asciiz "Wczytuje obraz BMP\n"
text2:		.asciiz "Program zakancza dzialanie"
blad_wspolrz:	.asciiz "\nBledne wspolrzedne\n"
Nagl:		.space 	54
obraz: 		.asciiz "sarah.bmp"
obraz2:		.asciiz "a.bmp"
		.text
		.globl main
main:
	la $a0,text1
	li $v0,4
	syscall		#wyświetla pierwszy komunikat w konsoli

###########################################
# Wczytuja dane z pliku i zamyka plik

	li	$v0, 13		# 13 - otw�rz plik
	la	$a0, obraz	# adres stringa zawieraj�cego t�o symulacji ("biale_tlo.bmp")
    	li	$a1, 0		# flaga for read-only
    	li	$a2, 0		# tryb
    	syscall
    
   	move	$t3, $v0 	# $v0 zawiera deskryptor pliku
   	bltz	$t3, blad_plik_in	# przeskocz do blad_plik_in jesli wczytywanie sie nie powiodlo

	li	$v0, 14		# 14 - czytaj z pliku
	move	$a0, $t3	# deskryptor pliku
	la	$a1, Nagl	# adres bufora do kt�rego ma by� wczytane (.space 54)
	li	$a2, 54		# maksymalna liczba bajt�w do wczytania
	syscall	

	la $t0, Nagl
	lw $s7,34($t0)		#wyczytuje rozmiar pliku
	lw $s3,18($t0)
	add $s2,$s3, $s3
 	add $s2,$s2, $s3
	
	andi $t9,$s2,3
	li $t8, 4
	sub $t8, $t8, $t9
	add $s2,$s2,$t8

	la $v0, 9 
	la $a0, ($s7) 		#alokuje pamięć
	syscall 
	move $t0,$v0		#w $t0 -> nasza Mapa
	move $s6,$t0		#w $s6 -> rozmiar całej mapy

	li	$v0, 14		# 14 - czytaj z pliku	
	move	$a0, $t3	# deskryptor pliku			
	move	$a1, $t0	# adres rejestru, do którego ma być zapisane
	move	$a2, $s7	# maksymalna liczba bajt�w do wczytania				
	syscall	

	li	$v0, 16		# 16 - zamknij plik
	syscall	
						
###########################################
# Pobiera wspolrzedne odcinka 

	li $t1, 10	#x pocz
	li $t2, 10	#y pocz
	li $t3, 25	#x kon
	li $t4, 20	#y kon

#zamienia, żeby ykońcowe większe od ypoczątkowego
	blt $t4, $t2, et11
	j laduj_kolory
et11:
	move $t5, $t4
	move $t4, $t2
	move $t2, $t5
	move $t5, $t1
	move $t1, $t3
	move $t3, $t5
laduj_kolory:
	li $s3, 255	#ładuje B do rejestru s3
	li $s4, 0	#ładuje G do rejestru s4
	li $s5, 0	#ładuje R do rejestru s5

# Ustawia na pierwszym pikselu i rysuje go
	li $t5, 0	#licznik
przesun:
	beq $t5, $t2, rysuj	#jeśli y1 razy przesunęliśmy się o rozmiar mapy - przejdź do rusuj:
	add $t0, $t0, $s2
	add $t5, $t5, 1
	j przesun
rysuj:
	add $t0, $t0, $t1
	add $t0, $t0, $t1
	add $t0, $t0, $t1
	sb $s3,($t0)	#rysuje pierwszy piksel
	add $t0, $t0, 1
	sb $s4, ($t0)
	add $t0, $t0, 1
	sb $t5, ($t0)

	blt $t1, $t3, x1_mniejsze	#if(x1<x2)=>skocz do x1_mniejsze
	li $s1, -1		#xi = -1
	sub $t5, $t1, $t3	#dx = x1 - x2
	j dy
x1_mniejsze:
	li $s1, 1		#xi = 1
	sub $t5, $t3, $t1	#dx = x2 - x1
dy:
	blt $t2, $t4, y1_mniejsze	#if(y1<y2)=>skocz do y1_mniejsze
	sub $t6, $t2, $t4	#dy = y1 - y2
	j et3
y1_mniejsze:
	sub $t6, $t4, $t2	#dy = y2 - y1
et3:
	bgt $t5, $t6, dx_wieksze	#if(dx>dy)=>skocz do dx_wieksze
	sub $t7, $t5, $t6	#ai = dx - dy
	sll $t7, $t7, 1		#ai*2
	move $t8, $t5		
	sll $t8, $t8, 1		#bi = dx*2
	sub $t9, $t8, $t6	#d = bi - dy

loop1:
	beq $t2, $t4, zapisz_plik	#if(y == y2) => skocz do zapisz_plik
	bge $t9, $zero, d_wieksze		#if(d >= 0) => skocz do d_wieksze
	#Zwiększa tylko y1 o 1!!!
	add $t9, $t9, $t8	#d += bi
	add $t2, $t2, 1		#y1 += 1
	add $t0, $t0, $s2	#przesuwa bajty Mapy o Rozmiar
	add $t0, $t0,-2
	sb $s3,($t0)	#B
	add $t0, $t0, 1
	sb $s4, ($t0)	#G
	add $t0, $t0, 1
	sb $s5, ($t0)	#R
	j loop1
d_wieksze:
	#zwiększa y1 i x1 o 1
	add $t1, $t1, $s1		#x1 += xi
	add $t2, $t2, 1			#y1 += 1
	add $t9, $t9, $t7		#d += ai
	add $t0, $t0, $s2
	beq $s1,1,et1
	add $t0, $t0, -6
et1:
	add $t0, $t0,1
	#add $t0, $t0, 3			#trzeba jeszcze przesunąć o 3 bajty
	sb $s3,($t0)	#B
	add $t0, $t0, 1
	sb $s4, ($t0)	#G
	add $t0, $t0, 1
	sb $s5, ($t0)	#R
	j loop1


#### if(dx>dy)
dx_wieksze:
	sub $t7, $t6, $t5	#ai = dy - dx
	sll $t7, $t7, 1		#ai = ai*2
	move $t8, $t6
	sll $t8, $t8, 1		#bi = dy*2
	sub $t9, $t8, $t5	#d = bi - dx
loop2:
	#x1 przesuwa o jeden
	beq $t1, $t3, zapisz_plik	#if(x1 == x2) => skocz do zapisz_plik
	bge $t9, $zero, wieksze		#if(d>=0) => skocz do wieksze
	add $t9, $t9, $t8		#d += bi
	add $t1, $t1, $s1		#x1 += xi

	###Przesuwa x1 o jeden w prawo lub lewo
	beq $s1, 1, nie_przesuwaj
	add $t0, $t0, -6
nie_przesuwaj:
	add $t0, $t0,1
	sb $s3,($t0)	#B
	add $t0, $t0, 1
	sb $s4, ($t0)	#G
	add $t0, $t0, 1
	sb $s5, ($t0)	#R
	j loop2
wieksze:	
	#Przesuwa x i y o jeden!!!
	add $t1, $t1, $s1		#x1 = x1 + xi
	add $t2, $t2, 1			#y1 += 1
	add $t9, $t9, $t7		#d = d + ai
	add $t0, $t0, $s2		#przewuwa Mapę o Rozmiar
	beq $s1, 1, nie_przesuwaj2
	add $t0, $t0, -6
nie_przesuwaj2:
	add $t0, $t0,1
	sb $s3,($t0)	#B
	add $t0, $t0, 1
	sb $s4, ($t0)	#G
	add $t0, $t0, 1
	sb $s5, ($t0)	#R
	j loop2
###########################################
#Zapisuje dane do pliku

zapisz_plik:
	li	$v0, 13		# 13 - otworz plik
	la	$a0, obraz2	# adres stringa zawierajacego tlo symulacji ("Obraz.bmp")
    	li	$a1, 1		# flaga for read-only
    	li	$a2, 0		# tryb
    	syscall

	move	$t1, $v0 	# $v0 zawiera deskryptor pliku
	bltz	$t1, blad_plik_in	# przeskocz do blad_plik_in jesli wczytywanie sie nie powiodlo		

	li	$v0, 15		# 15 - zapisz do pliku
	move	$a0, $t1	# t1 - deskryptor pliku
	la	$a1, Nagl	# a1 - adres bufora, kt�ry ma by� wpisany do pliku
	li	$a2, 54		# a2 - liczba bajt�w do wpisania do pliku
	syscall



	li	$v0, 15		# 15 - zapisz do pliku
	move	$a0, $t1	# t1 - deskryptor pliku
	move	$a1, $s6	# a1 - adres bufora, kt�ry ma by� wpisany do pliku
	move	$a2, $s7	# a2 - liczba bajt�w do wpisania do pliku
	syscall

	li	$v0, 16		# 16 - zamknij plik
	move	$a0, $t1	# t1 - deskryptor pliku
	syscall
	j koniec
	
	
###########################################
#Blad wczytania pliku

blad_plik_in:	# b��d wczytania pliku z t�em
	li 	$v0, 4		# 4 - wypisanie stringa
	la 	$a0, blad_wczyt	# a0 - adres bufora, kt�ry ma by� wypisany
	syscall

koniec:	
	la $a0,text2
	li $v0,4
	syscall		#wyświetla ostatni komunikat w konsoli

	li	$v0, 10
    	syscall
