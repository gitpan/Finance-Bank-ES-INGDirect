package Finance::Bank::ES::INGDirect;

use strict;
use warnings;
use Carp;
use WWW::Mechanize;
our $VERSION='0.01';


# hackery for https proxy support, inspired by Finance::Bank::Barclays
# thanks Dave Holland!
my $https_proxy=$ENV{https_proxy};
delete $ENV{https_proxy} if($https_proxy);
our $browser = WWW::Mechanize->new(env_proxy=>1);
$browser->env_proxy;     # Load proxy settings (but not the https proxy)
$ENV{https_proxy}=$https_proxy if($https_proxy);

sub ver_saldos {
	my ($class,%opts)=@_;
	croak "Debe proporcionar un Documento" unless exists $opts{documento};
	croak "Debe proporcionar una fecha de nacimiento DD/MM/AAAA" unless exists $opts{fecha_nacimiento};
	croak "Debe proporcionar un PIN" unless exists $opts{pin};
        $opts{tipo_documento}="NIF" unless exists $opts{tipo_documento};
	my $base="https://www.ingdirect.es/WebTransactional/Transactional/clientes/access/";
	my %tipodoc=(NIF => 0,
		     Pasaporte=> 1,
		     TarjetaResidencia=> 2);		
	my $cbodocument=$tipodoc{NIF};
	my $id=$opts{documento};
	my ($birthDay,$birthMonth,$birthYear)=split("/",$opts{fecha_nacimiento});	
	my $pine=$opts{pin};
	my @pin=split //,$pine;	
	my $entrada = 	$base .'cappin.asp?cbodocument='. $cbodocument
			      .'&id='. $id 
			      .'&birthDay='. $birthDay 
		              .'&birthMonth='. $birthMonth 
		              .'&birthYear='. $birthYear;		
        my $re='name="txt_Pin(\d*)"';
        my $browser = WWW::Mechanize->new();
        $browser->agent_alias("Windows IE 6");
        my $r=$browser->get($entrada);
        croak "Can't open INGDirect entrance" unless $browser->res->is_success();
        my $datos=$r->content;
        $browser->form('LoginForm');
        while ($datos=~m{$re}gs){
		$browser->field("txt_Pin$1", $pin[$1-1]);
	}
	$r=$browser->submit();
	croak "Can't open INGDirect login" unless $browser->res->is_success();
	$r=$browser->follow_link(n=>2); #Frames
	croak "Can't open Lower Frame" unless $browser->res->is_success();
	$r=$browser->follow_link(url_regex => qr{position/globalinf_all_cuentas.asp}i); #Saldos productos
	croak "Can't open balances" unless $browser->res->is_success();
	my $chorro='<TD STYLE="FONT: 10px Arial, Helvetica, sans-serif;" width="150" align="left" valign="middle">(.*?)</TD>.*?<TD STYLE="FONT: 10px Arial, Helvetica, sans-serif;" width="150" align="center" valign="middle">(\d*?)</TD>.*?<TD align="right" STYLE="FONT: 10px Arial, Helvetica, sans-serif;" width="112">&nbsp;(.*?)&nbsp; €&nbsp;</TD>';
	$datos=$r->content;
	my @cuentas=();
	while($datos=~m{$chorro}gs){
		push @cuentas,( { descripcion =>$1,
				  numero => $2,
				  saldo => $3 } );
	}
	return @cuentas;
}
1;
__END__
# Documentation

=head1 NAME

Finance::Bank::ES::INGDirect - Check your INGDirect bank accounts from Perl 

=head1 SYNOPSIS
my $nif="11111111B";
my $fenac="12/12/1212";
my $pin="929999";
my @cuentas=Finance::Bank::ES::INGDirect->ver_saldos(	documento=>$nif,
							fecha_nacimiento=>$fenac,
							pin=> $pin);
foreach (@cuentas) {
	print "Desc: ".$_->{descripcion}." Num: ".$_->{numero}." Saldo: ".$_->{saldo}."\n";
}

=head1 DESCRIPTION

Check your INGDirect bank accounts from Perl.
It only checks balances, but future versions will allow you to do more things.
Chequea el saldo de tus cuentas en INGDirect con Perl.
Ahora solamente chequea saldos, pero en futuras versiones se permitiran mas cosas.
Me encantaria saber que usas el modulo! Enviame un mail!

=head2 EXPORT

None by default.

=head2 REQUIRE

WWW::Mechanize

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

Ten cuidado con el modulo. Examina el fuente para que veas que no hago 
cosas raras.
Pasalo a traves de un proxy para que veas que no me conecto a sitios raros.

=head1 NICE EXAMPLE WITH TK

use Finance::Bank::ES::INGDirect;
use Tk;
use strict;

my $main = MainWindow->new;
$main->Label(-text => 'NIF')->pack;
my $nif = $main->Entry(-width => 10);
$nif->pack;
$main->Label(-text => 'Fecha Nacimiento(DD/MM/AAAA)')->pack;
my $fenac = $main->Entry(-width => 10);
$fenac->pack;
$main->Label(-text => 'PIN')->pack;
my $pin = $main->Entry(-width => 7, -show => '*' );
$pin->pack;
$main->Label(-text => 'Datos')->pack;
my $d = $main->MListbox(  -columns =>     [[-text=>'Descripcion'],
					   [-text=>'Numero'],
					   [-text=>'Saldo']]);
$d->pack;
$main->Button(-text => 'Conectar!',
              -command => sub{ver_saldos($nif->get, $fenac->get, $pin->get)}
              )->pack;
MainLoop;

sub ver_saldos {
	my ($nif, $fenac, $pin) = @_;
	my @cuentas=Finance::Bank::ES::INGDirect->ver_saldos(	documento=>$nif,
								fecha_nacimiento=>$fenac,
								pin=> $pin);
	foreach (@cuentas) {
		$d->insert(0,[$_->{descripcion},$_->{numero},$_->{saldo}]);
	}
}


=head1 SEE ALSO

Finance::Bank::*

=head1 AUTHOR

Bruno Diaz Briere C<bruno.diaz@gmx.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Bruno Diaz Briere

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
