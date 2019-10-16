
0. Prepare:
> chmod 700 ./dnsresolver.bash
1. Create new DNS Resolver with suffix 0 and code, residing in dnsresolver-code.fc:
> ./dnsresolver.bash new 0
2. Check its version
> ./dnsresolver.bash get 0 ver
> > result:  [ 42 ] 
3. Update code of DNS Resolver with suffix 0 by dnsresolver-updated.fc:
> ./dnsresolver.bash upd 0
4. Check its version
> ./dnsresolver.bash get 0 ver
> > result:  [ 43 ] 
5. Create another DNS Resolver with suffix 1 and code, residing in dnsresolver-code.fc:
> ./dnsresolver.bash new 1
6. Check public key of owner of DNS Resolver with suffix 0:
> ./dnsresolver.bash owner 0
7. Check public key of owner of DNS Resolver with suffix 1:
> ./dnsresolver.bash owner 1
8. Change owner of DNS Resolver with suffix 0 to same owner of DNS Resolver with suffix 1:
> ./dnsresolver.bash transfer 0 dnsresolver1.pk
9. Check public key of owner of DNS Resolver with suffix 0:
> ./dnsresolver.bash owner 0
10. Return back owner of DNS Resolver with suffix 0 :
> ./dnsresolver.bash transfer 0 dnsresolver0.pk.old
11. Check public key of owner of DNS Resolver with suffix 0:
> ./dnsresolver.bash owner 0
> 
