# Program rysujacy algorytmem Bresenhama na obrazie BMP (24bpp) elipse o zadanych: wspolrzednych srodka i dlugosciach polosi
# @autor: Wiktor Franus
# 	  grupa: 4I1
# 	  Warsaw University of Technology
#
# $t0 -	adres poczatku tablicy pikseli		#s0 - rozmiar pliku
# $t1 -	wspolrzedna x				#s1 - rozmiar wiersza w bajtach
# $t2 -	wspolrzedna y				#s2 - granica rysowania - punkt w ktorym nachylenie stycznej do elipsy przekracza -1
# $t3 - dlugosc polosi a			#s3 - zmienna pomocnicza
# $t4 - dlugosc polosi b			#s4 - skladowa koloru piksela B
# $t5 - a^2					#s5 - skladowa koloru piksela G
# $t6 - b^2					#s6 - skladowa koloru piksela R
# $t7 - zmienna decyzyjna d			#s7 - adres pliku na stercie
# $t8 - wskaznik pisania			#a1 - flaga informujaca czy juz osiagnieto raz granice rysowania (rozroznia rysowanie 1 i 2)
# $t9 - zmienna pomocnicza

		.data
x0:		.word	100
y0:		.word	100
r_a:		.word   10
r_b:		.word   3
#################
R:		.byte   0
G:		.byte   0
B:		.byte   0
obraz: 		.asciiz "/home/franek/projekty/arko/mips_elipsa/biale_tlo2.bmp"
obraz2:		.asciiz "/home/franek/projekty/arko/mips_elipsa/out.bmp"
text1:		.asciiz "Wczytuje obraz BMP\n"
text2:		.asciiz "Program zakancza dzialanie"
blad_wczyt:	.asciiz "Blad wczytania pliku. Program zakancza dzialanie\n"
blad_dlugosc:   .asciiz "Blad: Conajmniej jedna z polosi musi miec dlugosc wieksza od zera\n"
newline:	.asciiz "\n"
		.align  2
header:		.space  36

        	.text
        	.globl main
main:
	la   $a0, text1
	li   $v0, 4
	syscall		   #wyświetla pierwszy komunikat w konsoli
	
	
  	li   $v0, 13       # otworz plik
  	la   $a0, obraz    # output file name
  	li   $a1, 0        # tryb odczytu
  	li   $a2, 0        # nieistotne
  	syscall            
  	move $t1, $v0      # zapisz deskryptor w t1
  	bltz $t1, blad_plik_in

	# wczytaj 'BM' z naglowka
 	li   $v0, 14       
 	move $a0, $t1      # file descriptor 
  	la   $a1, header   # adres bufora
 	li   $a2, 2        # ilosc bajtow do wczytana
  	syscall
  	# wczytaj reszte naglowka
  	li   $v0, 14       
 	move $a0, $t1      # file descriptor 
  	la   $a1, header   # adres bufora
 	li   $a2, 36       # ilosc bajtow do wczytana  
 	syscall
 	
 	la   $t0,header
 	lw   $s0,0($t0)    # wczytaj rozmiar calego pliku
 	lw   $s2,8($t0)    # wczytaj offset tablicy pikseli
 	lw   $s1,16($t0)   # wczytaj szerokosc bitmapy
 	
 	# zamknij plik
 	li   $v0, 16       # system call for close file
  	move $a0, $t1      # file descriptor to close
  	syscall
  	
	#zaalokuj pamiec na plik na stercie
	la   $v0, 9 
	la   $a0, ($s0)    # alokuje pamięć
	syscall
	move $t0,$v0	   # w $t0 adres zaalokowanej pamieci

	
	# otworz ponownie plik i wpisz go calego do zaalokowanej pamieci
  	li   $v0, 13       # otworz plik
  	la   $a0, obraz    # output file name
  	li   $a1, 0        # tryb odczytu
  	li   $a2, 0        # nieistotne
  	syscall   
  	move $t1, $v0      # zapisz deskryptor w t1
  	
  	li   $v0, 14       
 	move $a0, $t1      # file descriptor 
  	la   $a1, ($t0)    # adres bufora
 	move $a2, $s0      # ilosc bajtow do wczytana  
 	syscall	
 
  	# zamknij plik
  	li   $v0, 16       # system call for close file
  	move $a0, $t1      # file descriptor to close
  	syscall            # close file

# Zapamietaj adres poczatku pliku w $s7 oraz ustaw wskaznik $t0 na poczatek tablicy pikseli
	move $s7,$t0
	add  $t0,$t0,$s2
	
#######################
# Oblicz rozmiar wiersza w bajtach (z paddingiem) i zapisz w $s1
	add  $t5,$s1, $s1  # $t5 = 3 * szerokosc_bmp_w_pikselach , bo każdy piksel zapisany jest za pomocą 3 bajtów
 	add  $t5,$t5, $s1
 	andi $t6,$t5,3	   # szerokosc_bmp % 4
 	beqz $t6,kontynuuj # jesli szerokosc bitmapy w bajtach jest podzielna przez 4, nic nie rob
			   # w p.p. dodaj padding
	li   $t7, 4
	sub  $t7, $t7, $t6
	add  $t5,$t5,$t7

kontynuuj:
	move $s1,$t5
	
	# wolne: $t1-t9, $s2-$s6
	
# Wczytaj z pamieci bajty R G B koloru pikseli
	lb   $s4, B
	lb   $s5, G
	lb   $s6, R 
	
	li   $a2,1	   # ustaw flage, ktora informuje czy juz osiagnelismy pierwsza granice czy nie
bresenham:
# Wczytaj z pamieci dane elipsy
	lw   $t3, r_a	   # a - dlugosc dluzszej polosi
	lw   $t4, r_b	   # b - dlugosc krotszej polosi
	add  $t9,$t3,$t4	
	beqz $t9,blad_polosie # blad jesli obie polosie rowne 0
	
po_zamianie:
	lw   $t1, x0	   # x srodka
	lw   $t2, y0	   # y srodka

	
# Oblicz a^2, b^2, d = 4*b2 - 4*b*a2 + a2 i granice rysowania = x2 = a4 / (a2 + b2)
	multu $t3,$t3
	mflo  $t5	   # $t5 = a^2
	multu $t4,$t4
	mflo  $t6	   # $t6 = b^2	
	sll   $t7,$t6,2	   # $t7 = 4*b^2
	mult  $t5,$t4
	mflo  $s3
	sll   $s3,$s3,2    # $s3 = 4*b*a^2 -tmp
	add   $t7,$t7,$t5
	sub   $t7,$t7,$s3  # $t7 = d    
	mult  $t5,$t5
	mflo  $s3
	add   $s2,$t5,$t6
	div   $s2,$s3,$s2  # $s2 = limit

	# wolne: $t8,t9,$s3
	
# Ustaw wskaźnik pisania na punkt (x0,y0+dl_polosi_pionowej), czyli 'czubek elipsy'
# wskazik = adres_pocz_buf + (y0+dl_polosi_pionowej)*szer_wiersza_w_bajtach + 3*x0

	add   $t8,$t2,$t4
	mult  $s1,$t8
	mflo  $t8
	add   $t8,$t8,$t1
	add   $t8,$t8,$t1
	add   $t8,$t8,$t1
	add   $t8,$t8,$t0  # $t8 - adres pierwszego bajtu piksela
	
	# wolne: t9,$s3

# Na potrzeby algorytmu ustaw tymczasowe wspolrzedne pierwszego piksela na (1,dl_polosi_pionowej)
	li    $t1,1	   # x
	move  $t2,$t4	   # y

loop:		
	jal   rysuj_4_piksele
	
	# sprawdz czy osiagnieto granice rysowania,tj. czy x2 >= limit
	mult  $t1,$t1
	mflo  $t9
	bge   $t9,$s2,zamien_polosie
	
 	# sprawdz wartosc zmiennej decyzyjnej
	bltz  $t7,wybierz_E
	
# RUCH w kier SE: Zwieksz x o 1, y zmniejsz o 1 i zaaktualizuj zmienna decyzyjna d = d + 8*b2*x + 12*b2 - 8*a2*y + 8*a2, 
# gdzie x to poprzednie x zwiekszone o 1, a y to poprzednie y zmniejszone o 1

	mult  $t6,$t1
	mflo  $t9
	sll   $t9,$t9,3
	add   $t7,$t7,$t9
	sll   $t9,$t6,2
	add   $t7,$t7,$t9
	add   $t7,$t7,$t9
	add   $t7,$t7,$t9
	sll   $t9,$t5,3
	add   $t7,$t7,$t9
	mult  $t5,$t2
	mflo  $t9
	sll   $t9,$t9,3
	sub   $t7,$t7,$t9
	
	addiu $t1,$t1,1    # x = x+1
	sub   $t2,$t2,1    # y = y-1
	
	sub   $t8,$t8,$s1  #
	addiu $t8,$t8,1	   # ustaw wskaznik pisania na kolejny bajt, ale w poprzednim rzedzie
	
	j     loop
	
# RUCH w kier E: Zwieksz x o 1 i zaaktualizuj zmienna decyzyjna d = d + 8*b2*x + 12*b2, gdzie x to poprzednie x zwiekszone o 1
wybierz_E:

	mult  $t6,$t1
	mflo  $t9
	sll   $t9,$t9,3
	add   $t7,$t7,$t9
	sll   $t9,$t6,2
	add   $t7,$t7,$t9
	add   $t7,$t7,$t9
	add   $t7,$t7,$t9
	
	addiu $t1,$t1,1    # x = x+1
	addiu $t8,$t8,1    # ustaw wskaznik pisania na kolejny bajt
	
	j     loop

#######################	
rysuj_4_piksele:
	sw    $ra,-4($sp)  # zachowaj adres powrotu na stosie
	bgtz  $a2,nie_zamieniaj # jesli pierwsze rysowanie to nic nie zmieniaj
				# w drugim rysowaniu zamien osie OX i OY			
	move  $a0,$t2
	move  $t2,$t1
	move  $t1,$a0	   # zamiana wspolrzednych x i y
	
	# wskazik = adres_pocz_buf + (y0+y)*szer_wiersza_w_bajtach + 3*(x0+x-1)	
	lw    $a0,y0
	add   $t8,$t2,$a0
	mult  $s1,$t8
	mflo  $t8
	lw    $a0,x0
	add   $a0,$a0,$t1
	subiu $a0,$a0,1
	add   $t8,$t8,$a0
	add   $t8,$t8,$a0
	add   $t8,$t8,$a0
	add   $t8,$t8,$t0  # $t8 - adres pierwszego bajtu piksela
	
nie_zamieniaj:
	jal   rysuj_pixel
	
	move  $s3,$t8      # zapamietaj wskaznik zanim zostanie przesuniety
	
	# rysuj piksel w II cwiartce ukladu wspolrzednych
	sll   $t9,$t1,3
	sub   $t9,$t9,$t1
	sub   $t9,$t9,$t1
	subiu $t9,$t9,1	   # odjecie piksela lezacego na prostej x=0
	move  $a3,$t9      # w a3 zapamietaj roznice |x1-x2| miedzy pikselem w I i II cwiartce
	sub   $t8,$t8,$t9
	jal   rysuj_pixel
	
	# rysuj piksel w III cwiartce ukladu wspolrzednych
	sll   $t9,$t2,1
	subiu $t9,$t9,1
	mult  $t9,$s1
	mflo  $t9	   
	sub   $t8,$t8,$t9
	subiu $t8,$t8,2    # powrot na 1 bajt pixela (wczesniej wskaznik byl na 3 bajcie pixela)
	jal   rysuj_pixel
	
	# rysuj piksel w IV cwiartce ukladu 
	add   $t8,$t8,$a3
	subi  $t8,$t8,4    # powrot na 1 bajt piksela
	jal   rysuj_pixel

	move  $t8,$s3      # wczytaj z powrotem wskaznik pisania z I cwiartki
	
	bgtz  $a2,powrot
	move  $a0,$t2	   #
	move  $t2,$t1	   #
	move  $t1,$a0	   # zamien z powrotem x i y

powrot:
	lw    $ra,-4($sp)
	jr    $ra
#######################		
		
rysuj_pixel:
	sb    $s4,($t8)
	addiu $t8,$t8,1
	sb    $s5,($t8)
	addiu $t8,$t8,1
	sb    $s6,($t8)
	jr    $ra

#######################

zamien_polosie:
	beqz  $a2,zapis
	lw    $t3,r_b
	lw    $t4,r_a
	subi  $a2,$a2,1	   # ustaw flage na 0
	j     po_zamianie
	
###########################################
# Zapis do pliku

zapis:
 	li   $v0, 13       # otworz plik wyjsciowy
  	la   $a0, obraz2   # output file name
  	li   $a1, 1        # tryb odczytu
  	li   $a2, 0        # nieistotne
  	syscall            
  	move $t1, $v0      # zapisz deskryptor w t1
  	
 	li   $v0, 15       
 	move $a0, $t1      # file descriptor 
 	move $a1, $s7      # adres bufora
 	move $a2, $s0      # ilosc bajtow do wczytana
  	syscall
  	
  	# zamknij plik
  	li   $v0, 16       # system call for close file
  	move $a0, $t1      # file descriptor to close
  	syscall  
  	
  	j koniec
  	
###########################################
# Blad wczytania pliku

blad_plik_in:	
	li   $v0, 4	   # wypisz komunikat bledu
	la   $a0, blad_wczyt	
	syscall

blad_polosie:	
	li   $v0, 4	   # wypisz komunikat bledu
	la   $a0, blad_dlugosc	
	syscall

koniec:	
	la   $a0, text2
	li   $v0, 4
	syscall		   #wyświetla ostatni komunikat w konsoli

	li   $v0, 10
    	syscall
 	
