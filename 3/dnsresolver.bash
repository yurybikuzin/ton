#!/bin/bash

# PREREQUISITES:
#   sponsor.addr
#   sponsor.pk
#   wallet.fif
#   baddr.fif
#   naddr.fif
#   owner.fif
#   pub.fif
#   dnsresolver-new.fif
#   dnsresolver-reg.fif
#   dnsresolver-transfer.fif
#   dnsresolver-upd.fif
#   stdlib.fc
#   dnsresolver-code.fc
#   dnsresolver-updated.fc
#   auto/

# sponsor: kQBb4i4a5pEUWiNsjpOcILNk7ZXtSTOdSDmhwn2r1RodNegA

CONFIG=/etc/ton/ton-client.config
LCLIENT=lite-client
FIFT=fift
FUNC=func
SPONSOR=$("$FIFT" -s baddr.fif sponsor)
SLEEPTIME=25

prefix=dnsresolver
amout_default=0.5

cmd=$1
suffix=$2
if [[ $cmd == "" || $cmd == help ]]; then
  echo "This is *multi* DNS Resolvers handler utility"
  echo "PRIMARY USAGE:"
  echo "  0. $0 new SUFFIX"
  echo "    DESCRIPTION:"
  echo "      creates new DNS Resolver smart contract with"
  echo "        private key saved into ${prefix}SUFFIX.pk"
  echo "        and address saved into ${prefix}SUFFIX.addr"
  echo "    EXAMPLE: "
  echo "      $0 new 0"
  echo "  1. $0 transfer SUFFIX NEW-OWNER.PK"
  echo "    DESCRIPTION:"
  echo "      makes NEW-OWNER.pk is new owner of ${prefix}SUFFIX"
  echo "        (for convinience copies NEW-OWNER.PK to ${prefix}SUFFIX.pk)"
  echo "    EXAMPLE: "
  echo "      $0 transfer 0 new_owner.pk"
  echo "  2. $0 reg SUFFIX subdomain"
  echo "    DESCRIPTION:"
  echo "      sends register query to DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "    EXAMPLE: "
  echo "      $0 reg 0 ABC"
  echo "  3. $0 dnsresolve SUFFIX subdomain category"
  echo "    DESCRIPTION:"
  echo "      requests get-method 'dnsresolve' of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "    EXAMPLES: "
  echo "      $0 dnsresolve ABC 0"
  echo "      $0 dnsresolve DEF 1"
  echo "SECONDARY USAGE:"
  echo "  4. $0 lc [lite-client options]"
  echo "    DESCRIPTION:"
  echo "      runs $LCLIENT with -C \"$CONFIG\" and supplied options"
  echo "    EXAMPLE (shows sponsor account): "
  echo "      $0 lc -c last -c \"getaccount $SPONSOR\""
  echo "  5. $0 sponsor"
  echo "    DESCRIPTION:"
  echo "      shortcut for above example"
  echo "  6. $0 seqno SUFFIX"
  echo "    DESCRIPTION:"
  echo "      requests get-method 'seqno' of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  7. $0 get SUFFIX METHOD [ARGS...]"
  echo "    DESCRIPTION:"
  echo "      requests arbitrary get-method of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  8. $0 upd SUFFIX"
  echo "    DESCRIPTION:"
  echo "      sends update query (by new code from $prefix-updated.fc) of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  9. $0 show SUFFIX"
  echo "    DESCRIPTION:"
  echo "      shows state (lite-client 'getaccount') of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  10. $0 gas SUFFIX"
  echo "    DESCRIPTION:"
  echo "      returns gas remained of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  11. $0 baddr SUFFIX"
  echo "    DESCRIPTION:"
  echo "      returns Bounceable address of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  12. $0 naddr SUFFIX"
  echo "    DESCRIPTION:"
  echo "      returns Non-bounceable address (for init only) of DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  13. $0 fill-query SUFFIX [AMOUNT]"
  echo "    DESCRIPTION:"
  echo "      prepares wallet-query.boc with order to transfer AMOUNT ($amout_default by default) Grams"
  echo "      from sponsor account ($SPONSOR) to DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  14. $0 fill SUFFIX [AMOUNT]"
  echo "    DESCRIPTION:"
  echo "      prepares and sends wallet-query.boc with order to transfer AMOUNT ($amout_default by default) Grams"
  echo "      from sponsor account ($SPONSOR) to DNS Resolver (${prefix}SUFFIX) smart contract"
  echo "  15. $0 pretty NUMBER"
  echo "    DESCRIPTION:"
  echo "      adds thousand separators to number and returns it"
  echo "  16. $0 ls"
  echo "    DESCRIPTION:"
  echo "      list ${prefix}*.addr"
  echo "  17. $0 pub SUFFIX|PK-FILE"
  echo "    DESCRIPTION:"
  echo "      returns public key of PK-FILE or ${prefix}SUFFIX.pk"
  echo "  18. $0 owner SUFFIX"
  echo "    DESCRIPTION:"
  echo "      returns public key of owner of DNS Resolver with addr from ${prefix}SUFFIX.addr"
elif [[ $cmd == new ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ -e $file ]]; then
    echo "ERR: file '$file' already exists" >&2
    exit 1
  fi
  "$FUNC" -SPR -oauto/$prefix-code.fif stdlib.fc $prefix-code.fc && \
  "$FIFT" -s $prefix-new.fif 0 $prefix$suffix
  [[ $? -eq 0 ]] || exit $?
  $0 fill-query $suffix
  $0 lc -c "sendfile wallet-query.boc" -c "sendfile $prefix$suffix-new.boc"
  echo "Wait for a while ($SLEEPTIME secs) . . ."
  sleep $SLEEPTIME
  $0 show $suffix
elif [[ $cmd == transfer ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  shift
  new_owner_pk=$1
  file="$new_owner_pk"
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  "$FIFT" -s $prefix-transfer.fif $prefix$suffix $($0 seqno $suffix) "$new_owner_pk" && \
  $0 lc -c "sendfile $prefix$suffix-transfer.boc"
  if [[ $? -ne 0 ]]; then exit $?; fi
  seqno=$($0 seqno $suffix)
  gas=$($0 gas $suffix)
  echo "Wait for a while ($SLEEPTIME secs) . . ."
  sleep $SLEEPTIME
  gas_remained=$($0 gas $suffix)
  echo "gas(nano): $($0 pretty $gas) => $($0 pretty $gas_remained) ($($0 pretty $(($gas_remained - $gas))))"
  echo "seqno: $seqno => $($0 seqno $suffix)"
  # answer=N
  # read  -n 1 -p "Rewrite file '$prefix$suffix.pk' by '$new_owner_pk' (Y/N):" answer
  # echo " "
  # if [[ $answer == 'Y' || $answer == 'y' ]]; then
    echo "mv $prefix$suffix.pk => $prefix$suffix.pk.old"
    mv $prefix$suffix.pk $prefix$suffix.pk.tmp
    echo "cp '$new_owner_pk' => $prefix$suffix.pk"
    cp "$new_owner_pk" $prefix$suffix.pk
    mv $prefix$suffix.pk.tmp $prefix$suffix.pk.old
  # fi
elif [[ $cmd == reg ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  "$FIFT" -s $prefix-reg.fif $prefix$suffix $($0 seqno $suffix) && \
  $0 lc -c "sendfile $prefix$suffix-reg.boc"
  if [[ $? -ne 0 ]]; then exit $?; fi
  seqno=$($0 seqno $suffix)
  gas=$($0 gas $suffix)
  echo "Wait for a while ($SLEEPTIME secs) . . ."
  sleep $SLEEPTIME
  gas_remained=$($0 gas $suffix)
  echo "gas(nano): $($0 pretty $gas) => $($0 pretty $gas_remained) ($($0 pretty $(($gas_remained - $gas))))"
  echo "seqno: $seqno => $($0 seqno $suffix)"
elif [[ $cmd == dnsresolve ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  echo "ERR: TODO" >&2; exit 1
elif [[ $cmd == lc ]]; then
  shift
  echo "$LCLIENT" -C "$CONFIG" "$@"
  "$LCLIENT" -C "$CONFIG" "$@"
elif [[ $cmd == sponsor ]]; then
  shift
  opt=$1
  if [[ $opt == "-seqno" ]]; then
    $0 lc -c "runmethod $SPONSOR seqno" 2>&1 | tail -n 1 | grep -Po '\d+'
  else
    $0 lc -c last -c "getaccount $SPONSOR"
  fi
elif [[ $cmd == seqno ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  $0 get $suffix seqno  | tail -n 1 | grep -Po '\d+'
  # file=$prefix$suffix.addr
  # if [[ ! -e $file ]]; then
  #   echo "ERR: file '$file' not exists" >&2
  #   exit 1
  # fi
  # $0 lc -c "runmethod $($0 baddr $suffix) seqno" 2>&1 | tail -n 1 | grep -Po '\d+'
elif [[ $cmd == get ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  shift
  method=$1
  shift
  if [[ $method == "" ]]; then echo "ERR: METHOD expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  $0 lc -c "runmethod $($0 baddr $suffix) $method $@" 2>&1
elif [[ $cmd == upd ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  "$FUNC" -SPR -oauto/$prefix-updated.fif stdlib.fc $prefix-updated.fc && \
  "$FIFT" -s $prefix-upd.fif $prefix$suffix $($0 seqno $suffix) && \
  $0 lc -c "sendfile $prefix$suffix-upd.boc"
  if [[ $? -ne 0 ]]; then exit $?; fi
  seqno=$($0 seqno $suffix)
  gas=$($0 gas $suffix)
  echo "Wait for a while ($SLEEPTIME secs) . . ."
  sleep $SLEEPTIME
  gas_remained=$($0 gas $suffix)
  echo "gas(nano): $($0 pretty $gas) => $($0 pretty $gas_remained) ($($0 pretty $(($gas_remained - $gas))))"
  echo "seqno: $seqno => $($0 seqno $suffix)"
elif [[ $cmd == show ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  $0 lc -c last -c "getaccount $($0 baddr $suffix)"
  echo "gas remained(nano): $($0 pretty $($0 gas $suffix))"
  echo "seqno: $($0 seqno $suffix)"
elif [[ $cmd == gas ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  result=$($0 lc -c last -c "getaccount $($0 baddr $suffix)" 2>&1 | grep -Po 'amount:\(var_uint len:\d+ value:\d+\)\)' | cut -d: -f2- | cut -d: -f2- | cut -d: -f2-)
  echo ${result::-2}
elif [[ $cmd == baddr ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  "$FIFT" -s baddr.fif $prefix$suffix
elif [[ $cmd == naddr ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$prefix$suffix.addr
  if [[ ! -e $file ]]; then
    echo "ERR: file '$file' not exists" >&2
    exit 1
  fi
  "$FIFT" -s naddr.fif $prefix$suffix
elif [[ $cmd == fill-query ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  shift
  amount=$1
  [[ $amount ]] || amount=$amout_default
  "$FIFT" -s wallet.fif sponsor $($0 naddr $suffix) $($0 sponsor -seqno) $amount
elif [[ $cmd == fill ]]; then
  shift
  $0 fill-query "$@"
  $0 lc -c "sendfile wallet-query.boc"
  gas=$($0 gas $suffix)
  echo "Wait for a while ($SLEEPTIME secs) . . ."
  sleep $SLEEPTIME
  gas_remained=$($0 gas $suffix)
  echo "gas(nano): $($0 pretty $gas) => $($0 pretty $gas_remained) ($($0 pretty $(($gas_remained - $gas))))"
elif [[ $cmd == pretty ]]; then
  shift
  n=$1
  printf "%'.f\n" $n
elif [[ $cmd == ls ]]; then
  ls $prefix*.addr
elif [[ $cmd == pub ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  file=$suffix
  if [[ ! -e $file ]]; then
    file=$prefix$suffix.pk
    if [[ ! -e $file ]]; then
      echo "ERR: file '$file' not exists" >&2
      exit 1
    fi
  fi
  "$FIFT" -s pub.fif $file
elif [[ $cmd == owner ]]; then
  shift
  suffix=$1
  if [[ $suffix == "" ]]; then echo "ERR: SUFFIX expected" >&2; exit 1; fi
  pub=$($0 get $suffix owner 2>&1 | tail -n 1 | grep -Po '\d+')
  "$FIFT" -s owner.fif $pub
else
  echo "ERR: unexpected command '$1'"
  echo "consult with $0 help"
fi

