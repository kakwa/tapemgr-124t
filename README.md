tapemgr-124t
============

Utilities and library to manage a Dell PowerVault 124T from command line

License
-------

MIT

Why
---

The PowerVault 124T is a nice tape autoloader, but there are some annoying things with it.

In particular, not having the possibility to eject or load tapes other than through the LCD menu or the web administration is a pain in the a**.

It's even more annoying when you try to automate your backup management as much as possible (backups are already boring enough).
Simple use cases like detecting tapes that are full in Bacula and automaticaly ejecting them is impossible to automate.

Tapemgr-124t utilities offers a way to expose most of the tape operations from the LCD menu to the command line. The perl library can also be used.

Dependancies
------------

* WWW::Mechanize
* HTML::TreeBuilder
* Getopt::Long

Command line
------------

Tapemgr-124t comes with 4 utilities:

```bash
# eject a tape (you still have to pick it up from the mail slot, this script will not put it on a shelf for you)
$ 124t-eject -H <tape recoreder ip/host> -u <login> -p <password> -s <slot id>

# load a tape, if -s is specified, will load tape in this slot, otherwise in first free slot
$ 124t-load  -H <tape recoreder ip/host> -u <login> -p <password> [-s <slot id>]

# move tape from slot1 to slot2
$ 124t-move -H <tape recoreder ip/host> -u <login> -p <password> -s <slot1> -d <slot2>

# status of the slots
$ 124t-status -H <tape recoreder ip/host> -u <login> -p <password> [-n]
```

See --help for more details.

Library
-------

```perl

use TAPEMGR_124T::Actions;

# init the module
my $tape = TAPEMGR_124T::Actions->new(
    host     => '192.168.0.1',
    login    => 'admin',
    password => 'password',
);

# move a tape from slot 6 to slot 4
$tape->move_tape(6, 4);

# load a tape from mailslot in the first available slot
$tape->load_tape();

# load a tape from mailslot in slot 3
$tape->load_tape_slot(3);

# eject tape from slot 4
$tape->eject_tape(4);

# convert a slot id/number to a slot name
print id2slot(17);

# convert a slot name to slot id/number
print id2slot(mailslot);

# display the slots status
my %status = $tape->slots_status();
foreach(sort {$a <=> $b} keys(%status)){
   my $slot_name = TAPEMGR_124T::Actions::id2slot(${_});
   my $slot_content = $status{$_};
   print "$slot_name: $status{$_}\n";
}
```

