for RP in {classic,vanilla,zero,cherry,new}.coke {crystal,max,one,wild-cherry,throwback}.pepsi {sherry,champagne,syrah,merlot,pinot,malbec,port}.wine {ipa,lager,stout,wheat,lambic}.beer rum tequila gin rye bourbon; do
  ssh root@proxy.${RP}.$DOMAIN.com "ifconfig; iptables -L -n -t nat"
done
