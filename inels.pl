#!/usr/bin/perl

use IO::Socket::IP;
use Data::Dumper;
use Device::Modbus::RTU;
use Device::Modbus::RTU::Client;

my $modbus;

modbus_connect();

while(0) {
	#rele(124, 1);
	#rele(124, 0);
	rele(1, 1);
	rele(1, 0);
}



#exit;


while(1) {
    my $sock = IO::Socket::IP->new(
        PeerHost => "10.0.0.136",
        PeerPort => "1111",
        #             Proto     => IPPROTO_TCP,
    ) or next;

    printf "Connected to inels\n";

    my $sub = 0x02030000;

    while(1) { 
        my $data = $sock->recv(my $line, 4096);
	my @lines = split(/\n/, $line);
	foreach my $line (@lines) {
		chomp($line);
		printf "[%s] read: %s -> %s\n", scalar localtime(time()), $data, $line;
		# EVENT 05 0x020300aa 0x00000001

		#alarm(60);

		if ($line =~ /EVENT (05|06) 0x([0-9a-f]+) 0x([0-9a-f]+)/) {
			#print "1: $1 2: $2/".hex($2)." 3: $3/".hex($3)."\n";
			#printf "[%s] read: %s -> %s\n", scalar localtime(time()), $data, $line;

			my $x = hex($2) - $sub;
			my $stav;
			$stav = 0 if $1 eq "06";
			$stav = 1 if $1 eq "05";
			rele($x, $stav) if defined $stav;
		}

		if ($line =~ /EVENT (05|06) ([0-9]+),([0-9]+)/) {
			#print "1: $1 2: $2/".hex($2)." 3: $3/".hex($3)."\n";
			#printf "[%s] read: %s -> %s\n", scalar localtime(time()), $data, $line;

			my $x = $2;#) - $sub;
			my $stav;
			$stav = 0 if $1 eq "06";
			$stav = 1 if $1 eq "05";
			#rele($x, $stav) if defined $stav;
		}
	}
    }


}

sub rele {
    my $ktere = shift;
    my $co = shift;
    my $modul = 1;

    my $ktere_in = $ktere;
    while($ktere > 0x10) {
        $ktere -= 0x10;
        $modul++;
    }


    if ($modul > 0 and $modul <= 8) {
	printf "[%s] modul: %s ktere: %s co: %s (%d)\n", scalar localtime(time()), $modul, $ktere, $co, $ktere_in;
        modbus_write($modul, $ktere, $co ? 0x100 : 0x200);
    } else {
	printf "[%s] modul mimo rozsah: %s ktere: %s co: %s\n", scalar localtime(time()), $modul, $ktere, $co;
    }
}

sub modbus_connect {
    $modbus = Device::Modbus::RTU::Client->new(
        port     => '/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_A50285BI-if00-port0',
        #/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_A50285BI-if00-port0',
	#baudrate => 4800,
	#baudrate => 9600,
	baudrate => 19200,
        parity   => 'even',
        timeout => 100,
    ) or die $!;
}


sub modbus_write {
    my $modul = shift;
    my $ktere = shift;
    my $value = shift;

    my $req1 = $modbus->write_single_register(
        unit 	=> $modul,
        address => $ktere,
	value 	=> $value,
    );
    eval {
	    $modbus->send_request($req1);
	    my $adu = $modbus->receive_response;

	    if ($adu->success) {
		    printf "[%s] ok\n", scalar localtime(time());
		    $values = $adu->values;
	    } else {
		    printf "[%s] not ok\n", scalar localtime(time());
	    }
    };

    #my $adu = $modbus->receive_response;

    #print Dumper($adu);

    #    unit     => 1,
    #    address  => 0x5000,
    #    quantity => 0x32,
    #);

}

