default:
	cd nistfalcon/src;\
	rm -f *.o libfalcon.a;\
	gcc -c -O3 -fPIC -DALGNAME=falcon512int *.c;\
	ar rcs libfalcon.a build/*.o;
	cp nistfalcon/src/libfalcon.a .

	CGO_CFLAGS="-I./nistfalcon/src -DALGNAME=falcon512int" CGO_LDFLAGS="-DALGNAME=falcon512int -L./nistfalcon/src -lfalcon" go run -x falcon.go


