#!/usr/bin/env bash 

# extract argument from command line
EvalArgs()
{

  for arg in "$@"
  do
    if expr 'index' "$arg" '=' '>' '1' >/dev/null
    then
      case "$prefix" in
      1)
         eval "${NAME}_${arg}"
         if test $? != 0
         then
            echo "ERROR: ${NAME}_${arg} contains special character [$@]"
         fi
        ;;
      *)
        eval "${arg}"
        if test $? != 0
        then
           echo "ERROR: ${arg} contains special character [$@]"
        fi
        ;;
      esac
    fi
  done
  prefix=0
}

# Change path in strip to make it run from anywhere
FixPathBase () {
  if test ! -f ./$1/Fridu-$2.script
  then
     echo "Hoops !!! cannot open $BASE/$1/Fridu-$2.script"
     exit 1
  fi

  sed "s:FRIDU_BASE=.*$:FRIDU_BASE=$BASE:" <./$1/Fridu-$2.script >./$1/Fridu-$2.tmp
  mv -f ./$1/Fridu-$2.tmp ./$1/Fridu-$2.script
  chmod +x  ./$1/Fridu-$2.script
}


# -------- main start ---------

# init default values
test -f /etc/default/rcS   && sysconf=/etc/default
test -f /etc/sysconfig/syslog && sysconf=/etc/sysconfig
template=
bindir=/usr/sbin
cd `dirname $0`
BASE=`pwd`

# get argument from command line
EvalArgs "$@"

if test -z "$sysconf"
then
  echo "ERROR: no default sysconf found please add sysconf=/etc/xxxx in command line"
  exit 1
else
  mkdir -p $sysconf
  if test ! -d $sysconf
  then
    echo "ERROR: creation of sysconf=$sysconf failled"
    exit 1
  fi
fi

if test ! -z "$template"; then
  if test ! -e ./fw-rules/$template
  then
    echo "ERROR: ./fw-rules/$template not found [Please provide a valid rules-template with template=xxxx]"
    exit 1
  else
    echo "FWCONFIG=$template" > $sysconf/Fridu-default
  fi
fi

FixPathBase scripts firewall
rm -f $sysconf/Fridu-firewall 2>/dev/null
ln -s $BASE/fw-rules                       $sysconf/Fridu-firewall
ln -sf $BASE/scripts/Fridu-firewall.script  $BINDIR/.

#echo "installing startup strip in /etc/init.d/Fridu-firewall"
if test -e /etc/default/rcS
then
  ln -sf $BASE/tools/Fridu-firewall.deb  /etc/init.d/Fridu-firewall
  INITDIR=/etc/rc[2-5].d
else
  ln -sf $BASE/tools/Fridu-firewall.sle  /etc/init.d/Fridu-firewall
  INITDIR=/etc/rc.d/rc[2-5].d
fi

#echo "Autostart of Fridu-firewall for level 2-5"
for DIR in $INITDIR
do
  ln -sf /etc/init.d/Fridu-firewall      $DIR/S25Fridu-firewall
done

echo -------
echo "Installed Fridu-firewall"
echo "  rules template ->  $sysconf/Fridu-firewall"

if test -f $sysconf/Fridu-default; then
 .  $sysconf/Fridu-default
  echo "  rules default  ->  $sysconf/Fridu-firewall/$FWCONFIG"
else
  echo "  rules default  ->  none [use Fridu-firewall config=xxx]"
  echo "  NOTE: to set a default rule add:"
  echo "        FWCONFIG=myDefaultTemplate in $sysconf/Fridu-default"
fi

#echo "install Fridu-firewall in $bindir"
ln -sf $BASE/scripts/Fridu-firewall.script $bindir/Fridu-firewall

