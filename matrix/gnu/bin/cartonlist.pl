=head1 NAME
 
Carton::Doc::List - List dependencies tracked in the cpanfile.snapshot file
 
=head1 SYNOPSIS
 
  carton list
 
=head1 DESCRIPTION
 
List the dependencies and version information tracked in the
I<cpanfile.snapshot> file. This command by default displays the name of the
distribution (e.g. I<Foo-Bar-0.01>) in a flat list.
 
=head1 OPTIONS
 
=over 4
 
=item --distfile
 
Displays the list of distributions in a distfile format (i.e. C<AUTHOR/Dist-1.23.tar.gz>)
 
=back