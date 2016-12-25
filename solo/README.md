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
		* read password
		* there have bof
* exit
	* quit
		
# 0x1 exploit

 
