package TAPEMGR_124T::Actions;

our $VERSION = '0.0.1';

=head1 

NAME TAPEMGR_124T::Actions - Package to manage Dell 124 T powervault tape recorder 

=head1 SYNOPSIS

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

=cut

use warnings;
use strict;
use WWW::Mechanize;
use HTML::TreeBuilder;

my %slots = (
    'slot1'    => 1 , 
    'slot2'    => 2 , 
    'slot3'    => 3 , 
    'slot4'    => 4 , 
    'slot5'    => 5 , 
    'slot6'    => 6 , 
    'slot7'    => 7 , 
    'slot8'    => 8 , 
    'slot9'    => 9 , 
    'slot10'   => 10,
    'slot11'   => 11,
    'slot12'   => 12,
    'slot13'   => 13,
    'slot14'   => 14,
    'slot15'   => 15,
    'slot16'   => 16,
    'drive'    => 17,
    'mailslot' => 18,
    'picker'   => 19,
);

my %reverse_slots = reverse %slots;

# create the "object"
sub new {
    my($class, %args) = @_;
    my $self = bless({}, $class);
    $self->{host} = $args{host};
    $self->{login} = $args{login};
    $self->{password} = $args{password};
    return $self;
}

# convert slot name to slot number
sub slot2id{
    my $slot = shift;
    if ($slots{$slot}){
        return $slots{$slot};
    }
    else{
        die 'not a slot name'; 
    }
}

sub id2slot{
    my $slot = shift;
    if ($reverse_slots{$slot}){
        return $reverse_slots{$slot};
    }
    else{
        die 'not a slot id'; 
    }
}



# get the first empty 
sub get_empty_slot{
    my $self     = shift;
    my %status = $self->slots_status();
    foreach(keys(%status)){
        if ($status{$_} eq 'Empty'){
            return $_;
        }
    }
    die 'unable to find an empty slot';
}
# little helper to extract slot name from html page
# slot name is recovered from from_to(<slot name>) javascript calls
sub extract_slot{
    my $call = shift;
    if($call =~ /from_to.(.*)./) {
        return $1;
    }
    else
    { 
        die 'unable to match a slot name';
    }
}

# get the status of each slots
# return a hash (<slotid> => <content>)
sub slots_status{
    my $self     = shift;
    my $host     = $self->{host};
    my $login    = $self->{login};
    my $password = $self->{password};

    # we initialize mechaniwe
    my $mech = WWW::Mechanize->new(autocheck => 1);
    $mech->credentials(${login}, ${password});
    my $url = "http://${host}/commands.html";

    $mech->agent_alias( 'Windows IE 6' );

    # we get the page
    # the interesting stuff are the following img tags:
    # <img src="tape.gif" width="60" height="24" alt="000015L6" title="000015L6" onClick="from_to(slot5)">
    # we recover the slot from the onClick attribute and the content from the title attribute.
    $mech->get( $url );

    # we parse the html pages
    #
    my $root = HTML::TreeBuilder->new();
    $root->parse($mech->content);
    my $img;
    my %status = ();
    # loop on img tags with 'onClick' attributes
    foreach ($root->look_down(
        _tag => 'img',
        sub { defined($_[0]->attr('onClick')) }
    )){
        if (defined($_->attr('onClick'))){
            my $call = $_->attr('onClick');
            my $slotid = slot2id(extract_slot($call));
            my $content = $_->attr('title');
            $status{$slotid} = $content;
            #print "$slotid $content\n";
        }
    };
    return %status;
}

# move tape from one slot to the other
sub move_tape{
    my $self      = shift;
    my $from      = shift;
    my $to        = shift;
    my $dontcheck = shift;
    my $host      = $self->{host};
    my $login     = $self->{login};
    my $password  = $self->{password};

    if (not defined($dontcheck) or not($dontcheck)){
       my %status = $self->slots_status();
       if ($status{$from} eq 'Empty'){
           die 'source slot empty';
       }
       if ($status{$to} ne 'Empty'){
           die 'destination slot not empty';
       }
    }

    #we initialize the form
    my $mech = WWW::Mechanize->new(autocheck => 1);
    $mech->credentials(${login}, ${password});
    my $url = "http://${host}/commands.html";

    $mech->agent_alias( 'Windows IE 6' );

    #we get the form
    $mech->get( $url );

    #and we need to set this header 
    $mech->add_header('Accept-Language' => 'fr-FR');

    #we submit the form
    $mech->submit_form(
        form_name => 'move',
        fields    => { 
            from       => $from,
            to         => $to,
        },
    );
    #we return the raw html
    return $mech->content;
}

# load a tape from the mail slot to the first empty slot
sub load_tape{
    my $self     = shift;
    my $slotid   = $self->get_empty_slot();
    $self->move_tape(18, $slotid, 1);
}

# load a tape from the mail slot to the specified slot
sub load_tape_slot{
    my $self     = shift;
    my $slotid   = shift; 
    $self->move_tape(18, $slotid);
}

# eject tape from the specified slot
sub eject_tape{
    my $self     = shift;
    my $slotid   = shift; 
    $self->move_tape($slotid, 18);
}

1;
