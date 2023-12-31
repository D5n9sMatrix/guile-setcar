package PDF::Reuse;
 
use 5.006;
use strict;
use warnings;
 
require    Exporter;
require    Digest::MD5;
use autouse 'Carp' => qw(carp
                         cluck
                         croak);
 
use Compress::Zlib qw(compress inflateInit);
 
use autouse 'Data::Dumper'   => qw(Dumper);
use AutoLoader qw(AUTOLOAD);
 
our $VERSION = '0.39';
our @ISA     = qw(Exporter);
our @EXPORT  = qw(prFile
                  prPage
                  prId
                  prIdType
                  prInitVars
                  prEnd
                  prExtract
                  prForm
                  prImage
                  prAltJpeg
                  prJpeg
                  prDoc
                  prDocForm
                  prFont
                  prFontSize
                  prGraphState
                  prGetLogBuffer
                  prAdd
                  prBar
                  prText
                  prDocDir
                  prLogDir
                  prLog
                  prVers
                  prCid
                  prJs
                  prInit
                  prField
                  prTouchUp
                  prCompress
                  prMbox
                  prBookmark
                  prStrWidth
                  prLink
                  prTTFont
                  prSinglePage);
 
our ($utfil, $slutNod, $formCont, $imSeq, $duplicateInits, $page, $sidObjNr, $sida,
    $interActive, $NamesSaved, $AARootSaved, $AAPageSaved, $root,
    $AcroFormSaved, $id, $ldir, $checkId, $formNr, $imageNr,
    $filnamn, $interAktivSida, $taInterAkt, $type, $runfil, $checkCs,
    $confuseObj, $compress, $pos, $fontNr, $objNr, $docProxy,
    $defGState, $gSNr, $pattern, $shading, $colorSpace, $totalCount);
 
our (@kids, @counts, @formBox, @objekt, @parents, @aktuellFont, @skapa,
    @jsfiler, @inits, @bookmarks, @annots);
 
our ( %old, %oldObject, %resurser, %form, %image, %objRef, %nyaFunk, %fontSource,
     %sidFont, %sidXObject, %sidExtGState, %font, %intAct, %fields, %script,
     %initScript, %sidPattern, %sidShading, %sidColorSpace, %knownToFile,
     %processed, %embedded, %dummy, %behandlad, %unZipped, %links, %prefs);
 
our $stream  = '';
our $idTyp   = '';
our $ddir    = '';
our $log     = '';
 
#########################
# Konstanter för objekt
#########################
 
use constant   oNR        => 0;
use constant   oPOS       => 1;
use constant   oSTREAMP   => 2;
use constant   oKIDS      => 3;
use constant   oFORM      => 4;
use constant   oIMAGENR   => 5;
use constant   oWIDTH     => 6;
use constant   oHEIGHT    => 7;
use constant   oTYPE      => 8;
use constant   oNAME      => 9;
 
###################################
# Konstanter för formulär
###################################
 
use constant   fOBJ       => 0;
use constant   fRESOURCE  => 1;
use constant   fBBOX      => 2;
use constant   fIMAGES    => 3;
use constant   fMAIN      => 4;
use constant   fKIDS      => 5;
use constant   fNOKIDS    => 6;
use constant   fID        => 7;
use constant   fVALID     => 8;
 
####################################
# Konstanter för images
####################################
 
use constant   imWIDTH     => 0;
use constant   imHEIGHT    => 1;
use constant   imXPOS      => 2;
use constant   imYPOS      => 3;
use constant   imXSCALE    => 4;
use constant   imYSCALE    => 5;
use constant   imIMAGENO   => 6;
 
#####################################
# Konstanter för interaktiva objekt
#####################################
 
use constant   iNAMES     => 1;
use constant   iACROFORM  => 2;
use constant   iAAROOT    => 3;
use constant   iANNOTS    => 4;
use constant   iSTARTSIDA => 5;
use constant   iAAPAGE    => 6;
 
#####################################
# Konstanter för fonter
#####################################
 
use constant   foREFOBJ     => 0;
use constant   foINTNAMN    => 1;
use constant   foEXTNAMN    => 2;
use constant   foORIGINALNR => 3;
use constant   foSOURCE     => 4;
use constant   foTYP        => 5;
use constant   foFONTOBJ    => 6;
 
##########
# Övrigt
##########
 
use constant IS_MODPERL => $ENV{MOD_PERL}; # For mod_perl 1.
                                           # For mod_perl 2 pass $r to prFile()
our $touchUp  = 1;
 
our %stdFont =
       ('Times-Roman'           => 'Times-Roman',
        'Times-Bold'            => 'Times-Bold',
        'Times-Italic'          => 'Times-Italic',
        'Times-BoldItalic'      => 'Times-BoldItalic',
        'Courier'               => 'Courier',
        'Courier-Bold'          => 'Courier-Bold',
        'Courier-Oblique'       => 'Courier-Oblique',
        'Courier-BoldOblique'   => 'Courier-BoldOblique',
        'Helvetica'             => 'Helvetica',
        'Helvetica-Bold'        => 'Helvetica-Bold',
        'Helvetica-Oblique'     => 'Helvetica-Oblique',
        'Helvetica-BoldOblique' => 'Helvetica-BoldOblique',
        'Symbol'                => 'Symbol',
        'ZapfDingbats'          => 'ZapfDingbats',
        'TR'  => 'Times-Roman',
        'TB'  => 'Times-Bold',
        'TI'  => 'Times-Italic',
        'TBI' => 'Times-BoldItalic',
        'C'   => 'Courier',
        'CB'  => 'Courier-Bold',
        'CO'  => 'Courier-Oblique',
        'CBO' => 'Courier-BoldOblique',
        'H'   => 'Helvetica',
        'HB'  => 'Helvetica-Bold',
        'HO'  => 'Helvetica-Oblique',
        'HBO' => 'Helvetica-BoldOblique',
        'S'   => 'Symbol',
        'Z'   => 'ZapfDingbats');
 
our $genLowerX    = 0;
our $genLowerY    = 0;
our $genUpperX    = 595,
our $genUpperY    = 842;
our $genFont      = 'Helvetica';
our $fontSize     = 12;
 
keys(%resurser)  = 10;
 
sub prFont
{   my $nyFont = shift;
    my ($intnamn, $extnamn, $objektnr, $oldIntNamn, $oldExtNamn);
 
    if (! $pos)
    {  errLog("No output file, you have to call prFile first");
    }
    $oldIntNamn = $aktuellFont[foINTNAMN];
    $oldExtNamn = $aktuellFont[foEXTNAMN];
    if ($nyFont)
    {  ($intnamn, $extnamn, $objektnr) = findFont($nyFont);
    }
    else
    {   $intnamn = $aktuellFont[foINTNAMN];
        $extnamn = $aktuellFont[foEXTNAMN];
    }
    if ($runfil)
    {  $log .= "Font~$nyFont\n";
    }
    if (wantarray)
    {  return ($intnamn, $extnamn, $oldIntNamn, $oldExtNamn, \%font);
    }
    else
    {  return $intnamn;
    }
}
 
sub prFontSize
{   my $fSize = shift || 12;
    my $oldFontSize = $fontSize;
    if ($fSize =~ m'\d+\.?\d*'o)
    { $fontSize = $fSize;
      if ($runfil)
      {  $log .= "FontSize~$fontSize\n";
      }
    }
    if (! $pos)
    {  errLog("No output file, you have to call prFile first");
    }
 
    return ($fontSize, $oldFontSize);
}
 
sub prFile
{  if ($pos)
   {  prEnd();
      close UTFIL;
   }
   %prefs = ();
   my $param = shift;
   if (ref($param) eq 'HASH')
   {  $filnamn  = '-';
      for (keys %{$param})
      {   my $key = lc($_);
          if ($key eq 'name')
          {  $filnamn = $param->{$_}; }
          elsif (($key eq 'hidetoolbar')
          ||     ($key eq 'hidemenubar')
          ||     ($key eq 'hidewindowui')
          ||     ($key eq 'fitwindow')
          ||     ($key eq 'centerwindow'))
          {  $prefs{$key} = $param->{$_};
          }
      }
   }
   else
   {  $filnamn  = $param || '-';
      $prefs{hidetoolbar}  = $_[1]  if defined $_[1];
      $prefs{hidemenubar}  = $_[2]  if defined $_[2];
      $prefs{hidewindowui} = $_[3]  if defined $_[3];
      $prefs{fitwindow}    = $_[4]  if defined $_[4];
      $prefs{centerwindow} = $_[5]  if defined $_[5];
   }
   my $kortNamn;
   if ($filnamn ne '-')
   {   my $ri  = rindex($filnamn,'/');
       if ($ri > 0)
       {  $kortNamn = substr($filnamn, ($ri + 1));
          $utfil = $ddir ? $ddir . $kortNamn : $filnamn;
       }
       else
       {  $utfil = $ddir ? $ddir . $filnamn : $filnamn;
       }
       $ri = rindex($utfil,'/');
       if ($ri > 0)
       {   my $dirdel = substr($utfil,0,$ri);
           if (! -e $dirdel)
           {  mkdir $dirdel || errLog("Couldn't create dir $dirdel, $!");
           }
       }
       else
       {  $ri = rindex($utfil,'\\');
          if ($ri > 0)
          {   my $dirdel = substr($utfil,0,$ri);
              if (! -e $dirdel)
              {  mkdir $dirdel || errLog("Couldn't create dir $dirdel, $!");
              }
          }
       }
   }
   else
   {   $utfil = $filnamn;
   }
 
   my $utfil_ref = ref $utfil;
   if ($utfil_ref and ($utfil_ref eq 'Apache2::RequestRec') or
                      ($utfil_ref eq 'Apache::RequestRec') ) # mod_perl 2
   { tie *UTFIL, $utfil;
   }
   elsif (IS_MODPERL && $utfil eq '-')     # mod_perl 1
   { tie *UTFIL, 'Apache';
   }
   elsif ($utfil_ref and $utfil_ref eq 'IO::String')
   { tie *UTFIL, $utfil;
   }
   else
   { open (UTFIL, ">$utfil") || errLog("Couldn't open file $utfil, $!");
   }
   binmode UTFIL;
   my $utrad = "\%PDF-1.4\n\%\â\ã\Ï\Ó\n";
 
   $pos   = syswrite UTFIL, $utrad;
 
   if (defined $ldir)
   {   if ($utfil eq '-')
       {   $kortNamn = 'stdout';
       }
       if ($kortNamn)
       {  $runfil = $ldir . $kortNamn  . '.dat';
       }
       else
       {  $runfil = $ldir . $filnamn  . '.dat';
       }
       open (RUNFIL, ">>$runfil") || errLog("Couldn't open logfile $runfil, $!");
       $log .= "Vers~$VERSION\n";
   }
 
 
   @parents     = ();
   @kids        = ();
   @counts      = ();
   @objekt      = ();
   $objNr       = 2; # Reserverat objekt 1 för root och 2 för initial sidnod
   $parents[0]  = 2;
   $page        = 0;
   $formNr      = 0;
   $imageNr     = 0;
   $fontNr      = 0;
   $gSNr        = 0;
   $pattern     = 0;
   $shading     = 0;
   $colorSpace  = 0;
   $sida        = 0;
   %font        = ();
   %resurser    = ();
   %fields      = ();
   @jsfiler     = ();
   @inits       = ();
   %nyaFunk     = ();
   %objRef      = ();
   %knownToFile = ();
   @aktuellFont = ();
   %old         = ();
   %behandlad   = ();
   @bookmarks   = ();
   %links       = ();
   undef $defGState;
   undef $interActive;
   undef $NamesSaved;
   undef $AARootSaved;
   undef $AcroFormSaved;
   $checkId    = '';
   undef $duplicateInits;
   undef $confuseObj;
   $fontSize  = 12;
   $genLowerX = 0;
   $genLowerY = 0;
   $genUpperX = 595,
   $genUpperY = 842;
 
   prPage(1);
   $stream = ' ';
   if ($runfil)
   {  $filnamn = prep($filnamn);
      $log .= "File~$filnamn";
      $log .= (exists $prefs{hidetoolbar}) ? "~$prefs{hidetoolbar}" : '~';
      $log .= (exists $prefs{hidemenubar}) ? "~$prefs{hidemenubar}" : '~';
      $log .= (exists $prefs{hidewindowui}) ? "~$prefs{hidewindowui}" : '~';
      $log .= (exists $prefs{fitwindow}) ? "~$prefs{fitwindow}" : '~';
      $log .= (exists $prefs{centerwindow}) ? "~$prefs{centerwindow}" : "~\n";
   }
   1;
}
 
 
sub prPage
{  my $noLogg = shift;
   if ((defined $stream) && (length($stream) > 0))
   { skrivSida();
   }
 
   $page++;
   $objNr++;
   $sidObjNr = $objNr;
 
   #
   # Resurserna nollställs
   #
 
   %sidXObject    = ();
   %sidExtGState  = ();
   %sidFont       = ();
   %sidPattern    = ();
   %sidShading    = ();
   %sidColorSpace = ();
   @annots        = ();
 
   undef $interAktivSida;
   undef $checkCs;
   if (($runfil) && (! $noLogg))
   {  $log .= "Page~\n";
       print RUNFIL $log;
       $log = '';
   }
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
   1;
 
}
 
sub prText
{ my $xPos  = shift;
  my $yPos  = shift;
  my $TxT   = shift;
  my $align = shift || 'left';
  my $rot   = shift || '0';
 
  my $width = 0;
  my $x_align_offset = 0;
 
  if (! defined $TxT)
  {  $TxT = '';
  }
 
  if (($xPos !~ m'\-?[\d\.]+'o) || (! defined $xPos))
  { errLog("Illegal x-position for text: $xPos");
  }
  if (($yPos !~ m'\-?[\d\.]+'o) || (! defined $yPos))
  { errLog("Illegal y-position for text: $yPos");
  }
 
  if ($runfil)
  {   my $Texten   = prep($TxT);
      $log .= "Text~$xPos~$yPos~$Texten~$align~$rot\n";
  }
 
  if (length($stream) < 3)
  {  $stream = "0 0 0 rg\n 0 g\nf\n";
  }
 
 
  if (! $aktuellFont[foINTNAMN])
  {  findFont();
  }
  my $Font        = $aktuellFont[foINTNAMN];        # Namn i strömmen
  $sidFont{$Font} = $aktuellFont[foREFOBJ];
  my $fontname    = $aktuellFont[foEXTNAMN];
  my $ttfont      = $font{$fontname} ? $font{$fontname}[foFONTOBJ] : undef;
 
 
  # define what the offset for alignment is
 
  if ((wantarray)
  || ($align ne 'left'))
  {  $width = prStrWidth($TxT, $aktuellFont[foEXTNAMN], $fontSize);
     if($align eq 'right')
     {  $x_align_offset = - $width;
     }
     elsif ($align eq 'center')
     {  $x_align_offset = -$width / 2;
     }
  }
 
  $TxT =~ s|\(|\\(|gos;
  $TxT =~ s|\)|\\)|gos;
 
 
  unless($rot)
  {  $stream .= "\nBT /$Font $fontSize Tf ";
     if($ttfont)
     {   $TxT = $ttfont->encode_text($TxT);
         $stream .= $xPos+$x_align_offset . " $yPos Td $TxT Tj ET\n";
     }
     elsif (!$aktuellFont[foTYP])
     {   $stream .= $xPos+$x_align_offset . " $yPos Td \($TxT\) Tj ET\n";
     }
     else
     {   my $text;
         $TxT =~ s/\\(\d\d\d)/chr(oct($1))/eg;
         for (unpack ('C*', $TxT))
         {  $text .= sprintf("%04x", ($_ - 29));
         }
         $stream .= $xPos+$x_align_offset . " $yPos Td \<$text\> Tj ET\n";
     }
  }
  else
  {  if ($rot =~ m'q(\d)'oi)
      {  if ($1 eq '1')
         {  $rot = 270;
         }
         elsif ($1 eq '2')
         {  $rot = 180;
         }
         else
         {  $rot = 90;
         }
      }
 
     my $radian = sprintf("%.6f", $rot / 57.2957795);    # approx.
     my $Cos    = sprintf("%.6f", cos($radian));
     my $Sin    = sprintf("%.6f", sin($radian));
     my $negSin = $Sin * -1;
 
     my $encText = $ttfont ? $ttfont->encode_text($TxT) : "\($TxT\)";
     $stream .=   "\nq\n"                           # enter a new stack frame
                # . "/Gs0 gs\n"                             # reset graphic mode
                . "$Cos $Sin $negSin $Cos $xPos $yPos cm\n" # rotation/translation in the CM
                . "\nBT /$Font $fontSize Tf "
                . "$x_align_offset 0 Td $encText Tj ET\n"   # text @ 0,0
                . "Q\n";                                    # close the stack frame
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
 
 
  if (wantarray)
  {  # return a new "cursor" position...
 
     if($rot==0)
     {  if($align eq 'left')
        {   return ($xPos, $xPos + $width);
        }
        elsif($align eq 'center')
        { return ($xPos - $x_align_offset, $xPos + $x_align_offset);
        }
        elsif($align eq 'right')
        {   return ($xPos - $width, $xPos);
        }
 
     }
     else
     {   # todo
         # we could some trigonometry to return an x/y point
         return 1;
     }
  }
  else
  {  return 1;
  }
 
}
 
 
sub prAdd
{  my $contents = shift;
   $stream .= "\n$contents\n";
   if ($runfil)
   {   $contents = prep($contents);
       $log .= "Add~$contents\n";
   }
   $checkCs = 1;
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
   1;
}
 
##########################
# Ett grafiskt "formulär"
##########################
 
sub prForm
{ my ($sidnr, $adjust, $effect, $tolerant, $infil, $x, $y, $size, $xsize,
      $ysize, $rotate);
  my $param = shift;
  if (ref($param) eq 'HASH')
  {  $infil    = $param->{'file'};
     $sidnr    = $param->{'page'} || 1;
     $adjust   = $param->{'adjust'} || '';
     $effect   = $param->{'effect'} || 'print';
     $tolerant = $param->{'tolerant'} || '';
     $x        = $param->{'x'} || 0;
     $y        = $param->{'y'} || 0;
     $rotate   = $param->{'rotate'} || 0;
     $size     = $param->{'size'} || 1;
     $xsize    = $param->{'xsize'} || 1;
     $ysize    = $param->{'ysize'} || 1;
  }
  else
  {  $infil    = $param;
     $sidnr    = shift || 1;
     $adjust   = shift || '';
     $effect   = shift || 'print';
     $tolerant = shift || '';
     $x        = shift || 0;
     $y        = shift || 0;
     $rotate   = shift || 0;
     $size     = shift || 1;
     $xsize    = shift || 1;
     $ysize    = shift || 1;
  }
 
  my $refNr;
  my $namn;
  $type = 'form';
  my $fSource = $infil . '_' . $sidnr;
  if (! exists $form{$fSource})
  {  $formNr++;
     $namn = 'Fm' . $formNr;
     $knownToFile{$fSource} = $namn;
     my $action;
     if ($effect eq 'load')
     {  $action = 'load'
     }
     else
     {  $action = 'print'
     }
     $refNr         = getPage($infil, $sidnr, $action);
     if ($refNr)
     {  $objRef{$namn} = $refNr;
     }
     else
     {  if ($tolerant)
        {  if ((defined $refNr) && ($refNr eq '0'))   # Sidnumret existerar inte, men ok
           {   $namn = '0';
           }
           else
           {   undef $namn;   # Sidan kan inte användas som form
           }
        }
        elsif (! defined $refNr)
        {  my $mess = "$fSource can't be used as a form. See the documentation\n"
                    . "under prForm how to concatenate streams\n";
           errLog($mess);
        }
        else
        {  errLog("File : $infil  Page: $sidnr  doesn't exist");
        }
     }
  }
  else
  {  if (exists $knownToFile{$fSource})
     {  $namn = $knownToFile{$fSource};
     }
     else
     {  $formNr++;
        $namn = 'Fm' . $formNr;
        $knownToFile{$fSource} = $namn;
     }
     if (exists $objRef{$namn})
     {  $refNr = $objRef{$namn};
     }
     else
     {  if (! $form{$fSource}[fVALID])
        {  my $mess = "$fSource can't be used as a form. See the documentation\n"
                    . "under prForm how to concatenate streams\n";
           if ($tolerant)
           {  cluck $mess;
              undef $namn;
           }
           else
           {  errLog($mess);
           }
        }
        elsif ($effect ne 'load')
        {  $refNr         =  byggForm($infil, $sidnr);
           $objRef{$namn} =  $refNr;
        }
     }
  }
  my @BBox = @{$form{$fSource}[fBBOX]} if ($refNr);
  if (($effect eq 'print') && ($form{$fSource}[fVALID]) && ($refNr))
  {   if (! defined $defGState)
      { prDefaultGrState();
      }
 
      if ($adjust)
      {   $stream .= "q\n";
          $stream .= fillTheForm(@BBox, $adjust);
          $stream .= "\n/Gs0 gs\n";
          $stream .= "/$namn Do\n";
          $stream .= "Q\n";
      }
      elsif (($x) || ($y) || ($rotate) || ($size != 1)
                  || ($xsize != 1)     || ($ysize != 1))
      {   $stream .= "q\n";
          $stream .= calcMatrix($x, $y, $rotate, $size,
                     $xsize, $ysize, $BBox[2], $BBox[3]);
          $stream .= "\n/Gs0 gs\n";
          $stream .= "/$namn Do\n";
          $stream .= "Q\n";
      }
      else
      {   $stream .= "\n/Gs0 gs\n";
          $stream .= "/$namn Do\n";
 
      }
      $sidXObject{$namn}   = $refNr;
      $sidExtGState{'Gs0'} = $defGState;
  }
  if ($runfil)
  {  $infil = prep($infil);
     $log .= "Form~$infil~$sidnr~$adjust~$effect~$tolerant";
     $log .= "~$x~$y~$rotate~$size~$xsize~$ysize\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  if (($effect ne 'print') && ($effect ne 'add'))
  {  undef $namn;
  }
  if (wantarray)
  {  my $images = 0;
     if (exists $form{$fSource}[fIMAGES])
     {  $images = scalar(@{$form{$fSource}[fIMAGES]});
     }
     return ($namn, $BBox[0], $BBox[1], $BBox[2],
             $BBox[3], $images);
  }
  else
  {  return $namn;
  }
}
 
 
 
##########################################################
sub prDefaultGrState
##########################################################
{  $objNr++;
   $defGState = $objNr;
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
 
   $objekt[$objNr] = $pos;
   my $utrad = "$objNr 0 obj" . '<</Type/ExtGState/SA false/SM 0.02/TR2 /Default'
           . ">>endobj\n";
   $pos += syswrite UTFIL, $utrad;
   $objRef{'Gs0'} = $objNr;
   return ('Gs0', $defGState);
}
 
######################################################
# En font lokaliseras och fontobjektet skrivs ev. ut
######################################################
 
sub findFont
{  no warnings;
   my $Font = shift || '';
 
   if (! (exists $fontSource{$Font}))        #  Fonten måste skapas
   {  if (exists $stdFont{$Font})
      {  $Font = $stdFont{$Font};}
      else
      {  $Font = $genFont; }                 # Helvetica sätts om inget annat finns
      if (! (exists $font{$Font}))
      {  $objNr++;
         $fontNr++;
         my $fontAbbr           = 'Ft' . $fontNr;
         my $fontObjekt         = "$objNr 0 obj<</Type/Font/Subtype/Type1" .
                               "/BaseFont/$Font/Encoding/WinAnsiEncoding>>endobj\n";
         $font{$Font}[foINTNAMN]      = $fontAbbr;
         $font{$Font}[foREFOBJ]       = $objNr;
         $objRef{$fontAbbr}           = $objNr;
         $fontSource{$Font}[foSOURCE] = 'Standard';
         $objekt[$objNr]              = $pos;
         $pos += syswrite UTFIL, $fontObjekt;
      }
   }
   else
   {  if (defined $font{$Font}[foREFOBJ])       # Finns redan i filen
      {  ; }
      else
      {  if ($fontSource{$Font}[foSOURCE] eq 'Standard')
         {   $objNr++;
             $fontNr++;
             my $fontAbbr           = 'Ft' . $fontNr;
             my $fontObjekt         = "$objNr 0 obj<</Type/Font/Subtype/Type1" .
                                      "/BaseFont/$Font/Encoding/WinAnsiEncoding>>endobj\n";
             $font{$Font}[foINTNAMN]    = $fontAbbr;
             $font{$Font}[foREFOBJ]     = $objNr;
             $objRef{$fontAbbr}         = $objNr;
             $objekt[$objNr]            = $pos;
             $pos += syswrite UTFIL, $fontObjekt;
         }
         else
         {  my $fSource = $fontSource{$Font}[foSOURCE];
            my $ri      = rindex($fSource, '_');
            my $Source  = substr($fSource, 0, $ri);
            my $Page    = substr($fSource, ($ri + 1));
 
            if (! $fontSource{$Font}[foORIGINALNR])
            {  errLog("Couldn't find $Font, aborts");
            }
            else
            {  my $namn = extractObject($Source, $Page,
                                        $fontSource{$Font}[foORIGINALNR], 'Font');
            }
         }
      }
   }
 
   $aktuellFont[foEXTNAMN]   = $Font;
   $aktuellFont[foREFOBJ]    = $font{$Font}[foREFOBJ];
   $aktuellFont[foINTNAMN]   = $font{$Font}[foINTNAMN];
   $aktuellFont[foTYP]       = $font{$Font}[foTYP];
 
   $sidFont{$aktuellFont[foINTNAMN]} = $aktuellFont[foREFOBJ];
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
 
   return ($aktuellFont[foINTNAMN], $aktuellFont[foEXTNAMN], $aktuellFont[foREFOBJ]);
}
 
sub skrivSida
{  my ($compressFlag, $streamObjekt, @extObj);
   if ($checkCs)
   {  @extObj = ($stream =~ m'/(\S+)\s*'gso);
      checkContentStream(@extObj);
   }
   if (( $compress ) && ( length($stream)  > 99 ))
   {   my $output = compress($stream);
       if ((length($output) > 25) && (length($output) < (length($stream))))
       {  $stream = $output;
          $compressFlag = 1;
       }
   }
 
   if (! $parents[0])
   { $objNr++;
     $parents[0] = $objNr;
   }
   my $parent = $parents[0];
 
   ##########################################
   #  Interaktiva funktioner läggs ev. till
   ##########################################
 
   if ($interAktivSida)
   {  my ($infil, $sidnr) = split(/\s+/, $interActive);
      ($NamesSaved, $AARootSaved, $AAPageSaved, $AcroFormSaved)
            = AcroFormsEtc($infil, $sidnr);
   }
 
   ##########################
   # Skapa resursdictionary
   ##########################
   my $resursDict = "/ProcSet[/PDF/Text]";
   if (scalar %sidFont)
   {  $resursDict .= '/Font << ';
      my $i = 0;
      for (sort keys %sidFont)
      {  $resursDict .= "/$_ $sidFont{$_} 0 R";
      }
 
      $resursDict .= " >>";
   }
   if (scalar %sidXObject)
   {  $resursDict .= '/XObject<<';
      for (sort keys %sidXObject)
      {  $resursDict .= "/$_ $sidXObject{$_} 0 R";
      }
      $resursDict .= ">>";
   }
   if (scalar %sidExtGState)
   {  $resursDict .= '/ExtGState<<';
      for (sort keys %sidExtGState)
      {  $resursDict .= "\/$_ $sidExtGState{$_} 0 R";
      }
      $resursDict .= ">>";
   }
   if (scalar %sidPattern)
   {  $resursDict .= '/Pattern<<';
      for (sort keys %sidPattern)
      {  $resursDict .= "/$_ $sidPattern{$_} 0 R";
      }
      $resursDict .= ">>";
   }
   if (scalar %sidShading)
   {  $resursDict .= '/Shading<<';
      for (sort keys %sidShading)
      {  $resursDict .= "/$_ $sidShading{$_} 0 R";
      }
      $resursDict .= ">>";
   }
   if (scalar %sidColorSpace)
   {  $resursDict .= '/ColorSpace<<';
      for (sort keys %sidColorSpace)
      {  $resursDict .= "/$_ $sidColorSpace{$_} 0 R";
      }
      $resursDict .= ">>";
   }
 
 
   my $resursObjekt;
 
   if (exists $resurser{$resursDict})
   {  $resursObjekt = $resurser{$resursDict};  # Fanns ett identiskt,
   }                                           # använd det
   else
   {   $objNr++;
       if ( keys(%resurser) < 10)
       {  $resurser{$resursDict} = $objNr;  # Spara 10 första resursobjekten
       }
       $resursObjekt   = $objNr;
       $objekt[$objNr] = $pos;
       $resursDict     = "$objNr 0 obj<<$resursDict>>endobj\n";
       $pos += syswrite UTFIL, $resursDict ;
    }
    my $sidObjekt;
 
    if (! $touchUp)
    {   #
        # Contents objektet skapas
        #
 
        my $devX = "900";
        my $devY = "900";
 
        my $mellanObjekt = '<</Type/XObject/Subtype/Form/FormType 1';
        if (defined $resursObjekt)
        {  $mellanObjekt .= "/Resources $resursObjekt 0 R";
        }
        $mellanObjekt .= "/BBox \[$genLowerX $genLowerY $genUpperX $genUpperY\]" .
                     "/Matrix \[ 1 0 0 1 -$devX -$devY \]";
 
        my $langd = length($stream);
 
        $objNr++;
        $objekt[$objNr] = $pos;
        if (! $compressFlag)
        {   $mellanObjekt  = "$objNr 0 obj\n$mellanObjekt/Length $langd>>stream\n"
                           . $stream;
            $mellanObjekt .= "endstream\nendobj\n";
        }
        else
        {   $stream = "\n" . $stream . "\n";
            $langd++;
            $mellanObjekt  = "$objNr 0 obj\n$mellanObjekt/Filter/FlateDecode"
                           .  "/Length $langd>>stream" . $stream;
            $mellanObjekt .= "endstream\nendobj\n";
        }
 
        $pos += syswrite UTFIL, $mellanObjekt;
        $mellanObjekt = $objNr;
 
        if (! defined $confuseObj)
        {  $objNr++;
           $objekt[$objNr] = $pos;
 
           $stream = "\nq\n1 0 0 1 $devX $devY cm\n/Xwq Do\nQ\n";
           $langd = length($stream);
           $confuseObj = $objNr;
           $stream = "$objNr 0 obj<</Length $langd>>stream\n" . "$stream";
           $stream .= "\nendstream\nendobj\n";
           $pos += syswrite UTFIL, $stream;
        }
        $sidObjekt = "$sidObjNr 0 obj\n<</Type/Page/Parent $parent 0 R/Contents $confuseObj 0 R"
                      . "/MediaBox \[$genLowerX $genLowerY $genUpperX $genUpperY\]"
                      . "/Resources <</ProcSet[/PDF/Text]/XObject<</Xwq $mellanObjekt 0 R>>>>";
    }
    else
    {   my $langd = length($stream);
 
        $objNr++;
        $objekt[$objNr] = $pos;
        if (! $compressFlag)
        {  $streamObjekt  = "$objNr 0 obj<</Length $langd>>stream\n" . $stream;
           $streamObjekt .= "\nendstream\nendobj\n";
        }
        else
        {  $stream = "\n" . $stream . "\n";
           $langd++;
 
           $streamObjekt  = "$objNr 0 obj<</Filter/FlateDecode"
                             . "/Length $langd>>stream" . $stream;
           $streamObjekt .= "endstream\nendobj\n";
        }
 
        $pos += syswrite UTFIL, $streamObjekt;
        $streamObjekt = $objNr;
        ##################################
        # Så skapas och skrivs sidobjektet
        ##################################
 
        $sidObjekt = "$sidObjNr 0 obj<</Type/Page/Parent $parent 0 R/Contents $streamObjekt 0 R"
                      . "/MediaBox \[$genLowerX $genLowerY $genUpperX $genUpperY\]"
                      . "/Resources $resursObjekt 0 R";
    }
 
    $stream = '';
 
    my $tSida = $sida + 1;
    if ((@annots)
    || (%links && @{$links{'-1'}})
    || (%links && @{$links{$tSida}}))
    {  $sidObjekt .= '/Annots ' . mergeLinks() . ' 0 R';
    }
    if (defined $AAPageSaved)
    {  $sidObjekt .= "/AA $AAPageSaved";
       undef $AAPageSaved;
    }
    $sidObjekt .= ">>endobj\n";
    $objekt[$sidObjNr] = $pos;
    $pos += syswrite UTFIL, $sidObjekt;
    push @{$kids[0]}, $sidObjNr;
    $sida++;
    $counts[0]++;
    if ($counts[0] > 9)
    {  ordnaNoder(8); }
}
 
 
sub prEnd
{   if (! $pos)
    {  return;
    }
    if ($stream)
    { skrivSida(); }
    skrivUtNoder();
 
    if($docProxy)
    {  $docProxy->write_objects;
       undef $docProxy;             # Break circular refs
    }
 
    ###################
    # Skriv root
    ###################
 
    if (! defined $objekt[$objNr])
    {  $objNr--;                   # reserverat sidobjektnr utnyttjades aldrig
    }
 
    my $utrad = "1 0 obj<</Type/Catalog/Pages $slutNod 0 R";
    if (defined $NamesSaved)
    {  $utrad .= "\/Names $NamesSaved 0 R\n";
    }
    elsif ((scalar %fields) || (scalar @jsfiler))
    {  $utrad .= "\/Names " . behandlaNames() . " 0 R\n";
    }
    if (defined $AARootSaved)
    {  $utrad .= "/AA $AARootSaved\n";
    }
    if ((scalar @inits) || (scalar %fields))
    {  my $nyttANr = skrivKedja();
       $utrad .= "/OpenAction $nyttANr 0 R";
    }
 
    if (defined $AcroFormSaved)
    {  $utrad .= "/AcroForm $AcroFormSaved\n";
    }
 
    if (scalar @bookmarks)
    {  my $outLine = ordnaBookmarks();
       $utrad .= "/Outlines $outLine 0 R/PageMode /UseOutlines\n";
    }
    if (scalar %prefs)
    {   $utrad .= '/ViewerPreferences << ';
        if (exists $prefs{hidetoolbar})
        {  $utrad .= ($prefs{hidetoolbar}) ? '/HideToolbar true'
                                           : '/HideToolbar false';
        }
        if (exists $prefs{hidemenubar})
        {  $utrad .= ($prefs{hidemenubar}) ? '/HideMenubar true'
                                           : '/HideMenubar false';
        }
        if (exists $prefs{hidewindowui})
        {  $utrad .= ($prefs{hidewindowui}) ? '/HideWindowUI true'
                                            : '/HideWindowUI false';
        }
        if (exists $prefs{fitwindow})
        {  $utrad .= ($prefs{fitwindow}) ? '/FitWindow true'
                                         : '/FitWindow false';
        }
        if (exists $prefs{centerwindow})
        {  $utrad .= ($prefs{centerwindow}) ? '/CenterWindow true'
                                            : '/CenterWindow false';
        }
        $utrad .= '>> ';
    }
 
    $utrad .= ">>endobj\n";
 
    $objekt[1] = $pos;
    $pos += syswrite UTFIL, $utrad;
    my $antal = $#objekt;
    my $startxref = $pos;
    my $xrefAntal = $antal + 1;
    $pos += syswrite UTFIL, "xref\n";
    $pos += syswrite UTFIL, "0 $xrefAntal\n";
    $pos += syswrite UTFIL, "0000000000 65535 f \n";
 
    for (my $i = 1; $i <= $antal; $i++)
    {  $utrad = sprintf "%.10d 00000 n \n", $objekt[$i];
       $pos += syswrite UTFIL, $utrad;
    }
 
    $utrad  = "trailer\n<<\n/Size $xrefAntal\n/Root 1 0 R\n";
    if ($idTyp ne 'None')
    {  my ($id1, $id2) = definieraId();
       $utrad .= "/ID [<$id1><$id2>]\n";
       $log  .= "IdType~rep\n";
       $log  .= "Id~$id1\n";
    }
    $utrad .= ">>\nstartxref\n$startxref\n";
    $pos += syswrite UTFIL, $utrad;
    $pos += syswrite UTFIL, "%%EOF\n";
    close UTFIL;
 
    if ($runfil)
    {   if ($log)
        { print RUNFIL $log;
        }
        close RUNFIL;
    }
    $log    = '';
    $runfil = '';
    $pos    = 0;
    1;
}
 
sub ordnaNoder
{  my $antBarn = shift;
   my $i       = 0;
   my $j       = 1;
   my $vektor;
 
   while  ($antBarn < $#{$kids[$i]})
   {  #
      # Skriv ut aktuell förälder
      # flytta till nästa nivå
      #
      $vektor = '[';
 
      for (@{$kids[$i]})
      {  $vektor .= "$_ 0 R "; }
      $vektor .= ']';
 
      if (! $parents[$j])
      {  $objNr++;
         $parents[$j] = $objNr;
      }
 
      my $nodObjekt;
      $nodObjekt = "$parents[$i] 0 obj<</Type/Pages/Parent $parents[$j] 0 R\n/Kids $vektor\n/Count $counts[$i]>>endobj\n";
 
      $objekt[$parents[$i]] = $pos;
      $pos += syswrite UTFIL, $nodObjekt;
      $counts[$j] += $counts[$i];
      $counts[$i]  = 0;
      $kids[$i]    = [];
      push @{$kids[$j]}, $parents[$i];
      undef $parents[$i];
      $i++;
      $j++;
   }
}
 
sub skrivUtNoder
{  no warnings;
   my ($i, $j, $vektor, $nodObjekt);
   my $si = -1;
   #
   # Hitta slutnoden
   #
   for (@parents)
   { $slutNod = $_;
     $si++;
   }
 
   for ($i = 0; $parents[$i] ne $slutNod; $i++)
   {  if (defined $parents[$i])  # Bara definierat om det finns kids
      {  $vektor = '[';
         for (@{$kids[$i]})
         {  $vektor .= "$_ 0 R "; }
         $vektor .= ']';
         ########################################
         # Hitta förälder till aktuell förälder
         ########################################
         my $nod;
         for ($j = $i + 1; (! $nod); $j++)
         {  if ($parents[$j])
            {  $nod = $parents[$j];
               $counts[$j] += $counts[$i];
               push @{$kids[$j]}, $parents[$i];
            }
         }
 
         $nodObjekt = "$parents[$i] 0 obj<</Type/Pages/Parent $nod 0 R\n/Kids $vektor/Count $counts[$i]>>endobj\n";
 
         $objekt[$parents[$i]] = $pos;
         $pos += syswrite UTFIL, $nodObjekt;
      }
   }
   #####################################
   #  Så ordnas och skrivs slutnoden ut
   #####################################
   $vektor = '[';
   for (@{$kids[$si]})
   {  $vektor .= "$_ 0 R "; }
   $vektor .= ']';
   $nodObjekt  = "$slutNod 0 obj<</Type/Pages/Kids $vektor/Count $counts[$si]";
   # $nodObjekt .= "/MediaBox \[$genLowerX $genLowerY $genUpperX $genUpperY\]";
   $nodObjekt .= " >>endobj\n";
   $objekt[$slutNod] = $pos;
   $pos += syswrite UTFIL, $nodObjekt;
 
}
 
sub findGet
{  my ($fil, $cid) = @_;
   $fil =~ s|\s+$||o;
   my ($req, $extFil, $tempFil, $fil2, $tStamp, $res);
 
   if (-e $fil)
   {  $tStamp = (stat($fil))[9];
      if ($cid)
      {
        if ($cid eq $tStamp)
        {  return ($fil, $cid);
        }
      }
      else
      {  return ($fil, $tStamp);
      }
   }
   if ($cid)
   {  $fil2 = $fil . $cid;
      if (-e $fil2)
      {  return ($fil2, $cid);
      }
   }
   errLog("The file $fil can't be found, aborts");
}
 
sub definieraId
{  if ($idTyp eq 'rep')
   {  if (! defined $id)
      {  errLog("Can't replicate the id if is missing, aborting");
      }
      my $tempId = $id;
      undef $id;
      return ($tempId, $tempId);
   }
   elsif ($idTyp eq 'add')
   {  $id++;
      return ($id, $id);
   }
   else
   {  my $str = time();
      $str .= $filnamn . $pos;
      $str  = Digest::MD5::md5_hex($str);
      return ($str, $str);
   }
}
 
sub prStrWidth
{  require PDF::Reuse::Util;
   my $string   = shift;
   my $Font     = shift;
   my $FontSize = shift || $fontSize;
   my $w = 0;
 
   # there's no use continuing if no string is passed in
   if (! defined($string))
   {  errLog("undefined value passed to prStrWidth");
   }
 
   if (length($string) == 0)
   {  return 0;
   }
 
   if(my($width) = ttfStrWidth($string, $Font, $FontSize))
   {  return $width;
   }
 
   if (! $Font)
   {  if (! $aktuellFont[foEXTNAMN])
      {  findFont();
      }
      $Font = $aktuellFont[foEXTNAMN];
   }
 
   if (! exists $PDF::Reuse::Util::font_widths{$Font})
   {  if (exists $stdFont{$Font})
      {  $Font = $stdFont{$Font};
      }
      if (! exists $PDF::Reuse::Util::font_widths{$Font})
      {   $Font = 'Helvetica';
      }
   }
 
   if (ref($PDF::Reuse::Util::font_widths{$Font}) eq 'ARRAY')
   {   my @font_table = @{ $PDF::Reuse::Util::font_widths{$Font} };
       for (unpack ("C*", $string))
       {  $w += $font_table[$_];
       }
   }
   else
   {   $w = length($string) * $PDF::Reuse::Util::font_widths{$Font};
   }
   $w = $w / 1000 * $FontSize;
 
   return $w;
}
 
sub prTTFont
{  return prFont() if ! @_;
   my($selector, $fontname) = @_;
 
   # Have we loaded this font already?
   my $ttfont = findTTFont($selector);
   if (! $ttfont  and  $font{$selector} )
   {  return prFont($selector);
   }
   $fontname = $ttfont->fontname if $ttfont;
 
   # Create a new TTFont object if we haven't loaded this one before
   if (! $ttfont)
   {  $docProxy ||= PDF::Reuse::DocProxy->new(
         next_obj => sub { ++$objNr },
         prObj    => \&prObj,
      );
 
      my $ttfont = PDF::Reuse::TTFont->new(
         filename => $selector,
         fontname => $fontname,
         fontAbbr => 'Ft' . ++$fontNr,
         docProxy => $docProxy,
      );
      $fontname = $ttfont->fontname;
 
      $font{$fontname}[foINTNAMN]      = $ttfont->fontAbbr;
      $font{$fontname}[foREFOBJ]       = $ttfont->obj_num;
      $font{$fontname}[foFONTOBJ]      = $ttfont;
      $objRef{$ttfont->fontAbbr}       = $ttfont->obj_num;
      $fontSource{$fontname}[foSOURCE] = 'Standard';
   }
 
   my $oldIntNamn = $aktuellFont[foINTNAMN];
   my $oldExtNamn = $aktuellFont[foEXTNAMN];
 
   $aktuellFont[foEXTNAMN]   = $fontname;
   $aktuellFont[foREFOBJ]    = $font{$fontname}[foREFOBJ];
   $aktuellFont[foINTNAMN]   = $font{$fontname}[foINTNAMN];
   $aktuellFont[foTYP]       = $font{$fontname}[foTYP];
 
   $sidFont{$aktuellFont[foINTNAMN]} = $aktuellFont[foREFOBJ];
 
   if (wantarray)
   { return ($aktuellFont[foINTNAMN], $aktuellFont[foEXTNAMN], $oldIntNamn, $oldExtNamn, \%font);
   }
   else
   { return $aktuellFont[foINTNAMN];
   }
}
 
 
sub prObj
{  my($objNr, $data) = @_;
 
   $objekt[$objNr] = $pos;
   $pos += syswrite UTFIL, $data;
}
 
 
sub findTTFont
{  my $selector = shift || $aktuellFont[foEXTNAMN];
 
   return $font{$selector}[foFONTOBJ] if $font{$selector};
   foreach my $name (keys %font)
   {  if (  $font{$name}[foINTNAMN] eq $selector
         or $font{$name}[foFONTOBJ] && $font{$name}[foFONTOBJ]->filename eq $selector
      )
      {  return $font{$name}[foFONTOBJ];
      }
   }
   return;
}
 
 
sub ttfStrWidth
{  my($string, $selector, $fontsize) = @_;
 
   my $ttfont = findTTFont($selector) or return;
   return $ttfont->text_width($string, $fontsize);
}
 
 
# This 'glue' package emulates the bits of the Text::PDF::File API that are
# needed by Text::PDF::TTFont0 (below) and ties them in to the PDF::Reuse API.
 
package PDF::Reuse::DocProxy;
 
sub new
{  my $class = shift;
 
   my $self = bless { ' version' => 3, @_, '>buffer'  => '', }, $class;
}
 
 
sub new_obj
{  my $self = shift;
   my $obj  = shift  or die 'No base for new_obj';
 
   my $num = $self->{next_obj}->();
   my $gen = 0;
 
   $self->{' objcache'}{$num, $gen} = $obj;
   $self->{' objects'}{$obj->uid}   = [ $num, $gen ];
   return $obj;
}
 
 
sub object_number
{  my($self, $obj) = @_;
   my $num = $self->{' objects'}{$obj->uid} || return;
   return $num->[0];
}
 
 
sub print
{  my($self, $data) = @_;
 
   if(my($tail, $rest) = $data =~ m{\A(.*?\nendobj\n)(.*)\z}s)
   {  my($obj_num) = $self->{'>buffer'} =~ /(\d+)/;
      # Pass serialised object back to PDF::Reuse
      $self->{prObj}->($obj_num, $self->{'>buffer'} . $tail);
      $self->{'>buffer'} = $rest;
   }
   else
   {  $self->{'>buffer'} .= $data;
   }
}
 
 
sub printf
{  my($self, $format, @args) = @_;;
   $self->print(sprintf($format, @args));
}
 
 
sub out_obj
{  my($self, $obj) = @_;
   return $self->new_obj($obj) unless defined $self->{' objects'}{$obj->uid};
   push @{ $self->{'>todo'} }, $obj->uid;
}
 
 
sub tell
{  return length shift->{'>buffer'};
}
 
 
sub write_objects
{  my($self) = @_;
 
   $self->{'>done'} = {};
   $self->{'>todo'} = [ sort map { $_->uid } values %{ $self->{' objcache'} } ];
   while(my $id = shift @{ $self->{'>todo'} }) {
      next if $self->{'>done'}{$id};
      my($num, $gen) = @{ $self->{' objects'}{$id} };
      $self->printf("%d %d obj\n", $num, $gen);
      $self->{' objcache'}{$num, $gen}->outobjdeep($self, $self);
      $self->print("\nendobj\n");
      $self->{'>done'}{$id}++;
   }
}
 
 
# This is a wrapper around Text::PDF::TTFont0, which provides support for
# embedding TrueType fonts
 
package PDF::Reuse::TTFont;
 
sub new
{  my $class = shift;
 
   require Text::PDF::TTFont0;
 
   my $self = bless { 'subset'   => 1, @_, }, $class;
 
   $self->{ttfont} = Text::PDF::TTFont0->new(
      $self->{docProxy},
      $self->{filename},
      $self->{fontAbbr},
      -subset => $self->{subset},
   );
   $self->{ttfont}->{' subvec'} = '';
 
   $self->{obj_num} = $self->{docProxy}->object_number($self->{ttfont});
 
   $self->{fontname} ||= $self->find_name();
 
   return $self;
}
 
sub filename  { return $_[0]->{filename};     }
sub fontname  { return $_[0]->{fontname};     }
sub obj_num   { return $_[0]->{obj_num};      }
sub fontAbbr  { return $_[0]->{fontAbbr};     }
sub docProxy  { return $_[0]->{docProxy};     }
 
sub find_name
{  my $self = shift;
   my($filebase) = $self->filename =~ m{.*[\\/](.*)\.};
   my $font = $self->{ttfont}->{' font'} or return $filebase;
   my $obj  = $font->{'name'}            or return $filebase;
   my $name = $obj->read->find_name(4)   or return $filebase;
   $name =~ s{\W}{}g;
   return $name;
}
 
sub encode_text
{  my($self, $text) = @_;
   $text =~ s|\\\(|(|gos;
   $text =~ s|\\\)|)|gos;
   return $self->{ttfont}->out_text($text);
}
 
sub text_width
{  my($self, $text, $size) = @_;
   return $self->{ttfont}->width($text) * $size;
}
 
sub DESTROY
{  my $self = shift;
   if(my $ttfont = $self->{ttfont})
   {  if(my $font = delete $ttfont->{' font'})
      { $font->release();
      }
      $ttfont->release();
   }
   %$self = ();
}
 
 
package PDF::Reuse;  # Applies to the autoloaded methods below (?)
 
1;
 
__END__
Show 1496 lines of Pod
 
sub prSinglePage
{ my $infil      = shift;
  my $pageNumber = shift;
 
  if (! defined $pageNumber)
  {   $behandlad{$infil}->{pageNumber} = 0
        unless (defined $behandlad{$infil}->{pageNumber});
      $pageNumber = $behandlad{$infil}->{pageNumber} + 1;
  }
 
  my ($sida, $Names, $AARoot, $AcroForm) = analysera($infil, $pageNumber, $pageNumber, 1);
  if (($Names) || ($AARoot) || ($AcroForm))
  { $NamesSaved     = $Names;
    $AARootSaved    = $AARoot;
    $AcroFormSaved  = $AcroForm;
    $interActive    = 1;
  }
  if (defined $sida)
  {  $behandlad{$infil}->{pageNumber} = $pageNumber;
  }
  if ($runfil)
  {   $infil = prep($infil);
      $log .= "prSinglePage~$infil~$pageNumber\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  return $sida;
 
}
 
 
 
sub prLink
{ my %link;
  my $param = shift;
  if (ref($param) eq 'HASH')
  {  $link{page}   = $param->{'page'} || -1;
     $link{x}      = $param->{'x'}    || 100;
     $link{y}      = $param->{'y'}    || 100;
     $link{width}  = $param->{width}  || 75;
     $link{height} = $param->{height} || 15;
     $link{v}      = $param->{URI};
     $link{s}      = $param->{s} || "URI";
  }
  else
  {  $link{page}   = $param || -1;
     $link{x}      = shift  || 100;
     $link{y}      = shift  || 100;
     $link{width}  = shift  || 75;
     $link{height} = shift  || 15;
     $link{v}      = shift;
     $link{s}      = shift  || "URI";
  }
 
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
 
  if ($runfil)
  {  $log .= "Link~$link{page}~$link{x}~$link{y}~$link{width}~"
          . "$link{height}~$link{v}~$link{s}\n";
  }
 
  if ($link{v})
  {  push @{$links{$link{page}}}, \%link;
  }
  1;
}
 
sub mergeLinks
{   my $tSida = $sida + 1;
    my $rad;
    my ($linkObject, $linkObjectNo);
    for my $link (@{$links{'-1'}}, @{$links{$tSida}} )
    {   my $x2 = $link->{x} + $link->{width};
        my $y2 = $link->{y} + $link->{height};
        if (exists $links{$link->{v}})
        {   $linkObjectNo = $links{$link->{v}};
        }
        else
        {   $objNr++;
            $objekt[$objNr] = $pos;
            my $v_n;
            my $v_v = '('.$link->{v}.')';
            if    ($link->{s} eq 'GoTo')
            {   $v_n = "D";
            }
            elsif ($link->{s} eq 'GoToA')
            {   $link->{s} = 'GoTo';
                $v_n       = 'D';
                $v_v       = $link->{v};
            }
            elsif ($link->{s} eq 'Launch')     {$v_n = 'F';}
            elsif ($link->{s} eq 'SubmitForm') {$v_n = 'F';}
            elsif ($link->{s} eq 'Named')
            {   $v_n = 'N';
                $v_v = $link->{v};
            }
            elsif ($link->{s} eq 'JavaScript') {$v_n = "JS";}
            else
            {   $v_n = $link->{s};
            }
            $rad = "$objNr 0 obj<</S/$link->{s}/$v_n$v_v>>endobj\n";
            $linkObjectNo = $objNr;
            $links{$link->{v}} = $objNr;
            $pos += syswrite UTFIL, $rad;
        }
        $rad = "/Subtype/Link/Rect[$link->{x} $link->{y} "
             . "$x2 $y2]/A $linkObjectNo 0 R/Border[0 0 0]";
        if (exists $links{$rad})
        {   push @annots, $links{$rad};
        }
        else
        {   $objNr++;
            $objekt[$objNr] = $pos;
            $links{$rad} = $objNr;
            $rad = "$objNr 0 obj<<$rad>>endobj\n";
            $pos += syswrite UTFIL, $rad;
            push @annots, $objNr;
        }
    }
    @{$links{'-1'}}   = ();
    @{$links{$tSida}} = ();
    $objNr++;
    $objekt[$objNr] = $pos;
    $rad = "$objNr 0 obj[\n";
    for (@annots)
    {  $rad .= "$_ 0 R\n";
    }
    $rad .= "]endobj\n";
    $pos += syswrite UTFIL, $rad;
    @annots = ();
    return $objNr;
}
 
 
sub prBookmark
{   my $param = shift;
    if (! ref($param))
    {   $param = eval ($param);
    }
    if (! ref($param))
    {   return undef;
    }
    if (! $pos)
    {  errLog("No output file, you have to call prFile first");
    }
    if (ref($param) eq 'HASH')
    {   push @bookmarks, $param;
    }
    else
    {   push @bookmarks, (@$param);
    }
    if ($runfil)
    {   local $Data::Dumper::Indent = 0;
        $param = Dumper($param);
        $param =~ s/^\$VAR1 = //;
        $param = prep($param);
        $log .= "Bookmark~$param\n";
    }
    return 1;
}
 
sub ordnaBookmarks
{   my ($first, $last, $me, $entry, $rad);
    $totalCount = 0;
    if (defined $objekt[$objNr])
    {  $objNr++;
    }
    $me = $objNr;
 
    my $number = $#bookmarks;
    for (my $i = 0; $i <= $number ; $i++)
    {   my %hash = %{$bookmarks[$i]};
        $objNr++;
        $hash{'this'} = $objNr;
        if ($i == 0)
        {   $first = $objNr;
        }
        if ($i == $number)
        {   $last = $objNr;
        }
        if ($i < $number)
        {  $hash{'next'} = $objNr + 1;
        }
        if ($i > 0)
        {  $hash{'previous'} = $objNr - 1;
        }
        $bookmarks[$i] = \%hash;
    }
 
    for $entry (@bookmarks)
    {  my %hash = %{$entry};
       descend ($me, %hash);
    }
 
    $objekt[$me] = $pos;
 
    $rad = "$me 0 obj<<";
    $rad .= "/Type/Outlines";
    $rad .= "/Count $totalCount";
    if (defined $first)
    {  $rad .= "/First $first 0 R";
    }
    if (defined $last)
    {  $rad .= "/Last $last 0 R";
    }
    $rad .= ">>endobj\n";
    $pos += syswrite UTFIL, $rad;
 
    return $me;
 
}
 
sub descend
{   my ($parent, %entry) = @_;
    my ($first, $last, $count, $me, $rad, $jsObj);
    if (! exists $entry{'close'})
    {  $totalCount++; }
    $count = $totalCount;
    $me = $entry{'this'};
    if (exists $entry{'kids'})
    {   if (ref($entry{'kids'}) eq 'ARRAY')
        {   my @array = @{$entry{'kids'}};
            my $number = $#array;
            for (my $i = 0; $i <= $number ; $i++)
            {   $objNr++;
                $array[$i]->{'this'} = $objNr;
                if ($i == 0)
                {   $first = $objNr;
                }
                if ($i == $number)
                {   $last = $objNr;
                }
 
                if ($i < $number)
                {  $array[$i]->{'next'} = $objNr + 1;
                }
                if ($i > 0)
                {  $array[$i]->{'previous'} = $objNr - 1;
                }
                if (exists $entry{'close'})
                {  $array[$i]->{'close'} = 1;
                }
            }
 
            for my $element (@array)
            {   descend($me, %{$element})
            }
        }
        else                                          # a hash
        {   my %hash = %{$entry{'kids'}};
            $objNr++;
            $hash{'this'} = $objNr;
            $first        = $objNr;
            $last         = $objNr;
            descend($me, %hash)
        }
     }
 
 
     $objekt[$me] = $pos;
     $rad = "$me 0 obj<<";
     if (exists $entry{'text'})
     {   $rad .= "/Title ($entry{'text'})";
     }
     $rad .= "/Parent $parent 0 R";
     if (defined $jsObj)
     {  $rad .= "/A $jsObj 0 R";
     }
     if (exists $entry{'act'})
     {   my $code = $entry{'act'};
         if ($code =~ m/(\d+)/os)
         {
              $code = $1;
         }
         $rad .= "/Dest [$code /XYZ null null null] ";
     }
     if (exists $entry{'previous'})
     {  $rad .= "/Prev $entry{'previous'} 0 R";
     }
     if (exists $entry{'next'})
     {  $rad .= "/Next $entry{'next'} 0 R";
     }
     if (defined $first)
     {  $rad .= "/First $first 0 R";
     }
     if (defined $last)
     {  $rad .= "/Last $last 0 R";
     }
     if ($count != $totalCount)
     {   $count = $totalCount - $count;
         $rad .= "/Count $count";
     }
     if (exists $entry{'color'})
     {   $rad .= "/C [$entry{'color'}]";
     }
     if (exists $entry{'style'})
     {   $rad .= "/F $entry{'style'}";
     }
 
     $rad .= ">>endobj\n";
     $pos += syswrite UTFIL, $rad;
}
 
sub prInitVars
{   my $exit = shift;
    $genLowerX    = 0;
    $genLowerY    = 0;
    $genUpperX    = 595,
    $genUpperY    = 842;
    $fontSize     = 12;
    ($utfil, $slutNod, $formCont, $imSeq,
    $page, $sidObjNr, $interActive, $NamesSaved, $AARootSaved, $AAPageSaved,
    $root, $AcroFormSaved, $id, $ldir, $checkId, $formNr, $imageNr,
    $filnamn, $interAktivSida, $taInterAkt, $type, $runfil, $checkCs,
    $confuseObj, $compress,$pos, $fontNr, $objNr,
    $defGState, $gSNr, $pattern, $shading, $colorSpace) = '';
 
    (@kids, @counts, @formBox, @objekt, @parents, @aktuellFont, @skapa,
     @jsfiler, @inits, @bookmarks, @annots) = ();
 
    ( %resurser,  %objRef, %nyaFunk,%oldObject, %unZipped,
      %sidFont, %sidXObject, %sidExtGState, %font, %fields, %script,
      %initScript, %sidPattern, %sidShading, %sidColorSpace, %knownToFile,
      %processed, %dummy) = ();
 
     $stream = '';
     $idTyp  = '';
     $ddir   = '';
     $log    = '';
 
     if ($exit)
     {  return 1;
     }
 
     ( %form, %image, %fontSource, %intAct) = ();
 
     return 1;
}
 
####################
# Behandla en bild
####################
 
sub prImage
{ my $param = shift;
  my ($infil, $sidnr, $bildnr, $effect, $adjust, $x, $y, $size, $xsize,
      $ysize, $rotate);
 
  if (ref($param) eq 'HASH')
  {  $infil  = $param->{'file'};
     $sidnr  = $param->{'page'} || 1;
     $bildnr = $param->{'imageNo'} || 1;
     $effect = $param->{'effect'} || 'print';
     $adjust = $param->{'adjust'} || '';
     $x      = $param->{'x'} || 0;
     $y      = $param->{'y'} || 0;
     $rotate = $param->{'rotate'} || 0;
     $size   = $param->{'size'} || 1;
     $xsize  = $param->{'xsize'} || 1;
     $ysize  = $param->{'ysize'} || 1;
  }
  else
  {  $infil  = $param;
     $sidnr  = shift || 1;
     $bildnr = shift || 1;
     $effect = shift || 'print';
     $adjust = shift || '';
     $x      = shift || 0;
     $y      = shift || 0;
     $rotate = shift || 0;
     $size   = shift || 1;
     $xsize  = shift || 1;
     $ysize  = shift || 1;
  }
 
  my ($refNr, $inamn, $bildIndex, $xc, $yc, $xs, $ys);
  $type = 'image';
 
  $bildIndex = $bildnr - 1;
  my $fSource = $infil . '_' . $sidnr;
  my $iSource = $fSource . '_' . $bildnr;
  if (! exists $image{$iSource})
  {  $imageNr++;
     $inamn = 'Ig' . $imageNr;
     $knownToFile{'Ig:' . $iSource} = $inamn;
     $image{$iSource}[imXPOS]   = 0;
     $image{$iSource}[imYPOS]   = 0;
     $image{$iSource}[imXSCALE] = 1;
     $image{$iSource}[imYSCALE] = 1;
     if (! exists $form{$fSource} )
     {  $refNr = getPage($infil, $sidnr, '');
        if ($refNr)
        {  $formNr++;
           my $namn = 'Fm' . $formNr;
           $knownToFile{$fSource} = $namn;
        }
        elsif ((defined $refNr) && ($refNr eq '0'))
        {  errLog("File: $infil  Page: $sidnr can't be found");
        }
     }
     my $in = $form{$fSource}[fIMAGES][$bildIndex];
     $image{$iSource}[imWIDTH]  = $form{$fSource}->[fOBJ]->{$in}->[oWIDTH];
     $image{$iSource}[imHEIGHT] = $form{$fSource}->[fOBJ]->{$in}->[oHEIGHT];
     $image{$iSource}[imIMAGENO] = $form{$fSource}[fIMAGES][$bildIndex];
  }
  if (exists $knownToFile{'Ig:' . $iSource})
  {   $inamn = $knownToFile{'Ig:' . $iSource};
  }
  else
  {   $imageNr++;
      $inamn = 'Ig' . $imageNr;
      $knownToFile{'Ig:' . $iSource} = $inamn;
  }
  if (! exists $objRef{$inamn})
  {  $refNr = getImage($infil,  $sidnr,
                       $bildnr, $image{$iSource}[imIMAGENO]);
     $objRef{$inamn} = $refNr;
  }
  else
  {   $refNr = $objRef{$inamn};
  }
 
  my @iData = @{$image{$iSource}};
 
  if (($effect eq 'print') && ($refNr))
  {  if (! defined  $defGState)
     { prDefaultGrState();}
     $stream .= "\n/Gs0 gs\n";
     $stream .= "q\n";
 
     if ($adjust)
     {  $stream .= fillTheForm(0, 0, $iData[imWIDTH], $iData[imHEIGHT],$adjust);
     }
     else
     {   my $tX     = ($x + $iData[imXPOS]);
         my $tY     = ($y + $iData[imYPOS]);
         $stream .= calcMatrix($tX, $tY, $rotate, $size,
                               $xsize, $ysize, $iData[imWIDTH], $iData[imHEIGHT]);
     }
     $stream .= "$iData[imWIDTH] 0 0 $iData[imHEIGHT] 0 0 cm\n";
     $stream .= "/$inamn Do\n";
     $sidXObject{$inamn} = $refNr;
     $stream .= "Q\n";
     $sidExtGState{'Gs0'} = $defGState;
  }
  if ($runfil)
  {  $infil = prep($infil);
     $log .= "Image~$infil~$sidnr~$bildnr~$effect~$adjust";
     $log .= "$x~$y~$size~$xsize~$ysize~$rotate\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
 
  if (wantarray)
  {   return ($inamn, $iData[imWIDTH], $iData[imHEIGHT]);
  }
  else
  {   return $inamn;
  }
}
 
 
 
sub prMbox
{  my $lx = defined($_[0]) ? shift : 0;
   my $ly = defined($_[0]) ? shift : 0;
   my $ux = defined($_[0]) ? shift : 595;
   my $uy = defined($_[0]) ? shift : 842;
 
   if ((defined $lx) && ($lx =~ m'^[\d\-\.]+$'o))
   { $genLowerX = $lx; }
   if ((defined $ly) && ($ly =~ m'^[\d\-\.]+$'o))
   { $genLowerY = $ly; }
   if ((defined $ux) && ($ux =~ m'^[\d\-\.]+$'o))
   { $genUpperX = $ux; }
   if ((defined $uy) && ($uy =~ m'^[\d\-\.]+$'o))
   { $genUpperY = $uy; }
   if ($runfil)
   {  $log .= "Mbox~$lx~$ly~$ux~$uy\n";
   }
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
   1;
}
 
sub prField
{  my ($fieldName, $fieldValue) = @_;
   if (($interAktivSida) || ($interActive))
   {  errLog("Too late, has already tried to INITIATE FIELDS within an interactive page");
   }
   elsif (! $pos)
   {  errLog("Too early INITIATE FIELDS, create a file first");
   }
   $fields{$fieldName} = $fieldValue;
   if ($fieldValue =~ m'^\s*js\s*\:(.*)'oi)
   {  my $code = $1;
      my @fall = ($code =~ m'([\w\d\_\$]+)\s*\(.*?\)'gs);
      for (@fall)
      {  if (! exists $initScript{$_})
         { $initScript{$_} = 0;
         }
      }
   }
   if ($runfil)
   {   $fieldName  = prep($fieldName);
       $fieldValue = prep($fieldValue);
       $log .= "Field~$fieldName~$fieldValue\n";
   }
   1;
}
############################################################
sub prBar
{ my ($xPos, $yPos, $TxT) = @_;
 
  $TxT   =~ tr/G/2/;
 
  my @fontSpar = @aktuellFont;
 
  findBarFont();
 
  my $Font = $aktuellFont[foINTNAMN];                # Namn i strömmen
 
  if (($xPos) && ($yPos))
  {  $stream .= "\nBT /$Font $fontSize Tf ";
     $stream .= "$xPos $yPos Td \($TxT\) Tj ET\n";
  }
  if ($runfil)
  {  $log .= "Bar~$xPos~$yPos~$TxT\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  @aktuellFont = @fontSpar;
  return $Font;
 
}
 
 
sub prExtract
{  my $name = shift;
   my $form = shift;
   my $page = shift || 1;
   if ($name =~ m'^/(\w+)'o)
   {  $name = $1;
   }
   my $fullName = "$name~$form~$page";
   if (exists $knownToFile{$fullName})
   {   return $knownToFile{$fullName};
   }
   else
   {   if ($runfil)
       {  $log = "Extract~$fullName\n";
       }
       if (! $pos)
       {  errLog("No output file, you have to call prFile first");
       }
 
       if (! exists $form{$form . '_' . $page})
       {  prForm($form, $page, undef, 'load', 1);
       }
       $name = extractName($form, $page, $name);
       if ($name)
       {  $knownToFile{$fullName} = $name;
       }
       return $name;
   }
}
 
 
########## Extrahera ett dokument ####################
sub prDoc
{ my ($infil, $first, $last);
  my $param = shift;
  if (ref($param) eq 'HASH')
  {  $infil = $param->{'file'};
     $first = $param->{'first'} || 1;
     $last  = $param->{'last'} || '';
  }
  else
  {  $infil = $param;
     $first = shift || 1;
     $last  = shift || '';
  }
 
 
  my ($sidor, $Names, $AARoot, $AcroForm) = analysera($infil, $first, $last);
  if (($Names) || ($AARoot) || ($AcroForm))
  { $NamesSaved     = $Names;
    $AARootSaved    = $AARoot;
    $AcroFormSaved  = $AcroForm;
    $interActive    = 1;
  }
  if ($runfil)
  {   $infil = prep($infil);
      $log .= "Doc~$infil~$first~$last\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  return $sidor;
}
 
############# Ett interaktivt + grafiskt "formulär" ##########
 
sub prDocForm
{my ($sidnr, $adjust, $effect, $tolerant, $infil, $x, $y, $size, $xsize,
      $ysize, $rotate);
  my $param = shift;
  if (ref($param) eq 'HASH')
  {  $infil    = $param->{'file'};
     $sidnr    = $param->{'page'} || 1;
     $adjust   = $param->{'adjust'} || '';
     $effect   = $param->{'effect'} || 'print';
     $tolerant = $param->{'tolerant'} || '';
     $x        = $param->{'x'} || 0;
     $y        = $param->{'y'} || 0;
     $rotate   = $param->{'rotate'} || 0;
     $size     = $param->{'size'} || 1;
     $xsize    = $param->{'xsize'} || 1;
     $ysize    = $param->{'ysize'} || 1;
  }
  else
  {  $infil    = $param;
     $sidnr    = shift || 1;
     $adjust   = shift || '';
     $effect   = shift || 'print';
     $tolerant = shift || '';
     $x        = shift || 0;
     $y        = shift || 0;
     $rotate   = shift || 0;
     $size     = shift || 1;
     $xsize    = shift || 1;
     $ysize    = shift || 1;
  }
  my $namn;
  my $refNr;
  $type = 'docform';
  my $fSource = $infil . '_' . $sidnr;
  my $action;
  if (! exists $form{$fSource})
  {  $formNr++;
     $namn = 'Fm' . $formNr;
     $knownToFile{$fSource} = $namn;
     if ($effect eq 'load')
     {  $action = 'load'
     }
     else
     {  $action = 'print'
     }
     $refNr         = getPage($infil, $sidnr, $action);
     if ($refNr)
     {  $objRef{$namn} = $refNr;
     }
     else
     {  if ($tolerant)
        {  if ((defined $refNr) && ($refNr eq '0'))   # Sidnumret existerar inte, men ok
           {   $namn = '0';
           }
           else
           {   undef $namn;   # Sidan kan inte användas som form
           }
        }
        elsif (! defined $refNr)
        {  my $mess = "$fSource can't be used as a form. See the documentation\n"
                    . "under prForm how to concatenate streams\n";
           errLog($mess);
        }
        else
        {  errLog("File : $infil  Page: $sidnr  doesn't exist");
        }
     }
  }
  else
  {  if (exists $knownToFile{$fSource})
     {   $namn = $knownToFile{$fSource};
     }
     else
     {  $formNr++;
        $namn = 'Fm' . $formNr;
        $knownToFile{$fSource} = $namn;
     }
     if (exists $objRef{$namn})
     {  $refNr = $objRef{$namn};
     }
     else
     {  if (! $form{$fSource}[fVALID])
        {  my $mess = "$fSource can't be used as a form. See the documentation\n"
                    . "under prForm how to concatenate streams\n";
           if ($tolerant)
           {  cluck $mess;
              undef $namn;
           }
           else
           {  errLog($mess);
           }
        }
        elsif ($effect ne 'load')
        {  $refNr         =  byggForm($infil, $sidnr);
           $objRef{$namn} = $refNr;
        }
     }
  }
  my @BBox = @{$form{$fSource}[fBBOX]} if ($refNr);
  if (($effect eq 'print') && ($form{$fSource}[fVALID]) && ($refNr))
  {   if ((! defined $interActive)
      && ($sidnr == 1)
      &&  (defined %{$intAct{$fSource}[0]}) )
      {  $interActive = $infil . ' ' . $sidnr;
         $interAktivSida = 1;
      }
      if (! defined $defGState)
      { prDefaultGrState();
      }
      if ($adjust)
      {   $stream .= "q\n";
          $stream .= fillTheForm(@BBox, $adjust);
          $stream .= "\n/Gs0 gs\n";
          $stream .= "/$namn Do\n";
          $stream .= "Q\n";
      }
      elsif (($x) || ($y) || ($rotate) || ($size != 1)
                  || ($xsize != 1)     || ($ysize != 1))
      {   $stream .= "q\n";
          $stream .= calcMatrix($x, $y, $rotate, $size,
                               $xsize, $ysize, $BBox[2], $BBox[3]);
          $stream .= "\n/Gs0 gs\n";
          $stream .= "/$namn Do\n";
          $stream .= "Q\n";
      }
      else
      {   $stream .= "\n/Gs0 gs\n";
          $stream .= "/$namn Do\n";
      }
      $sidXObject{$namn} = $refNr;
      $sidExtGState{'Gs0'} = $defGState;
  }
  if ($runfil)
  {   $infil = prep($infil);
      $log .= "Form~$infil~$sidnr~$adjust~$effect~$tolerant";
      $log .= "~$x~$y~$rotate~$size~$xsize~$ysize\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  if (($effect ne 'print') && ($effect ne 'add'))
  {  undef $namn;
  }
  if (wantarray)
  {  my $images = 0;
     if (exists $form{$fSource}[fIMAGES])
     {  $images = scalar(@{$form{$fSource}[fIMAGES]});
     }
     return ($namn, $BBox[0], $BBox[1], $BBox[2],
             $BBox[3], $images);
  }
  else
  {  return $namn;
  }
}
 
sub calcMatrix
{  my ($x, $y, $rotate, $size, $xsize, $ysize, $upperX, $upperY) = @_;
   my ($str, $xSize, $ySize);
   $size  = 1 if ($size  == 0);
   $xsize = 1 if ($xsize == 0);
   $ysize = 1 if ($ysize == 0);
   $xSize = $xsize * $size;
   $ySize = $ysize * $size;
   $str = "$xSize 0 0 $ySize $x $y cm\n";
   if ($rotate)
   {   if ($rotate =~ m'q(\d)'oi)
       {  my $tal = $1;
          if ($tal == 1)
          {  $upperY = $upperX;
             $upperX = 0;
             $rotate = 270;
          }
          elsif ($tal == 2)
          {  $rotate = 180;
          }
          else
          {  $rotate = 90;
             $upperX = $upperY;
             $upperY = 0;
          }
       }
       else
       {   $upperX = 0;
           $upperY = 0;
       }
       my $radian = sprintf("%.6f", $rotate / 57.2957795);    # approx.
       my $Cos    = sprintf("%.6f", cos($radian));
       my $Sin    = sprintf("%.6f", sin($radian));
       my $negSin = $Sin * -1;
       $str .= "$Cos $Sin $negSin $Cos $upperX $upperY cm\n";
   }
   return $str;
}
 
sub fillTheForm
{  my $left   = shift || 0;
   my $bottom = shift || 0;
   my $right  = shift || 0;
   my $top    = shift || 0;
   my $how    = shift || 1;
   my $image  = shift;
   my $str;
   my $scaleX = 1;
   my $scaleY = 1;
 
   my $xDim = $genUpperX - $genLowerX;
   my $yDim = $genUpperY - $genLowerY;
   my $xNy  = $right - $left;
   my $yNy  = $top - $bottom;
   $scaleX  = $xDim / $xNy;
   $scaleY  = $yDim / $yNy;
   if ($how == 1)
   {  if ($scaleX < $scaleY)
      {  $scaleY = $scaleX;
      }
      else
      {  $scaleX = $scaleY;
      }
   }
   $str = "$scaleX 0 0 $scaleY $left $bottom cm\n";
   return $str;
}
 
sub prAltJpeg
{  my ($iData, $iWidth, $iHeight, $iFormat,$aiData, $aiWidth, $aiHeight, $aiFormat) = @_;
   if (! $pos)                    # If no output is active, it is no use to continue
   {   return undef;
   }
   prJpeg($aiData, $aiWidth, $aiHeight, $aiFormat);
   my $altObjNr = $objNr;
   $imageNr++;
   $objNr++;
   $objekt[$objNr] = $pos;
   $utrad = "$objNr 0 obj\n" .
            "[ << /Image $altObjNr 0 R\n" .
            "/DefaultForPrinting true\n" .
            ">>\n" .
            "]\n" .
            "endobj\n";
   $pos += syswrite UTFIL, $utrad;
   if ($runfil)
   {  $log .= "Jpeg~AltImage\n";
   }
   $objRef{$namnet} = $objNr;
   my $namnet = prJpeg($iData, $iWidth, $iHeight, $iFormat, $objNr);
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
   return $namnet;
}
 
sub prJpeg
{  my ($iData, $iWidth, $iHeight, $iFormat, $iColorType, $altArrayObjNr) = @_;
   if ($iColorType =~ /Gray/i)
   {  $iColorType = 'DeviceGray';
   }
   else
   {  $iColorType = 'DeviceRGB';
   }
   my ($iLangd, $namnet, $utrad);
   if (! $pos)                    # If no output is active, it is no use to continue
   {   return undef;
   }
   my $checkidOld = $checkId;
   if (!$iFormat)
   {   ($iFile, $checkId) = findGet($iData, $checkidOld);
       if ($iFile)
       {  $iLangd = (stat($iFile))[7];
          $imageNr++;
          $namnet = 'Ig' . $imageNr;
          $objNr++;
          $objekt[$objNr] = $pos;
          open (BILDFIL, "<$iFile") || errLog("Couldn't open $iFile, $!, aborts");
          binmode BILDFIL;
          my $iStream;
          sysread BILDFIL, $iStream, $iLangd;
          $utrad = "$objNr 0 obj\n<</Type/XObject/Subtype/Image/Name/$namnet" .
                    "/Width $iWidth /Height $iHeight /BitsPerComponent 8 " .
                    ($altArrayObjNr ? "/Alternates $altArrayObjNr 0 R " : "") .
                    "/Filter/DCTDecode/ColorSpace/$iColorType"
                    . "/Length $iLangd >>stream\n$iStream\nendstream\nendobj\n";
          close BILDFIL;
          $pos += syswrite UTFIL, $utrad;
          if ($runfil)
          {  $log .= "Cid~$checkId\n";
             $log .= "Jpeg~$iFile~$iWidth~$iHeight\n";
          }
          $objRef{$namnet} = $objNr;
       }
   }
   elsif ($iFormat == 1)
   {  my $iBlob = $iData;
      $iLangd = length($iBlob);
      $imageNr++;
      $namnet = 'Ig' . $imageNr;
      $objNr++;
      $objekt[$objNr] = $pos;
      $utrad = "$objNr 0 obj\n<</Type/XObject/Subtype/Image/Name/$namnet" .
                "/Width $iWidth /Height $iHeight /BitsPerComponent 8 " .
                ($altArrayObjNr ? "/Alternates $altArrayObjNr 0 R " : "") .
                "/Filter/DCTDecode/ColorSpace/$iColorType"
                . "/Length $iLangd >>stream\n$iBlob\nendstream\nendobj\n";
      $pos += syswrite UTFIL, $utrad;
      if ($runfil)
      {  $log .= "Cid~$checkId\n";
         $log .= "Jpeg~$iFile~$iWidth~$iHeight\n" if !$iFormat;
         $log .= "Jpeg~Blob~$iWidth~$iHeight\n" if $iFormat == 1;
      }
      $objRef{$namnet} = $objNr;
   }
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
   undef $checkId;
   return $namnet;
}
 
sub checkContentStream
{  for (@_)
   {  if (my $value = $objRef{$_})
      {   my $typ = substr($_, 0, 2);
          if ($typ eq 'Ft')
          {  $sidFont{$_} = $value;
          }
          elsif ($typ eq 'Gs')
          {  $sidExtGState{$_} = $value;
          }
          elsif ($typ eq 'Pt')
          {  $sidPattern{$_} = $value;
          }
          elsif ($typ eq 'Sh')
          {  $sidShading{$_} = $value;
          }
          elsif ($typ eq 'Cs')
          {  $sidColorSpace{$_} = $value;
          }
          else
          {  $sidXObject{$_} = $value;
          }
      }
      elsif (($_ eq 'Gs0') && (! defined $defGState))
      {  my ($dummy, $oNr) = prDefaultGrState();
         $sidExtGState{'Gs0'} = $oNr;
      }
   }
}
 
sub prGraphState
{  my $string = shift;
   $gSNr++;
   my $name = 'Gs' . $gSNr ;
   $objNr++;
   $objekt[$objNr] = $pos;
   my $utrad = "$objNr 0 obj\n" . $string  . "\nendobj\n";
   $pos += syswrite UTFIL, $utrad;
   $objRef{$name} = $objNr;
   if ($runfil)
   {  $log .= "GraphStat~$string\n";
   }
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
   return $name;
}
 
##############################################################
# Streckkods fonten lokaliseras och objekten skrivs ev. ut
##############################################################
 
sub findBarFont()
{  my $Font = 'Bar';
 
   if (exists $font{$Font})              #  Objekt är redan definierat
   {  $aktuellFont[foEXTNAMN]   = $Font;
      $aktuellFont[foREFOBJ]    = $font{$Font}[foREFOBJ];
      $aktuellFont[foINTNAMN]   = $font{$Font}[foINTNAMN];
   }
   else
   {  $objNr++;
      $objekt[$objNr]  = $pos;
      my $encodObj     = $objNr;
      my $fontObjekt   = "$objNr 0 obj\n<< /Type /Encoding\n" .
                         '/Differences [48 /tomt /streck /lstreck]' . "\n>>\nendobj\n";
      $pos += syswrite UTFIL, $fontObjekt;
      my $charProcsObj = createCharProcs();
      $objNr++;
      $objekt[$objNr]  = $pos;
      $fontNr++;
      my $fontAbbr     = 'Ft' . $fontNr;
      $fontObjekt      = "$objNr 0 obj\n<</Type/Font/Subtype/Type3\n" .
                         '/FontBBox [0 -250 75 2000]' . "\n" .
                         '/FontMatrix [0.001 0 0 0.001 0 0]' . "\n" .
                         "\/CharProcs $charProcsObj 0 R\n" .
                         "\/Encoding $encodObj 0 R\n" .
                         '/FirstChar 48' . "\n" .
                         '/LastChar 50' . "\n" .
                         '/Widths [75 75 75]' . "\n>>\nendobj\n";
 
      $font{$Font}[foINTNAMN]  = $fontAbbr;
      $font{$Font}[foREFOBJ]   = $objNr;
      $objRef{$fontAbbr}       = $objNr;
      $objekt[$objNr]          = $pos;
      $aktuellFont[foEXTNAMN]  = $Font;
      $aktuellFont[foREFOBJ]   = $objNr;
      $aktuellFont[foINTNAMN]  = $fontAbbr;
      $pos += syswrite UTFIL, $fontObjekt;
   }
   if (! $pos)
   {  errLog("No output file, you have to call prFile first");
   }
 
   $sidFont{$aktuellFont[foINTNAMN]} = $aktuellFont[foREFOBJ];
}
 
sub createCharProcs()
{   #################################
    # Fonten (objektet) för 0 skapas
    #################################
 
    $objNr++;
    $objekt[$objNr]  = $pos;
    my $tomtObj = $objNr;
    my $str = "\n75 0 d0\n6 0 69 2000 re\n1.0 g\nf\n";
    my $strLength = length($str);
    my $obj = "$objNr 0 obj\n<< /Length $strLength >>\nstream" .
           $str . "\nendstream\nendobj\n";
    $pos += syswrite UTFIL, $obj;
 
    #################################
    # Fonten (objektet) för 1 skapas
    #################################
 
    $objNr++;
    $objekt[$objNr]  = $pos;
    my $streckObj = $objNr;
    $str = "\n75 0 d0\n4 0 71 2000 re\n0.0 g\nf\n";
    $strLength = length($str);
    $obj = "$objNr 0 obj\n<< /Length $strLength >>\nstream" .
           $str . "\nendstream\nendobj\n";
    $pos += syswrite UTFIL, $obj;
 
    ###################################################
    # Fonten (objektet) för 2, ett långt streck skapas
    ###################################################
 
    $objNr++;
    $objekt[$objNr]  = $pos;
    my $lStreckObj = $objNr;
    $str = "\n75 0 d0\n4 -250 71 2250 re\n0.0 g\nf\n";
    $strLength = length($str);
    $obj = "$objNr 0 obj\n<< /Length $strLength >>\nstream" .
           $str . "\nendstream\nendobj\n";
    $pos += syswrite UTFIL, $obj;
 
    #####################################################
    # Objektet för "CharProcs" skapas
    #####################################################
 
    $objNr++;
    $objekt[$objNr]  = $pos;
    my $charProcsObj = $objNr;
    $obj = "$objNr 0 obj\n<</tomt $tomtObj 0 R\n/streck $streckObj 0 R\n" .
           "/lstreck $lStreckObj 0 R>>\nendobj\n";
    $pos += syswrite UTFIL, $obj;
    return $charProcsObj;
}
 
 
 
sub prCid
{   $checkId = shift;
    if ($runfil)
    {  $log .= "Cid~$checkId\n";
    }
    1;
}
 
sub prIdType
{   $idTyp = shift;
    if ($runfil)
    {  $log .= "IdType~rep\n";
    }
    1;
}
 
 
sub prId
{   $id = shift;
    if ($runfil)
    {  $log .= "Id~$id\n";
    }
    if (! $pos)
    {  errLog("No output file, you have to call prFile first");
    }
    1;
}
 
sub prJs
{   my $filNamnIn = shift;
    my $filNamn;
    if ($filNamnIn !~ m'\{'os)
    {  my $checkIdOld = $checkId;
       ($filNamn, $checkId) = findGet($filNamnIn, $checkIdOld);
       if (($runfil) && ($checkId) && ($checkId ne $checkIdOld))
       {  $log .= "Cid~$checkId\n";
       }
       $checkId = '';
    }
    else
    {  $filNamn = $filNamnIn;
    }
    if ($runfil)
    {  my $filnamn = prep($filNamn);
       $log .= "Js~$filnamn\n";
    }
    if (($interAktivSida) || ($interActive))
    {  errLog("Too late, has already tried to merge JAVA SCRIPTS within an interactive page");
    }
    elsif (! $pos)
    {  errLog("Too early for JAVA SCRIPTS, create a file first");
    }
    push @jsfiler, $filNamn;
    1;
}
 
sub prInit
{   my $initText  = shift;
    my $duplicate = shift || '';
    my @fall = ($initText =~ m'([\w\d\_\$]+)\s*\(.*?\)'gs);
    for (@fall)
    {  if (! exists $initScript{$_})
       { $initScript{$_} = 0;
       }
    }
    if ($duplicate)
    {  $duplicateInits = 1;
    }
    push @inits, $initText;
    if ($runfil)
    {   $initText = prep($initText);
        $log .= "Init~$initText~$duplicate\n";
    }
    if (($interAktivSida) || ($interActive))
    {  errLog("Too late, has already tried to create INITIAL JAVA SCRIPTS within an interactive page");
    }
    elsif (! $pos)
    {  errLog("Too early for INITIAL JAVA SCRIPTS, create a file first");
    }
    1;
 
}
 
sub prVers
{   my $vers = shift;
    ############################################################
    # Om programmet körs om så kontrolleras VERSION
    ############################################################
    if ($vers ne $VERSION)
    {  warn  "$vers \<\> $VERSION might give different results, if comparing two runs \n";
       return undef;
    }
    else
    {  return 1;
    }
}
 
sub prDocDir
{  $ddir = findDir(shift);
   1;
}
 
sub prLogDir
{  $ldir = findDir(shift);
   1;
}
 
sub prLog
{  my $mess = shift;
   if ($runfil)
   {  $mess  = prep($mess);
      $log .= "Log~$mess\n";
      return 1;
   }
   else
   {  errLog("You have to give a directory for the logfiles first : prLogDir <dir> , aborts");
   }
 
}
 
sub prGetLogBuffer
{
   return $log;
}
 
sub findDir
{ my $dir = shift;
  if ($dir eq '.')
  { return undef; }
  if (! -e $dir)
   {  mkdir $dir || errLog("Couldn't create directory $dir, $!");
   }
 
  if ((-e $dir) && (-d $dir))
  {  if (substr($dir, length($dir), 1) eq '/')
     {  return $dir; }
     else
     {  return ($dir . '/');
     }
  }
  else
  { errLog("Error finding/creating directory $dir, $!");
  }
}
 
sub prTouchUp
{ $touchUp = shift;
  if ($runfil)
  {  $log .= "TouchUp~$touchUp\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  1;
}
 
sub prCompress
{ $compress = shift;
  if ($runfil)
  {  $log .= "Compress~$compress\n";
  }
  if (! $pos)
  {  errLog("No output file, you have to call prFile first");
  }
  1;
 
}
 
sub prep
{  my $indata = shift;
   $indata =~ s/[\n\r]+/ /sgo;
   $indata =~ s/~/<tilde>/sgo;
   return $indata;
}
 
 
sub xRefs
{  my ($bytes, $infil) = @_;
   my ($j, $nr, $xref, $i, $antal, $inrad, $Root, $tempRoot, $referens);
   my $buf = '';
   %embedded =();
 
   my $res = sysseek INFIL, -50, 2;
   if ($res)
   {  sysread INFIL, $buf, 100;
      if ($buf =~ m'Encrypt'o)
      {  errLog("The file $infil is encrypted, cannot be used, aborts");
      }
      if ($buf =~ m'\bstartxref\s+(\d+)'o)
      {  $xref = $1;
         if ($xref <= $bytes)
         {
            while ($xref)
            {  $res = sysseek INFIL, $xref, 0;
               $res = sysread INFIL, $buf, 200;
               if ($buf =~ m '^\d+\s\d+\sobj'os)
               {  ($xref, $tempRoot, $nr) = crossrefObj($nr, $xref);
               }
               else
               {  ($xref, $tempRoot, $nr) = xrefSection($nr, $xref, $infil);
               }
               if (($tempRoot) && (! $Root))
               {  $Root = $tempRoot;
               }
            }
         }
         else
         {  errLog("Invalid XREF, aborting");
         }
      }
   }
 
   ($Root) || errLog("The Root object in $infil couldn't be found, aborting");
 
   ##############################################################
   # Objekten sorteras i fallande ordning (efter offset i filen)
   ##############################################################
 
   my @offset = sort { $oldObject{$b} <=> $oldObject{$a} } keys %oldObject;
 
   my $saved;
 
   for (@offset)
   {   $saved  = $oldObject{$_};
       $bytes -= $saved;
 
       if ($_ !~ m'^xref'o)
       {   if ($saved == 0)
           {   $oldObject{$_} = [ 0, 0, $embedded{$_}];
           }
           else
           {   $oldObject{$_} = [ $saved, $bytes];
           }
       }
       $bytes = $saved;
   }
   %embedded = ();
   return $Root;
}
 
sub crossrefObj
{   my ($nr, $xref) = @_;
    my ($buf, %param, $len, $tempRoot);
    my $from = $xref;
    sysseek INFIL, $xref, 0;
    sysread INFIL, $buf, 400;
    my $str;
    if ($buf =~ m'^(.+>>\s*)stream'os)
    {  $str = $1;
       $from = length($str) + 7;
       if (substr($buf, $from, 1) eq "\n")
       {  $from++;
       }
       $from += $xref;
    }
 
    for (split('/',$str))
    {  if ($_ =~ m'^(\w+)(.*)'o)
       {  $param{$1} = $2 || ' ';
       }
    }
    if (!exists $param{'Index'})
    {  $param{'Index'} = "[0 $param{'Size'}]";
    }
    if ((exists $param{'Root'}) && ($param{'Root'} =~ m'^\s*(\d+)'o))
    {  $tempRoot = $1;
    }
    my @keys = ($param{'W'} =~ m'(\d+)'og);
    my $keyLength = 0;
    for (@keys)
    {  $keyLength += $_;
    }
    my $recLength = $keyLength + 1;
    my $upTo = 1 + $keys[0] + $keys[1];
    if ((exists $param{'Length'}) && ($param{'Length'} =~ m'(\d+)'o))
    {  $len = $1;
       sysseek INFIL, $from, 0;
       sysread INFIL, $buf, $len;
       my $x = inflateInit()
               || die "Cannot create an inflation stream\n" ;
       my ($output, $status) = $x->inflate(\$buf) ;
       die "inflation failed\n"
                     unless $status == 1;
 
       my $i = 0;
       my @last = (0, 0, 0, 0, 0, 0, 0);
       my @word = ('0', '0', '0', '0', '0', '0', '0');
       my $recTyp;
       my @intervall = ($param{'Index'} =~ m'(\d+)\D'osg);
       my $m = 0;
       my $currObj = $intervall[$m];
       $m++;
       my $max     = $currObj + $intervall[$m];
 
       for (unpack ("C*", $output))
       {  if (($_ != 0) && ($i > 0) && ($i < $upTo))
          {   my $tal = $_ + $last[$i] ;
              if ($tal > 255)
              {$tal -= 256;
              }
 
              $last[$i] = $tal;
              $word[$i] = sprintf("%x", $tal);
              if (length($word[$i]) == 1)
              {  $word[$i] = '0' . $word[$i];
              }
          }
          $i++;
          if ($i == $recLength)
          {  $i = 0;
             my $j = 0;
             my $offsObj;               # offset or object
             if ($keys[0] == 0)
             {  $recTyp = 1;
                $j = 1;
             }
             else
             {  $recTyp = $word[1];
                $j = 2;
             }
             my $k = 0;
             while ($k < $keys[1])
             {  $offsObj .= $word[$j];
                $k++;
                $j++;
             }
 
             if ($recTyp == 1)
             {   if (! (exists $oldObject{$currObj}))
                 {  $oldObject{$currObj} = hex($offsObj); }
                 else
                 {  $nr++;
                    $oldObject{'xref' . "$nr"} = hex($offsObj);
                 }
             }
             elsif ($recTyp == 2)
             {   if (! (exists $oldObject{$currObj}))
                 {  $oldObject{$currObj} = 0;
                 }
                 $embedded{$currObj} = hex($offsObj);
             }
             if ($currObj < $max)
             {  $currObj++;
             }
             else
             {  $m++;
                $currObj = $intervall[$m];
                $m++;
                $max     = $currObj + $intervall[$m];
             }
          }
       }
    }
    return ($param{'Prev'}, $tempRoot, $nr);
}
 
sub xrefSection
{   my ($nr, $xref, $infil) = @_;
    my ($i, $root, $antal);
    $nr++;
    $oldObject{('xref' . "$nr")} = $xref;  # Offset för xref sparas
    $xref += 5;
    sysseek INFIL, $xref, 0;
    $xref  = 0;
    my $inrad = '';
    my $buf   = '';
    my $c;
    sysread INFIL, $c, 1;
    while ($c =~ m!\s!s)
    {  sysread INFIL, $c, 1; }
 
    while ( (defined $c)
    &&   ($c ne "\n")
    &&   ($c ne "\r") )
    {    $inrad .= $c;
         sysread INFIL, $c, 1;
    }
 
    if ($inrad =~ m'^(\d+)\s+(\d+)'o)
    {   $i     = $1;
        $antal = $2;
    }
 
    while ($antal)
    {   for (my $l = 1; $l <= $antal; $l++)
        {  sysread INFIL, $inrad, 20;
           if ($inrad =~ m'^\s?(\d+) \d+ (\w)\s*'o)
           {  if ($2 eq 'n')
              {  if (! (exists $oldObject{$i}))
                 {  $oldObject{$i} = int($1); }
                 else
                 {  $nr++;
                    $oldObject{'xref' . "$nr"} = int($1);
                 }
              }
           }
           $i++;
        }
        undef $antal;
        undef $inrad;
        sysread INFIL, $c, 1;
        while ($c =~ m!\s!s)
        {  sysread INFIL, $c, 1; }
 
        while ( (defined $c)
        &&   ($c ne "\n")
        &&   ($c ne "\r") )
        {    $inrad .= $c;
             sysread INFIL, $c, 1;
        }
        if ($inrad =~ m'^(\d+)\s+(\d+)'o)
        {   $i     = $1;
            $antal = $2;
        }
 
    }
 
    while ($inrad)
    {   $buf .= $inrad;
        if ($buf =~ m'Encrypt'o)
        {  errLog("The file $infil is encrypted, cannot be used, aborts");
        }
        if ((! $root) && ($buf =~ m'\/Root\s+(\d+)\s{1,2}\d+\s{1,2}R'so))
        {  $root = $1;
           if ($xref)
           { last; }
        }
 
        if ((! $xref) && ($buf =~ m'\/Prev\s+(\d+)\D'so))
        {  $xref = $1;
           if ($root)
           { last; }
        }
 
        if ($buf =~ m'xref'so)
        {  last; }
 
        sysread INFIL, $inrad, 30;
    }
    return ($xref, $root, $nr);
}
 
sub getObject
{   my ($nr, $noId, $noEnd) = @_;
 
    my $buf;
    my ($offs, $siz, $embedded) = @{$oldObject{$nr}};
 
    if ($offs)
    {  sysseek INFIL, $offs, 0;
       sysread INFIL, $buf, $siz;
       if (($noId) && ($noEnd))
       {   if ($buf =~ m'^\d+ \d+ obj\s*(.*)endobj'os)
           {   if (wantarray)
               {   return ($1, $offs, $siz, $embedded);
               }
               else
               {   return $1;
               }
           }
       }
       elsif ($noId)
       {   if ($buf =~ m'^\d+ \d+ obj\s*(.*)'os)
           {   if (wantarray)
               {   return ($1, $offs, $siz, $embedded);
               }
               else
               {   return $1;
               }
           }
       }
       if (wantarray)
       {   return ($buf, $offs, $siz, $embedded)
       }
       else
       {   return $buf;
       }
    }
    elsif (exists $unZipped{$nr})
    {  ;
    }
    elsif ($embedded)
    {   unZipPrepare($embedded);
    }
    if ($noEnd)
    {   if (wantarray)
        {   return ($unZipped{$nr}, $offs, $siz, $embedded)
        }
        else
        {   return $unZipped{$nr};
        }
    }
    else
    {   if (wantarray)
        {   return ("$unZipped{$nr}endobj\n", $offs, $siz, $embedded)
        }
        else
        {   return "$unZipped{$nr}endobj\n";
        }
    }
}
 
sub getKnown
{   my ($p, $nr) = @_;
    my ($del1, $del2);
    my @objData = @{$$$p[0]->{$nr}};
    if (defined $objData[oSTREAMP])
    {  sysseek INFIL, ($objData[oNR][0] + $objData[oPOS]), 0;
       sysread INFIL, $del1, ($objData[oSTREAMP] - $objData[oPOS]);
       sysread INFIL, $del2, ($objData[oNR][1]   - $objData[oSTREAMP]);
    }
    else
    {  my $buf;
       my ($offs, $siz, $embedded) = @{$objData[oNR]};
       if ($offs)
       {  sysseek INFIL, $offs, 0;
          sysread INFIL, $buf, $siz;
          if ($buf =~ m'^\d+ \d+ obj\s*(.*)'os)
          {   $del1 = $1;
          }
       }
       elsif (exists $unZipped{$nr})
       {  $del1 = "$unZipped{$nr} endobj";
       }
       elsif ($embedded)
       {   @objData = @{$$$p[0]->{$embedded}};
           unZipPrepare($embedded, $objData[oNR][0], $objData[oNR][1]);
           $del1 = "$unZipped{$nr} endobj";
       }
    }
    return (\$del1, \$del2, $objData[oKIDS], $objData[oTYPE]);
}
 
 
sub unZipPrepare
{  my ($nr, $offs, $size) = @_;
   my $buf;
   if ($offs)
   {   sysseek INFIL, $offs, 0;
       sysread INFIL, $buf, $size;
   }
   else
   {   $buf = getObject($nr);
   }
   my (%param, $stream, $str);
 
   if ($buf =~ m'^(\d+ \d+ obj\s*<<[\w\d\/\s\[\]<>]+)stream\b'os)
   {  $str  = $1;
      $offs = length($str) + 7;
      if (substr($buf, $offs, 1) eq "\n")
      {  $offs++;
      }
 
      for (split('/',$str))
      {  if ($_ =~ m'^(\w+)(.*)'o)
         {  $param{$1} = $2 || ' ';
         }
      }
      $stream = substr($buf, $offs, $param{'Length'});
      my $x = inflateInit()
           || die "Cannot create an inflation stream\n";
      my ($output, $status) = $x->inflate($stream);
      die "inflation failed\n"
                     unless $status == 1;
 
      my $first = $param{'First'};
      my @oOffsets = (substr($output, 0, $first) =~ m'(\d+)\b'osg);
      my $i = 0;
      my $j = 1;
      my $bytes;
      while ($oOffsets[$i])
      {  my $k = $j + 2;
         if ($oOffsets[$k])
         {  $bytes = $oOffsets[$k] - $oOffsets[$j];
         }
         else
         {  $bytes = length($output) - $first - $oOffsets[$j];
         }
         $unZipped{$oOffsets[$i]} = substr($output,($first + $oOffsets[$j]), $bytes);
         $i += 2;
         $j += 2;
      }
   }
}
 
############################################
# En definitionerna för en sida extraheras
############################################
 
sub getPage
{  my ($infil, $sidnr, $action)  = @_;
 
   my ($res, $i, $referens,$objNrSaved,$validStream, $formRes, @objData,
       @underObjekt, @sidObj, $strPos, $startSida, $sidor, $filId, $del1, $del2,
       $offs, $siz, $embedded, $vektor, $utrad, $robj, $valid, $Annots, $Names,
       $AcroForm, $AARoot, $AAPage);
 
   my $sidAcc = 0;
   my $seq    = 0;
   $imSeq     = 0;
   @skapa     = ();
   undef $formCont;
 
 
   $objNrSaved = $objNr;
   my $fSource = $infil . '_' . $sidnr;
   my $checkidOld = $checkId;
   ($infil, $checkId) = findGet($infil, $checkidOld);
   if (($ldir) && ($checkId) && ($checkId ne $checkidOld))
   {  $log .= "Cid~$checkId\n";
   }
   $form{$fSource}[fID] =  $checkId;
   $checkId = '';
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
 
   if ($action eq 'print')
   {  *old = $behandlad{$infil}->{old};
   }
   else
   {  $behandlad{$infil}->{dummy} = {};
      *old = $behandlad{$infil}->{dummy};
   }
 
   *oldObject =  $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
   $root      = (exists $processed{$infil}->{root})
                    ? $processed{$infil}->{root} : 0;
 
 
   my @stati = stat($infil);
   open (INFIL, "<$infil") || errLog("Couldn't open $infil, $!");
   binmode INFIL;
 
   if (! $root)
   {  $root = xRefs($stati[7], $infil);
   }
 
   #############
   # Hitta root
   #############
 
   my $objektet = getObject($root);;
 
   if ($sidnr == 1)
   {  if ($objektet =~ m'/AcroForm(\s+\d+\s{1,2}\d+\s{1,2}R)'so)
      {  $AcroForm = $1;
      }
      if ($objektet =~ m'/Names\s+(\d+)\s{1,2}\d+\s{1,2}R'so)
      {  $Names = $1;
      }
      #################################################
      #  Finns ett dictionary för Additional Actions ?
      #################################################
      if ($objektet =~ m'/AA\s*\<\<\s*[^\>]+[^\>]+'so) # AA är ett dictionary
      {  my $k;
         my ($dummy, $obj) = split /\/AA/, $objektet;
         $obj =~ s/\<\</\#\<\</gs;
         $obj =~ s/\>\>/\>\>\#/gs;
         my @ord = split /\#/, $obj;
         for ($i = 0; $i <= $#ord; $i++)
         {   $AARoot .= $ord[$i];
             if ($ord[$i] =~ m'\S+'os)
             {  if ($ord[$i] =~ m'<<'os)
                {  $k++; }
                if ($ord[$i] =~ m'>>'os)
                {  $k--; }
                if ($k == 0)
                {  last; }
             }
          }
      }
   }
 
   #
   # Hitta pages
   #
 
   if ($objektet =~ m'/Pages\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
   {  $objektet = getObject($1);
      if ($objektet =~ m'/Count\s+(\d+)'os)
      {  $sidor = $1;
         if ($sidnr <= $sidor)
         {  ($formRes, $valid) = kolla($objektet);
         }
         else
         {   return 0;
         }
         if ($sidor > 1)
         {   undef $AcroForm;
             undef $Names;
             undef $AARoot;
             if ($type eq 'docform')
             {  errLog("prDocForm can only be used for single page documents - try prDoc or reformat $infil");
             }
         }
      }
   }
   else
   { errLog("Didn't find Pages in $infil - aborting"); }
 
   if ($objektet =~ m'/Kids\s*\[([^\]]+)'os)
   {  $vektor = $1; }
   while ($vektor =~ m'(\d+)\s{1,2}\d+\s{1,2}R'go)
   {   push @sidObj, $1;
   }
 
   my $bryt1 = -20;                     # Hängslen
   my $bryt2 = -20;                     # Svångrem för att undvika oändliga loopar
 
   while ($sidAcc < $sidnr)
   {  @underObjekt = @sidObj;
      @sidObj     = ();
      $bryt1++;
      for my $uO (@underObjekt)
      {  $objektet = getObject($uO);
         if ($objektet =~ m'/Count\s+(\d+)'os)
         {  if (($sidAcc + $1) < $sidnr)
            {  $sidAcc += $1; }
            else
            {  ($formRes, $valid) = kolla($objektet, $formRes);
               if ($objektet =~ m'/Kids\s*\[([^\]]+)'os)
               {  $vektor = $1; }
               while ($vektor =~ m'(\d+)\s{1,2}\d+\s{1,2}R'gso)
               {   push @sidObj, $1;  }
               last;
            }
         }
         else
         {  $sidAcc++; }
         if ($sidAcc == $sidnr)
         {   $seq = $uO;
             last;  }
         $bryt2++;
      }
      if (($bryt1 > $sidnr) || ($bryt2 > $sidnr))   # Bryt oändliga loopar
      {  last; }
   }
 
   ($formRes, $validStream) = kolla($objektet, $formRes);
   $startSida = $seq;
 
   if ($sidor == 1)
   {  #################################################
      # Kontrollera Page-objektet för annoteringar
      #################################################
 
      if ($objektet =~ m'/Annots\s*([^\/]+)'so)
      {  $Annots = $1;
      }
      #################################################
      #  Finns ett dictionary för Additional Actions ?
      #################################################
      if ($objektet =~ m'/AA\s*\<\<\s*[^\>]+[^\>]+'so)  # AA är ett dictionary. Hela kopieras
      {  my $k;
         my ($dummy, $obj) = split /\/AA/, $objektet;
         $obj =~ s/\<\</\#\<\</gs;
         $obj =~ s/\>\>/\>\>\#/gs;
         my @ord = split /\#/, $obj;
         for ($i = 0; $i <= $#ord; $i++)
         {   $AAPage .= $ord[$i];
             if ($ord[$i] =~ m'\S+'s)
             {  if ($ord[$i] =~ m'<<'s)
                {  $k++; }
                if ($ord[$i] =~ m'>>'s)
                {  $k--; }
                if ($k == 0)
                {  last; }
             }
          }
      }
   }
 
   my $rform = \$form{$fSource};
   @$$rform[fRESOURCE]  = $formRes;
   my @BBox;
   if (defined $formBox[0])
   {  $BBox[0] = $formBox[0]; }
   else
   {  $BBox[0] = $genLowerX; }
 
   if (defined $formBox[1])
   {  $BBox[1] = $formBox[1]; }
   else
   {  $BBox[1] = $genLowerY; }
 
   if (defined $formBox[2])
   {  $BBox[2] = $formBox[2]; }
   else
   {  $BBox[2] = $genUpperX; }
 
   if (defined $formBox[3])
   {  $BBox[3] = $formBox[3]; }
   else
   {  $BBox[3] = $genUpperY; }
 
   @{$form{$fSource}[fBBOX]} = @BBox;
 
   if ($formCont)
   {   $seq = $formCont;
       ($objektet, $offs, $siz, $embedded) = getObject($seq);
 
       $robj  = \$$$rform[fOBJ]->{$seq};
       @{$$$robj[oNR]} = ($offs, $siz, $embedded);
       $$$robj[oFORM] = 'Y';
       $form{$fSource}[fMAIN] = $seq;
       if ($objektet =~ m'^(\d+ \d+ obj\s*<<)(.+)(>>\s*stream)'so)
       {  $del1   = $2;
          $strPos           = length($1) + length($2) + length($3);
          $$$robj[oPOS]     = length($1);
          $$$robj[oSTREAMP] = $strPos;
          my $nyDel1;
          $nyDel1 = '<</Type/XObject/Subtype/Form/FormType 1';
          $nyDel1 .= "/Resources $formRes" .
                     "/BBox \[ $BBox[0] $BBox[1] $BBox[2] $BBox[3]\]" .
                     # "/Matrix \[ 1 0 0 1 0 0 \]" .
                     $del1;
          if ($action eq 'print')
          {  $objNr++;
             $objekt[$objNr] = $pos;
          }
          $referens = $objNr;
 
          $res = ($nyDel1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs);
          if ($res)
          { $$$robj[oKIDS] = 1; }
          if ($action eq 'print')
          {   $utrad  = "$referens 0 obj\n" . "$nyDel1" . ">>\nstream";
              $del2   = substr($objektet, $strPos);
              $utrad .= $del2;
              $pos   += syswrite UTFIL, $utrad;
          }
          $form{$fSource}[fVALID] = $validStream;
      }
      else                              # Endast resurserna kan behandlas
      {   $formRes =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
      }
   }
   else                                # Endast resurserna kan behandlas
   {  $formRes =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   }
 
   my $preLength;
   while (scalar @skapa)
   {  my @process = @skapa;
      @skapa = ();
      for (@process)
      {  my $Font;
         my $gammal = $$_[0];
         my $ny     = $$_[1];
         ($objektet, $offs, $siz, $embedded)  = getObject($gammal);
         $robj      = \$$$rform[fOBJ]->{$gammal};
         @{$$$robj[oNR]} = ($offs, $siz, $embedded);
         if ($objektet =~ m'^(\d+ \d+ obj\s*<<)(.+)(>>\s*stream)'os)
         {  $del1             = $2;
            $strPos           = length ($1) + length($2) + length($3);
            $$$robj[oPOS]     = length($1);
            $$$robj[oSTREAMP] = $strPos;
 
            ######## En bild ########
            if ($del1 =~ m'/Subtype\s*/Image'so)
            {  $imSeq++;
               $$$robj[oIMAGENR] = $imSeq;
               push @{$$$rform[fIMAGES]}, $gammal;
 
               if ($del1 =~ m'/Width\s+(\d+)'os)
               {  $$$robj[oWIDTH] = $1; }
               if ($del1 =~ m'/Height\s+(\d+)'os)
               {  $$$robj[oHEIGHT] = $1; }
            }
            $res = ($del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs);
            if ($res)
            { $$$robj[oKIDS] = 1; }
            if ($action eq 'print')
            {   $objekt[$ny] = $pos;
                $utrad  = "$ny 0 obj\n<<" . "$del1" . '>>stream';
                $del2   = substr($objektet, $strPos);
                $utrad .= $del2;
            }
         }
         else
         {  if ($objektet =~ m'^(\d+ \d+ obj\s*)'os)
            {  $preLength = length($1);
               $$$robj[oPOS] = $preLength;
               $objektet     = substr($objektet, $preLength);
            }
            else
            {  $$$robj[oPOS] = 0;
            }
            $res = ($objektet =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs);
            if ($res)
            { $$$robj[oKIDS] = 1; }
            if ($objektet =~ m'/Subtype\s*/Image'so)
            {  $imSeq++;
               $$$robj[oIMAGENR] = $imSeq;
               push @{$$$rform[fIMAGES]}, $gammal;
               ###################################
               # Sparar dimensionerna för bilden
               ###################################
               if ($del1 =~ m'/Width\s+(\d+)'os)
               {  $$$robj[oWIDTH] = $1; }
 
               if ($del1 =~ m'/Height\s+(\d+)'os)
               {  $$$robj[oHEIGHT] = $1; }
            }
            elsif ($objektet =~ m'/BaseFont\s*/([^\s\/]+)'os)
            {  $Font = $1;
               $$$robj[oTYPE] = 'Font';
               $$$robj[oNAME] = $Font;
               if ((! exists $font{$Font})
               && ($action))
               {  $fontNr++;
                  $font{$Font}[foINTNAMN]          = 'Ft' . $fontNr;
                  $font{$Font}[foORIGINALNR]       = $gammal;
                  $fontSource{$Font}[foSOURCE]     = $fSource;
                  $fontSource{$Font}[foORIGINALNR] = $gammal;
                  if ($objektet =~ m'/Subtype\s*/Type0'os)
                  {  $font{$Font}[foTYP] = 1;
                  }
                  if ($action eq 'print')
                  {  $font{$Font}[foREFOBJ]  = $ny;
                     $objRef{'Ft' . $fontNr} = $ny;
                  }
               }
            }
 
            if ($action eq 'print')
            {   $objekt[$ny] = $pos;
                $utrad = "$ny 0 obj $objektet";
            }
         }
         if ($action eq 'print')
         {   $pos += syswrite UTFIL, $utrad;
         }
       }
   }
 
   my $ref = \$form{$fSource};
   my @kids;
   my @nokids;
 
   #################################################################
   # lägg upp vektorer över vilka objekt som har KIDS eller NOKIDS
   #################################################################
 
   for my $key (keys %{$$$ref[fOBJ]})
   {   $robj  = \$$$ref[fOBJ]->{$key};
       if (! defined  $$$robj[oFORM])
       {   if (defined  $$$robj[oKIDS])
           {   push @kids, $key; }
           else
           {   push @nokids, $key; }
       }
       if ((defined $$$robj[0]->[2]) && (! exists $$$ref[fOBJ]->{$$$robj[0]->[2]}))
       {  $$$ref[fOBJ]->{$$$robj[0]->[2]}->[0] = $oldObject{$$$robj[0]->[2]};
       }
   }
   if (scalar @kids)
   {  $form{$fSource}[fKIDS] = \@kids;
   }
   if (scalar @nokids)
   {  $form{$fSource}[fNOKIDS] = \@nokids;
   }
 
   if ($action ne 'print')
   {  $objNr = $objNrSaved;            # Restore objNo if nothing was printed
   }
 
   $behandlad{$infil}->{dummy} = {};
   *old = $behandlad{$infil}->{dummy};
 
   $objNrSaved = $objNr;               # Save objNo
 
   if ($sidor == 1)
   {   @skapa = ();
       $old{$startSida} = $sidObjNr;
       my $ref = \$intAct{$fSource};
       @$$ref[iSTARTSIDA] = $startSida;
       if (defined $Names)
       {   @$$ref[iNAMES] = $Names;
           quickxform($Names);
       }
       if (defined $AcroForm)
       {   @$$ref[iACROFORM] = $AcroForm;
           $AcroForm =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
       }
       if (defined $AARoot)
       {   @$$ref[iAAROOT] = $AARoot;
           $AARoot =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
       }
       if (defined $AAPage)
       {   @$$ref[iAAPAGE] = $AAPage;
           $AAPage =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
       }
       if (defined $Annots)
       {   my @array;
           if ($Annots =~ m'\[([^\[\]]*)\]'os)
           {  $Annots = $1;
              @array = ($Annots =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'ogs);
           }
           else
           {  if ($Annots =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'os)
              {  $Annots = getObject($1);
                 @array = ($Annots =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'ogs);
              }
           }
           @$$ref[iANNOTS] = \@array;
           $Annots =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
       }
 
      while (scalar @skapa)
      {  my @process = @skapa;
         @skapa = ();
         for (@process)
         {  my $gammal = $$_[0];
            my $ny     = $$_[1];
            ($objektet, $offs, $siz, $embedded) = getObject($gammal);
            $robj  = \$$$ref[fOBJ]->{$gammal};
            @{$$$robj[oNR]} = ($offs, $siz, $embedded);
            if ($objektet =~ m'^(\d+ \d+ obj\s*<<)(.+)(>>\s*stream)'os)
            {  $del1             = $2;
               $$$robj[oPOS]     = length($1);
               $$$robj[oSTREAMP] = length($1) + length($2) + length($3);
 
               $res = ($del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs);
               if ($res)
               { $$$robj[oKIDS] = 1; }
            }
            else
            {  if ($objektet =~ m'^(\d+ \d+ obj)'os)
               {  my $preLength = length($1);
                  $$$robj[oPOS] = $preLength;
                  $objektet = substr($objektet, $preLength);
 
                  $res = ($objektet =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs);
                  if ($res)
                  { $$$robj[oKIDS] = 1; }
                }
             }
         }
      }
      for my $key (keys %{$$$ref[fOBJ]})
      {   $robj  = \$$$ref[fOBJ]->{$key};
          if ((defined $$$robj[0]->[2]) && (! exists $$$ref[fOBJ]->{$$$robj[0]->[2]}))
          {  $$$ref[fOBJ]->{$$$robj[0]->[2]}->[0] = $oldObject{$$$robj[0]->[2]};
          }
      }
  }
 
  $objNr = $objNrSaved;
  $processed{$infil}->{root}         = $root;
  close INFIL;
  return $referens;
}
 
##################################################
# Översätter ett gammalt objektnr till ett nytt
# och sparar en tabell med vad som skall skapas
##################################################
 
sub xform
{  if (exists $old{$1})
   {  $old{$1};
   }
   else
   {  push @skapa, [$1, ++$objNr];
      $old{$1} = $objNr;
   }
}
 
sub kolla
{  #
   # Resurser
   #
   my $obj       = shift;
   my $resources = shift;
   my $valid;
 
   if ($obj =~ m'MediaBox\s*\[\s*([\-\.\d]+)\s+([\-\.\d]+)\s+([\-\.\d]+)\s+([\-\.\d]+)'os)
   { $formBox[0] = $1;
     $formBox[1] = $2;
     $formBox[2] = $3;
     $formBox[3] = $4;
   }
 
   if ($obj =~ m'/Contents\s+(\d+)'so)
   {  $formCont = $1;
      my $cObj = getObject($formCont, 1, 1);
      if ($cObj =~ m'^\s*\[[^\]]+\]\s*$'os)
      {   $valid = 0;
          undef $formCont;
      }
      else
      {   $valid    = 1;
      }
   }
   elsif ($obj =~ m'/Contents\s*\[\s*(\d+)\s{1,2}\d+\s{1,2}R\s*\]'so)
   { $formCont = $1;
     $valid    = 1;
   }
 
   if ($obj =~ m'^(.+/Resources)'so)
   {  if ($obj =~ m'Resources(\s+\d+\s{1,2}\d+\s{1,2}R)'os)   # Hänvisning
      {  $resources = $1; }
      else                 # Resurserna är ett dictionary. Hela kopieras
      {  my $dummy;
         my $i;
         my $k;
         undef $resources;
         ($dummy, $obj) = split /\/Resources/, $obj;
         $obj =~ s/\<\</\#\<\</gs;
         $obj =~ s/\>\>/\>\>\#/gs;
         my @ord = split /\#/, $obj;
         for ($i = 0; $i <= $#ord; $i++)
         {   $resources .= $ord[$i];
             if ($ord[$i] =~ m'\S+'s)
             {  if ($ord[$i] =~ m'<<'s)
                {  $k++; }
                if ($ord[$i] =~ m'>>'s)
                {  $k--; }
                if ($k == 0)
                {  last; }
             }
          }
       }
    }
    return ($resources, $valid);
}
 
##############################
# Ett formulär (åter)skapas
##############################
 
sub byggForm
{  no warnings;
   my ($infil, $sidnr) = @_;
 
   my ($res, $corr, $nyDel1, $formRes, $del1, $del2, $kids, $typ, $nr,
       $utrad);
 
   my $fSource = $infil . '_' . $sidnr;
   my @stati = stat($infil);
 
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
 
   *old       = $behandlad{$infil}->{old};
   *oldObject = $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
 
   if ($form{$fSource}[fID] != $stati[9])
   {    errLog("$stati[9] ne $form{$fSource}[fID] aborts");
   }
   if ($checkId)
   {  if ($checkId ne $stati[9])
      {  my $mess =  "$checkId \<\> $stati[9] \n"
                  . "The Pdf-file $fSource has not the correct modification time. \n"
                  .  "The program is aborted";
         errLog($mess);
      }
      undef $checkId;
    }
    if ($ldir)
    {  $log .= "Cid~$stati[9]\n";
    }
 
   open (INFIL, "<$infil") || errLog("The file $infil couldn't be opened, aborting $!");
   binmode INFIL;
 
   ####################################################
   # Objekt utan referenser  kopieras och skrivs
   ####################################################
 
   for my $key (@{$form{$fSource}->[fNOKIDS]})
   {   if ((defined $old{$key}) && ($objekt[$old{$key}]))    # already processed
       {  next;
       }
 
       if (! defined $old{$key})
       {  $old{$key} = ++$objNr;
       }
       $nr = $old{$key};
       $objekt[$nr] = $pos;
 
       ($del1, $del2, $kids, $typ) = getKnown(\$form{$fSource},$key);
 
       if ($typ eq 'Font')
       {  my $Font = ${$form{$fSource}}[0]->{$key}->[oNAME];
          if (! defined $font{$Font}[foINTNAMN])
          {  $fontNr++;
             $font{$Font}[foINTNAMN]  = 'Ft' . $fontNr;
             $font{$Font}[foREFOBJ]   = $nr;
             $objRef{'Ft' . $fontNr}  = $nr;
          }
       }
       if (! defined $$del2)
       {   $utrad = "$nr 0 obj " . $$del1;
       }
       else
       {   $utrad = "$nr 0 obj\n<<" . $$del1 . $$del2;
       }
       $pos += syswrite UTFIL, $utrad;
   }
 
   #######################################################
   # Objekt med referenser kopieras, behandlas och skrivs
   #######################################################
   for my $key (@{$form{$fSource}->[fKIDS]})
   {   if ((defined $old{$key}) && ($objekt[$old{$key}]))  # already processed
       {  next;
       }
 
       if (! defined $old{$key})
       {  $old{$key} = ++$objNr;
       }
       $nr = $old{$key};
 
       $objekt[$nr] = $pos;
 
       ($del1, $del2, $kids, $typ) = getKnown(\$form{$fSource},$key);
 
       $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/translate() . ' 0 R'/oegs;
 
       if (defined $$del2)
       {  $utrad = "$nr 0 obj\n<<" . $$del1 . $$del2;
       }
       else
       {  $utrad = "$nr 0 obj " . $$del1;
       }
 
       if (($typ) && ($typ eq 'Font'))
       {  my $Font = $form{$fSource}[0]->{$key}->[oNAME];
          if (! defined $font{$Font}[foINTNAMN])
          {  $fontNr++;
             $font{$Font}[foINTNAMN]  = 'Ft' . $fontNr;
             $font{$Font}[foREFOBJ]   = $nr;
             $objRef{'Ft' . $fontNr} = $nr;
          }
       }
 
       $pos += syswrite UTFIL, $utrad;
   }
 
   #################################
   # Formulärobjektet behandlas
   #################################
 
   my $key = $form{$fSource}->[fMAIN];
   if (! defined $key)
   {  return undef;
   }
 
   if (exists $old{$key})                      # already processed
   {  close INFIL;
      return $old{$key};
   }
 
   $nr = ++$objNr;
 
   $objekt[$nr] = $pos;
 
   $formRes = $form{$fSource}->[fRESOURCE];
 
   ($del1, $del2) = getKnown(\$form{$fSource}, $key);
 
   $nyDel1 = '<</Type/XObject/Subtype/Form/FormType 1';
   $nyDel1 .= "/Resources $formRes" .
                 '/BBox [' .
                 $form{$fSource}->[fBBOX]->[0]  . ' ' .
                 $form{$fSource}->[fBBOX]->[1]  . ' ' .
                 $form{$fSource}->[fBBOX]->[2]  . ' ' .
                 $form{$fSource}->[fBBOX]->[3]  . ' ]' .
                 # "\]/Matrix \[ $sX 0 0 $sX $tX $tY \]" .
                 $$del1;
   $nyDel1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/translate() . ' 0 R'/oegs;
 
   $utrad = "$nr 0 obj" . $nyDel1 . $$del2;
 
   $pos += syswrite UTFIL, $utrad;
   close INFIL;
 
   return $nr;
}
 
##################
#  En bild läses
##################
 
sub getImage
{  my ($infil, $sidnr, $bildnr, $key) =  @_;
   if (! defined $key)
   {  errLog("Can't find image $bildnr on page $sidnr in file $infil, aborts");
   }
 
   @skapa = ();
   my ($res, $corr, $nyDel1, $del1, $del2, $nr, $utrad);
   my $fSource = $infil . '_' . $sidnr;
   my $iSource = $fSource . '_' . $bildnr;
 
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
 
   *old       = $behandlad{$infil}->{old};
   *oldObject = $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
 
   my @stati = stat($infil);
 
   if ($form{$fSource}[fID] != $stati[9])
   {    errLog("$stati[9] ne $form{$fSource}[fID], modification time has changed, aborting");
   }
 
   if (exists $old{$key})
   {  return $old{$key};
   }
 
   open (INFIL, "<$infil") || errLog("The file $infil couldn't be opened, $!");
   binmode INFIL;
 
   #########################################################
   # En bild med referenser kopieras, behandlas och skrivs
   #########################################################
 
   $nr = ++$objNr;
   $old{$key} = $nr;
 
   $objekt[$nr] = $pos;
 
   ($del1, $del2) = getKnown(\$form{$fSource}, $key);
 
   $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   if (defined $$del2)
   {  $utrad = "$nr 0 obj\n<<" . $$del1 . $$del2;
   }
   else
   {  $utrad = "$nr 0 obj " . $$del1;
   }
   $pos += syswrite UTFIL, $utrad;
   ##################################
   #  Skriv ut underordnade objekt
   ##################################
   while (scalar @skapa)
   {  my @process = @skapa;
      @skapa = ();
      for (@process)
      {  my $gammal = $$_[0];
         my $ny     = $$_[1];
 
         ($del1, $del2) = getKnown(\$form{$fSource}, $gammal);
 
         $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
         if (defined $$del2)
         {  $utrad = "$ny 0 obj\n<<" . $$del1 . $$del2;
         }
         else
         {  $utrad = "$ny 0 obj " . $$del1;
         }
         $objekt[$ny] = $pos;
         $pos += syswrite UTFIL, $utrad;
      }
   }
 
   close INFIL;
   return $nr;
 
}
 
##############################################################
#  Interaktiva funktioner knutna till ett formulär återskapas
##############################################################
 
sub AcroFormsEtc
{  my ($infil, $sidnr) =  @_;
 
   my ($Names, $AARoot, $AAPage, $AcroForm);
   @skapa = ();
 
   my ($res, $corr, $nyDel1, @objData, $del1, $del2, $utrad);
   my $fSource = $infil . '_' . $sidnr;
 
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
 
   *old       = $behandlad{$infil}->{old};
   *oldObject = $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
 
   my @stati = stat($infil);
   if ($form{$fSource}[fID] != $stati[9])
   {    print "$stati[9] ne $form{$fSource}[fID]\n";
        errLog("Modification time for $fSource has changed, aborting");
   }
 
   open (INFIL, "<$infil") || errLog("The file $infil couldn't be opened, aborting $!");
   binmode INFIL;
 
   my $fdSidnr = $intAct{$fSource}[iSTARTSIDA];
   $old{$fdSidnr} = $sidObjNr;
 
   if (($intAct{$fSource}[iNAMES]) ||(scalar @jsfiler) || (scalar @inits) || (scalar %fields))
   {  $Names  = behandlaNames($intAct{$fSource}[iNAMES], $fSource);
   }
 
   ##################################
   # Referenser behandlas och skrivs
   ##################################
 
   if (defined $intAct{$fSource}[iACROFORM])
   {   $AcroForm = $intAct{$fSource}[iACROFORM];
       $AcroForm =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   }
   if (defined $intAct{$fSource}[iAAROOT])
   {  $AARoot = $intAct{$fSource}[iAAROOT];
      $AARoot =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   }
 
   if (defined $intAct{$fSource}[iAAPAGE])
   {   $AAPage = $intAct{$fSource}[iAAPAGE];
       $AAPage =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   }
   if (defined $intAct{$fSource}[iANNOTS])
   {  for (@{$intAct{$fSource}[iANNOTS]})
      {  push @annots, quickxform($_);
      }
   }
 
   ##################################
   #  Skriv ut underordnade objekt
   ##################################
   while (scalar @skapa)
   {  my @process = @skapa;
      @skapa = ();
      for (@process)
      {  my $gammal = $$_[0];
         my $ny     = $$_[1];
 
         my $oD   = \@{$intAct{$fSource}[0]->{$gammal}};
         @objData = @{$$oD[oNR]};
 
         if (defined $$oD[oSTREAMP])
         {  $res = sysseek INFIL, ($objData[0] + $$oD[oPOS]), 0;
            $corr = sysread INFIL, $del1, ($$oD[oSTREAMP] - $$oD[oPOS]) ;
            if (defined  $$oD[oKIDS])
            {   $del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
            }
            $res = sysread INFIL, $del2, ($objData[1] - $corr);
            $utrad = "$ny 0 obj\n<<" . $del1 . $del2;
         }
         else
         {  $del1 = getObject($gammal);
            $del1 = substr($del1, $$oD[oPOS]);
            if (defined  $$oD[oKIDS])
            {   $del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
            }
            $utrad = "$ny 0 obj " . $del1;
         }
 
         $objekt[$ny] = $pos;
         $pos += syswrite UTFIL, $utrad;
      }
   }
 
   close INFIL;
   return ($Names, $AARoot, $AAPage, $AcroForm);
}
 
##############################
# Ett namnobjekt extraheras
##############################
 
sub extractName
{  my ($infil, $sidnr, $namn) = @_;
 
   my ($res, $del1, $resType, $key, $corr, $formRes, $kids, $nr, $utrad);
   my $del2 = '';
   @skapa = ();
 
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
 
   *old       = $behandlad{$infil}->{old};
   *oldObject = $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
 
   my $fSource = $infil . '_' . $sidnr;
 
   my @stati = stat($infil);
 
   if ($form{$fSource}[fID] != $stati[9])
   {    errLog("$stati[9] ne $form{$fSource}[fID] aborts");
   }
   if ($checkId)
   {  if ($checkId ne $stati[9])
      {  my $mess =  "$checkId \<\> $stati[9] \n"
                  . "The Pdf-file $fSource has not the correct modification time. \n"
                  .  "The program is aborted";
         errLog($mess);
      }
      undef $checkId;
    }
    if ($ldir)
    {  $log .= "Cid~$stati[9]\n";
    }
 
   open (INFIL, "<$infil") || errLog("The file $infil couldn't be opened, aborting $!");
   binmode INFIL;
 
   #################################
   # Resurserna läses
   #################################
 
   $formRes = $form{$fSource}->[fRESOURCE];
 
   if ($formRes !~ m'<<.*>>'os)                   # If not a directory, get it
   {   if ($formRes =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R'o)
       {  $key   = $1;
          $formRes = getKnown(\$form{$fSource}, $key);
       }
       else
       {  return undef;
       }
   }
   undef $key;
   while ($formRes =~ m'\/(\w+)\s*\<\<([^>]+)\>\>'osg)
   {   $resType = $1;
       my $str  = $2;
       if ($str =~ m|$namn\s+(\d+)\s{1,2}\d+\s{1,2}R|s)
       {   $key = $1;
           last;
       }
   }
   if (! defined $key)                      # Try to expand the references
   {   my ($str, $del1, $del2);
       while ($formRes =~ m'(\/\w+)\s+(\d+)\s{1,2}\d+\s{1,2}R'ogs)
       { $str .= $1 . ' ';
         ($del1, $del2) = getKnown(\$form{$fSource}, $2);
         my $string =  $$del1;
         $str .= $string . ' ';
       }
       $formRes = $str;
       while ($formRes =~ m'\/(\w+)\s*\<\<([^>]+)\>\>'osg)
       {   $resType = $1;
           my $str  = $2;
           if ($str =~ m|$namn (\d+)\s{1,2}\d+\s{1,2}R|s)
           {   $key = $1;
               last;
           }
       }
       return undef unless $key;
   }
 
   ########################################
   #  Read the top object of the hierarchy
   ########################################
 
   ($del1, $del2) = getKnown(\$form{$fSource}, $key);
 
   $objNr++;
   $nr = $objNr;
 
   if ($resType eq 'Font')
   {  my ($Font, $extNamn);
      if ($$del1 =~ m'/BaseFont\s*/([^\s\/]+)'os)
      {  $extNamn = $1;
         if (! exists $font{$extNamn})
         {  $fontNr++;
            $Font = 'Ft' . $fontNr;
            $font{$extNamn}[foINTNAMN]       = $Font;
            $font{$extNamn}[foORIGINALNR]    = $nr;
            if ($del1 =~ m'/Subtype\s*/Type0'os)
            {  $font{$extNamn}[foTYP] = 1;
            }
            $fontSource{$Font}[foSOURCE]     = $fSource;
            $fontSource{$Font}[foORIGINALNR] = $nr;
         }
         $font{$extNamn}[foREFOBJ]   = $nr;
         $Font = $font{$extNamn}[foINTNAMN];
         $namn = $Font;
         $objRef{$Font}  = $nr;
      }
      else
      {  errLog("Inconsitency in $fSource, font $namn can't be found, aborting");
      }
   }
   elsif ($resType eq 'ColorSpace')
   {  $colorSpace++;
      $namn = 'Cs' . $colorSpace;
      $objRef{$namn} = $nr;
   }
   elsif ($resType eq 'Pattern')
   {  $pattern++;
      $namn = 'Pt' . $pattern;
      $objRef{$namn} = $nr;
   }
   elsif ($resType eq 'Shading')
   {  $shading++;
      $namn = 'Sh' . $shading;
      $objRef{$namn} = $nr;
   }
   elsif ($resType eq 'ExtGState')
   {  $gSNr++;
      $namn = 'Gs' . $gSNr;
      $objRef{$namn} = $nr;
   }
   elsif ($resType eq 'XObject')
   {  if (defined $form{$fSource}->[0]->{$nr}->[oIMAGENR])
      {  $namn = 'Ig' . $form{$fSource}->[0]->{$nr}->[oIMAGENR];
      }
      else
      {  $formNr++;
         $namn = 'Fo' . $formNr;
      }
 
      $objRef{$namn} = $nr;
   }
 
   $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
 
   if (defined $$del2)
   {  $utrad = "$nr 0 obj\n<<" . $$del1 . $$del2;
   }
   else
   {  $utrad = "$nr 0 obj " . $$del1;
   }
   $objekt[$nr] = $pos;
   $pos += syswrite UTFIL, $utrad;
 
   ##################################
   #  Skriv ut underordnade objekt
   ##################################
 
   while (scalar @skapa)
   {  my @process = @skapa;
      @skapa = ();
      for (@process)
      {  my $gammal = $$_[0];
         my $ny     = $$_[1];
 
         ($del1, $del2, $kids) = getKnown(\$form{$fSource}, $gammal);
 
         $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs
                                     unless (! defined $kids);
         if (defined $$del2)
         {  $utrad = "$ny 0 obj\n<<" . $$del1 . $$del2;
         }
         else
         {  $utrad = "$ny 0 obj " . $$del1;
         }
         $objekt[$ny] = $pos;
         $pos += syswrite UTFIL, $utrad;
      }
   }
   close INFIL;
 
   return $namn;
 
}
 
########################
# Ett objekt extraheras
########################
 
sub extractObject
{  no warnings;
   my ($infil, $sidnr, $key, $typ) = @_;
 
   my ($res, $del1, $corr, $namn, $kids, $nr, $utrad);
   my $del2 = '';
   @skapa = ();
 
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
 
   *old       = $behandlad{$infil}->{old};
   *oldObject = $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
 
   my $fSource = $infil . '_' . $sidnr;
   my @stati = stat($infil);
 
   if ($form{$fSource}[fID] != $stati[9])
   {    errLog("$stati[9] ne $form{$fSource}[fID] aborts");
   }
   if ($checkId)
   {  if ($checkId ne $stati[9])
      {  my $mess =  "$checkId \<\> $stati[9] \n"
                  . "The Pdf-file $fSource has not the correct modification time. \n"
                  .  "The program is aborted";
         errLog($mess);
      }
      undef $checkId;
    }
    if ($ldir)
    {  $log .= "Cid~$stati[9]\n";
       my $indata = prep($infil);
       $log .= "Form~$indata~$sidnr~~load~1\n";
    }
 
   open (INFIL, "<$infil") || errLog("The file $infil couldn't be opened, aborting $!");
   binmode INFIL;
 
   ########################################
   #  Read the top object of the hierarchy
   ########################################
 
   ($del1, $del2, $kids) = getKnown(\$form{$fSource}, $key);
 
   if (exists $old{$key})
   {  $nr = $old{$key}; }
   else
   {  $old{$key} = ++$objNr;
      $nr = $objNr;
   }
 
   if ($typ eq 'Font')
   {  my ($Font, $extNamn);
      if ($$del1 =~ m'/BaseFont\s*/([^\s\/]+)'os)
      {  $extNamn = $1;
         $fontNr++;
         $Font = 'Ft' . $fontNr;
         $font{$extNamn}[foINTNAMN]    = $Font;
         $font{$extNamn}[foORIGINALNR] = $key;
         if ($del1 =~ m'/Subtype\s*/Type0'os)
         {  $font{$extNamn}[foTYP] = 1;
         }
         if ( ! defined $fontSource{$extNamn}[foSOURCE])
         {  $fontSource{$extNamn}[foSOURCE]     = $fSource;
            $fontSource{$extNamn}[foORIGINALNR] = $key;
         }
         $font{$extNamn}[foREFOBJ]   = $nr;
         $Font = $font{$extNamn}[foINTNAMN];
         $namn = $Font;
         $objRef{$Font}  = $nr;
      }
      else
      {  errLog("Error in $fSource, $key is not a font, aborting");
      }
   }
   elsif ($typ eq 'ColorSpace')
   {  $colorSpace++;
      $namn = 'Cs' . $colorSpace;
      $objRef{$namn} = $nr;
   }
   elsif ($typ eq 'Pattern')
   {  $pattern++;
      $namn = 'Pt' . $pattern;
      $objRef{$namn} = $nr;
   }
   elsif ($typ eq 'Shading')
   {  $shading++;
      $namn = 'Sh' . $shading;
      $objRef{$namn} = $nr;
   }
   elsif ($typ eq 'ExtGState')
   {  $gSNr++;
      $namn = 'Gs' . $gSNr;
      $objRef{$namn} = $nr;
   }
   elsif ($typ eq 'XObject')
   {  if (defined $form{$fSource}->[0]->{$nr}->[oIMAGENR])
      {  $namn = 'Ig' . $form{$fSource}->[0]->{$nr}->[oIMAGENR];
      }
      else
      {  $formNr++;
         $namn = 'Fo' . $formNr;
      }
 
      $objRef{$namn} = $nr;
   }
 
   $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs
                                  unless (! defined $kids);
   if (defined $$del2)
   {  $utrad = "$nr 0 obj\n<<" . $$del1 . $$del2;
   }
   else
   {  $utrad = "$nr 0 obj " . $$del1;
   }
 
   $objekt[$nr] = $pos;
   $pos += syswrite UTFIL, $utrad;
 
   ##################################
   #  Skriv ut underordnade objekt
   ##################################
 
   while (scalar @skapa)
   {  my @process = @skapa;
      @skapa = ();
      for (@process)
      {  my $gammal = $$_[0];
         my $ny     = $$_[1];
 
         ($del1, $del2, $kids) = getKnown(\$form{$fSource}, $gammal);
 
         $$del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs
                                 unless (! defined  $kids);
 
         if (defined $$del2)
         {  $utrad = "$ny 0 obj<<" . $$del1 . $$del2;
         }
         else
         {  $utrad = "$ny 0 obj " . $$del1;
         }
 
         $objekt[$ny] = $pos;
         $pos += syswrite UTFIL, $utrad;
      }
   }
   close INFIL;
   return $namn;
}
 
 
##########################################
# En fil analyseras och sidorna kopieras
##########################################
 
sub analysera
{  my $infil = shift;
   my $from  = shift || 1;
   my $to    = shift || 0;
   my $singlePage = shift;
   my ($i, $res, @underObjekt, @sidObj, $vektor, $resources, $valid,
       $strPos, $sidor, $filId, $Root, $del1, $del2, $utrad);
 
   my $extraherade = 0;
   my $sidAcc = 0;
   @skapa     = ();
 
   $behandlad{$infil}->{old} = {}
        unless (defined $behandlad{$infil}->{old});
   $processed{$infil}->{oldObject} = {}
        unless (defined $processed{$infil}->{oldObject});
   $processed{$infil}->{unZipped} = {}
        unless (defined $processed{$infil}->{unZipped});
   *old       = $behandlad{$infil}->{old};
   *oldObject = $processed{$infil}->{oldObject};
   *unZipped  = $processed{$infil}->{unZipped};
 
   $root      = (exists $processed{$infil}->{root})
                    ? $processed{$infil}->{root} : 0;
 
   my ($AcroForm, $Annots, $Names, $AARoot);
   undef $taInterAkt;
   undef %script;
 
   my $checkIdOld = $checkId;
   ($infil, $checkId) = findGet($infil, $checkIdOld);
   if (($ldir) && ($checkId) && ($checkId ne $checkIdOld))
   {  $log .= "Cid~$checkId\n";
   }
   undef $checkId;
   my @stati = stat($infil);
   open (INFIL, "<$infil") || errLog("Couldn't open $infil,aborting.  $!");
   binmode INFIL;
 
   if (! $root)
   {  $root      = xRefs($stati[7], $infil);
   }
   #############
   # Hitta root
   #############
 
   my $offSet;
   my $bytes;
   my $objektet = getObject($root);
 
   if ((! $interActive) && ( ! $to) && ($from == 1))
   {  if ($objektet =~ m'/AcroForm(\s+\d+\s{1,2}\d+\s{1,2}R)'so)
      {  $AcroForm = $1;
      }
      if ($objektet =~ m'/Names\s+(\d+)\s{1,2}\d+\s{1,2}R'so)
      {  $Names = $1;
      }
      if ((scalar %fields) || (scalar @jsfiler) || (scalar @inits))
      {   $Names  = behandlaNames($Names);
      }
      elsif ($Names)
      {  $Names = quickxform($Names);
      }
 
      #################################################
      #  Finns ett dictionary för Additional Actions ?
      #################################################
      if ($objektet =~ m'/AA(\s+\d+\s{1,2}\d+\s{1,2}R)'os)   # Hänvisning
      {  $AARoot = $1; }
      elsif ($objektet =~ m'/AA\s*\<\<\s*[^\>]+[^\>]+'so) # AA är ett dictionary
      {  my $k;
         my ($dummy, $obj) = split /\/AA/, $objektet;
         $obj =~ s/\<\</\#\<\</gs;
         $obj =~ s/\>\>/\>\>\#/gs;
         my @ord = split /\#/, $obj;
         for ($i = 0; $i <= $#ord; $i++)
         {   $AARoot .= $ord[$i];
             if ($ord[$i] =~ m'\S+'os)
             {  if ($ord[$i] =~ m'<<'os)
                {  $k++; }
                if ($ord[$i] =~ m'>>'os)
                {  $k--; }
                if ($k == 0)
                {  last; }
             }
          }
       }
       $taInterAkt = 1;   # Flagga att ta med interaktiva funktioner
   }
 
   #
   # Hitta pages
   #
 
   if ($objektet =~ m'/Pages\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
   {  $objektet = getObject($1);
      $resources = checkResources($objektet, $resources);
      if ($objektet =~ m'/Count\s+(\d+)'os)
      {  $sidor = $1;
         $behandlad{$infil}->{sidor} = $sidor;
      }
   }
   else
   { errLog("Didn't find pages "); }
 
   my @levels; my %kids;
   my $li = -1;
 
   if ($objektet =~ m'/Kids\s*\[([^\]]+)'os)
   {  $vektor = $1;
      while ($vektor =~ m'(\d+)\s{1,2}\d+\s{1,2}R'go)
      {   push @sidObj, $1;
      }
      $li++;
      $levels[$li] = \@sidObj;
   }
 
   while (($li > -1) && ($sidAcc < $sidor))
   {  if (scalar @{$levels[$li]})
      {   my $j = shift @{$levels[$li]};
          $objektet = getObject($j);
          if ($objektet =~ m'/Kids\s*\[([^\]]+)'os)
          {  $resources = checkResources($objektet, $resources);
             $vektor = $1;
             my @sObj;
             while ($vektor =~ m'(\d+)\s{1,2}\d+\s{1,2}R'go)
             {   push @sObj, $1 if !$kids{$1}; $kids{$1}=1;
             }
               if(@sObj)
               {  $li++;
                  $levels[$li] = \@sObj;
               }
          }
          else
          {  $sidAcc++;
             if ($sidAcc >= $from)
             {   if ($to)
                 {  if ($sidAcc <= $to)
                    {  sidAnalys($j, $objektet, $resources);
                       $extraherade++;
                       $sida++;
                    }
                    else
                    {  $sidAcc = $sidor;
                    }
                 }
                 else
                 {  sidAnalys($j, $objektet, $resources);
                    $extraherade++;
                    $sida++;
                 }
              }
          }
      }
      else
      {  $li--;
      }
   }
 
   if (defined $AcroForm)
   {  $AcroForm =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   }
   if (defined $AARoot)
   {  $AARoot =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   }
 
   while (scalar @skapa)
   {  my @process = @skapa;
      @skapa = ();
      for (@process)
      {  my $gammal = $$_[0];
         my $ny     = $$_[1];
         $objektet  = getObject($gammal);
 
         if ($objektet =~ m'^(\d+ \d+ obj\s*<<)(.+)(>>\s*stream)'os)
         {  $del1 = $2;
            $strPos = length($2) + length($3) + length($1);
            $del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
            $objekt[$ny] = $pos;
            $utrad = "$ny 0 obj<<" . "$del1" . '>>stream';
            $del2   = substr($objektet, $strPos);
            $utrad .= $del2;
 
            $pos += syswrite UTFIL, $utrad;
         }
         else
         {  if ($objektet =~ m'^(\d+ \d+ obj)'os)
            {  my $preLength = length($1);
               $objektet = substr($objektet, $preLength);
            }
            $objektet =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
            $objekt[$ny] = $pos;
            $utrad = "$ny 0 obj$objektet";
            $pos += syswrite UTFIL, $utrad;
         }
      }
  }
  close INFIL;
  $processed{$infil}->{root}         = $root;
 
  if (! $singlePage)
  {   return ($extraherade, $Names, $AARoot, $AcroForm);
  }
  else
  {   if ($extraherade)
      {   my $kvar = $behandlad{$infil}->{sidor} - $from;
          return ($kvar, $Names, $AARoot, $AcroForm);
      }
      else
      {   return (undef, undef, undef, undef);
      }
  }
}
 
sub sidAnalys
{  my ($oNr, $obj, $resources) = @_;
   my ($ny, $strPos, $spar, $closeProc, $del1, $del2, $utrad, $Annots,
   $resursObjekt, $streamObjekt, @extObj, $langd);
 
   if ((defined $stream) && (length($stream) > 0))
   {
       if ($checkCs)
       {  @extObj = ($stream =~ m'/(\S+)\s*'gso);
          checkContentStream(@extObj);
       }
 
       $objNr++;
       $objekt[$objNr] = $pos;
 
       if (( $compress ) && ( length($stream)  > 99 ))
       {   my $output = compress($stream);
           if ((length($output) > 25) && (length($output) < (length($stream))))
           {  $stream = $output;
           }
           $langd = length($stream);
           $stream = "\n" . $stream . "\n";
           $langd++;
           $streamObjekt  = "$objNr 0 obj<</Filter/FlateDecode"
                             . "/Length $langd>>stream" . $stream;
           $streamObjekt .= "endstream\nendobj\n";
 
       }
       else
       {  $langd = length($stream);
          $streamObjekt  = "$objNr 0 obj<</Length $langd>>stream\n" . $stream;
          $streamObjekt .= "\nendstream\nendobj\n";
       }
       $pos += syswrite UTFIL, $streamObjekt;
       $streamObjekt = "$objNr 0 R ";
 
       ########################################################################
       # Sometimes the contents reference is a ref to an object which
       # contains an array of content streams. Replace the ref with the array
       ########################################################################
 
       if ($obj =~ m'/Contents\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
       {   my $cObj = getObject($1, 1, 1);
           if ($cObj =~ m'^\s*\[[^\]]+\]\s*$'os)
           {   $obj =~ s|/Contents\s+\d+\s{1,2}\d+\s{1,2}R|'/Contents ' . $cObj|oes;
           }
       }
 
       my ($from, $to);
 
       ($resources, $from, $to) = checkResources ($obj, $resources);
       if ($from && $to)
       {   $obj = substr($obj, 0, $from) . substr($obj, $to);
       }
 
 
       ##########################
       # Hitta resursdictionary
       ##########################
       my $i = 0;
       while (($resources !~ m'\/'os) && ($i < 10))
       {   $i++;
           if ($resources =~ m'\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
           {   $resources = getObject($1, 1, 1);
           }
       }
       if ($i > 7)
       {  errLog("Couldn't find resources to merge");
       }
       if ($resources =~ m'\s*\<\<(.*)\>\>'os)
       {  $resources = $1;
       }
 
       if ($resources !~ m'/ProcSet')
       {  $resources =  '/ProcSet[/PDF/Text] ' . $resources;
       }
 
       ###############################################################
       # Läsa ev. referenser och skapa ett resursobjekt bestående av
       # dictionaries (för utvalda resurser)
       ###############################################################
 
       if (scalar %sidFont)
       {  if ($resources =~ m'/Font\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
          {   my $dict = getObject($1, 1, 1);
              $resources =~ s"/Font\s+\d+\s{1,2}\d+\s{1,2}R"'/Font' . $dict"ose;
          }
       }
 
       if (scalar %sidXObject)
       {  if ($resources =~ m'/XObject\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
          {   my $dict = getObject($1, 1, 1);
              $resources =~ s"/XObject\s+\d+\s{1,2}\d+\s{1,2}R"'/XObject' . $dict"ose;
          }
       }
 
       if (scalar %sidExtGState)
       {  if ($resources =~ m'/ExtGState\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
          {   my $dict = getObject($1, 1, 1);
              $resources =~ s"/ExtGState\s+\d+\s{1,2}\d+\s{1,2}R"'/ExtGState' . $dict"ose;
          }
       }
 
       if (scalar %sidPattern)
       {  if ($resources =~ m'/Pattern\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
          {   my $dict = getObject($1, 1, 1);
              $resources =~ s"/Pattern\s+\d+\s{1,2}\d+\s{1,2}R"'/Pattern' . $dict"ose;
          }
       }
 
       if (scalar %sidShading)
       {  if ($resources =~ m'/Shading\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
          {   my $dict = getObject($1, 1, 1);
              $resources =~ s"/Shading\s+\d+\s{1,2}\d+\s{1,2}R"'/Shading' . $dict"ose;
          }
       }
 
       if (scalar %sidColorSpace)
       {  if ($resources =~ m'/ColorSpace\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
          {   my $dict = getObject($1, 1, 1);
              $resources =~ s"/ColorSpace\s+\d+\s{1,2}\d+\s{1,2}R"'/ColorSpace' . $dict"ose;
          }
       }
       ####################################################
       # Nu är resurserna "normaliserade" med ursprungliga
       # värden. Spara värden för "översättning"
       ####################################################
 
       $resources =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
 
       ###############################
       # Komplettera med nya resurser
       ###############################
 
       if (scalar %sidFont)
       {  my $str = '';
          for (sort keys %sidFont)
          {  $str .= "/$_ $sidFont{$_} 0 R";
          }
          if ($resources !~ m'\/Font'os)
          {   $resources =  "/Font << $str >> " . $resources;
          }
          else
          {   $resources =~ s"/Font\s*<<"'/Font<<' . $str"oges;
          }
       }
 
       if (scalar %sidXObject)
       {  my $str = '';
          for (sort keys %sidXObject)
          {  $str .= "/$_ $sidXObject{$_} 0 R";
          }
          if ($resources !~ m'\/XObject'os)
          {   $resources =  "/XObject << $str >> " . $resources;
          }
          else
          {   $resources =~ s"/XObject\s*<<"'/XObject<<' . $str"oges;
          }
       }
 
       if (scalar %sidExtGState)
       {  my $str = '';
          for (sort keys %sidExtGState)
          {  $str .= "/$_ $sidExtGState{$_} 0 R";
          }
          if ($resources !~ m'\/ExtGState'os)
          {   $resources =  "/ExtGState << $str >> " . $resources;
          }
          else
          {   $resources =~ s"/ExtGState\s*<<"'/ExtGState<<' . $str"oges;
          }
       }
 
       if (scalar %sidPattern)
       {  my $str = '';
          for (sort keys %sidPattern)
          {  $str .= "/$_ $sidPattern{$_} 0 R";
          }
          if ($resources !~ m'\/Pattern'os)
          {   $resources =  "/Pattern << $str >> " . $resources;
          }
          else
          {   $resources =~ s"/Pattern\s*<<"'/Pattern<<' . $str"oges;
          }
       }
 
       if (scalar %sidShading)
       {  my $str = '';
          for (sort keys %sidShading)
          {  $str .= "/$_ $sidShading{$_} 0 R";
          }
          if ($resources !~ m'\/Shading'os)
          {   $resources =  "/Shading << $str >> " . $resources;
          }
          else
          {   $resources =~ s"/Shading\s*<<"'/Shading<<' . $str"oges;
          }
       }
 
       if (scalar %sidColorSpace)
       {  my $str = '';
          for (sort keys %sidColorSpace)
          {  $str .= "/$_ $sidColorSpace{$_} 0 R";
          }
          if ($resources !~ m'\/ColorSpace'os)
          {   $resources =  "/ColorSpace << $str >> " . $resources;
          }
          else
          {   $resources =~ s"/ColorSpace\s*<<"'/ColorSpace<<' . $str"oges;
          }
       }
 
       if (exists $resurser{$resources})
       {  $resources = "$resurser{$resources} 0 R\n";  # Fanns ett identiskt,
       }                                               # använd det
       else
       {   $objNr++;
           if ( keys(%resurser) < 10)
           {  $resurser{$resources} = $objNr;     # Spara 10 första resursobjekten
           }
           $objekt[$objNr] = $pos;
           $resursObjekt   = "$objNr 0 obj<<$resources>>endobj\n";
           $pos += syswrite UTFIL, $resursObjekt ;
           $resources      = "$objNr 0 R\n";
       }
 
       %sidXObject    = ();
       %sidExtGState  = ();
       %sidFont       = ();
       %sidPattern    = ();
       %sidShading    = ();
       %sidColorSpace = ();
       undef $checkCs;
 
       $stream     = '';
   }
 
   if (! $parents[0])
   { $objNr++;
     $parents[0] = $objNr;
   }
   my $parent = $parents[0];
 
   if (($sidObjNr) && (! defined $objekt[$sidObjNr]))
   {  $ny = $sidObjNr;
   }
   else
   {  $objNr++;
      $ny = $objNr;
   }
 
   $old{$oNr} = $ny;
 
   if ($obj =~ m'/Parent\s+(\d+)\s{1,2}\d+\s{1,2}R\b'os)
   {  $old{$1} = $parent;
   }
 
   if ($obj =~ m'^\d+ \d+ obj\s*<<(.+)>>\s*endobj'os)
   {  $del1 = $1;
   }
 
   if (%links)
   {   my $tSida = $sida + 1;
       if ((%links && @{$links{'-1'}}) || (%links && @{$links{$tSida}}))
       {   if ($del1 =~ m'/Annots\s*([^\/\<\>]+)'os)
           {  $Annots  = $1;
              @annots = ();
              if ($Annots =~ m'\[([^\[\]]*)\]'os)
              {  ; }
              else
              {  if ($Annots =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'os)
                 {  $Annots = getObject($1);
                 }
              }
              while ($Annots =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'ogs)
              {   push @annots, xform();
              }
              $del1 =~ s?/Annots\s*([^\/\<\>]+)??os;
           }
           $Annots = '/Annots ' . mergeLinks() . ' 0 R';
       }
   }
 
   if (! $taInterAkt)
   {  $del1 =~ s?\s*/AA\s*<<[^>]*>>??os;
   }
 
   $del1 =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
 
   if ($del1 !~ m'/Resources'o)
   {  $del1 .= "/Resources $resources";
   }
 
   if (defined $streamObjekt)     # En ny ström ska läggas till
   {  if ($del1 =~ m'/Contents\s+(\d+)\s{1,2}\d+\s{1,2}R'os)
      {  my $oldCont = $1;
         $del1 =~ s|/Contents\s+(\d+)\s{1,2}\d+\s{1,2}R|'/Contents [' . "$oldCont 0 R $streamObjekt" . ']'|oes;
      }
      elsif ($del1 =~ m'/Contents\s*\['os)
      {   $del1 =~ s|/Contents\s*\[([^\]]+)|'/Contents [' . $1 ." $streamObjekt"|oes;
      }
      else
      {   $del1 .= "/Contents $streamObjekt\n";
      }
   }
 
   if ($Annots)
   {  $del1 .= $Annots;
   }
 
   $utrad = "$ny 0 obj<<$del1>>";
   if (defined $del2)
   {   $utrad .= "stream\n$del2";
   }
   else
   {  $utrad .= "endobj\n";
   }
 
   $objekt[$ny] = $pos;
   $pos += syswrite UTFIL, $utrad;
 
   push @{$kids[0]}, $ny;
   $counts[0]++;
   if ($counts[0] > 9)
   {  ordnaNoder(8);
   }
}
 
 
sub checkResources
{   my $pObj  = shift;
    my $reStr = shift;
    my $to;
 
    my $p = index($pObj, '/Resources');
    if ( $p < 0)
    {  ;
    }
    elsif ($pObj =~ m'/Resources(\s+\d+\s{1,2}\d+\s{1,2}R)'os)
    {   $reStr = $1;
        $to = $p + 10 + length($reStr);
    }
    else
    {  my $t = length($pObj);
       my $i = $p + 10;
       my $j = $i;
       my $k = 0;
       my $c;
       while ($i < $t)
       {   $c = substr($pObj,$i,1);
           if (($c eq '<' )
           ||  ($c eq '>'))
           {   if ($c eq '<' )
               {  $k++;
               }
               else
               {  $k--;
               }
               last if ($k == 0);
           }
           $i++;
       }
       if ($i != $t)
       {  $i++;
          $reStr = substr($pObj, $j, ($i - $j));
          $to = $i;
       }
   }
 
   if (wantarray)
   {  return ($reStr, $p, $to);
   }
   else
   {  return $reStr;
   }
}
 
 
sub translate
{ if (exists $old{$1})
  { $old{$1}; }
  else
  {  $old{$1} = ++$objNr;
  }
}
 
sub behandlaNames
{  my ($namnObj, $iForm) = @_;
 
   my ($low, $high, $antNod0, $entry, $nyttNr, $ny, $obj,
       $fObjnr, $offSet, $bytes, $res, $key, $func, $corr, @objData);
   my (@nod0, @nodUpp, @kid, @soek, %nytt);
 
   my $objektet  = '';
   my $vektor    = '';
   my $antal     = 0;
   my $antNodUpp = 0;
   if ($namnObj)
   {  if ($iForm)                                # Läsning via interntabell
      {   $objektet = getObject($namnObj, 1);
 
          if ($objektet =~ m'<<(.+)>>'ogs)
          { $objektet = $1; }
          if ($objektet =~ s'/JavaScript\s+(\d+)\s{1,2}\d+\s{1,2}R''os)
          {  my $byt = $1;
             push @kid, $1;
             while (scalar @kid)
             {  @soek = @kid;
                @kid = ();
                for my $sObj (@soek)
                {  $obj = getObject($sObj, 1);
                   if ($obj =~ m'/Kids\s*\[([^]]+)'ogs)
                   {  $vektor = $1;
                   }
                   while ($vektor =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'ogs)
                   {  push @kid, $1;
                   }
                   $vektor = '';
                   if ($obj =~ m'/Names\s*\[([^]]+)'ogs)
                   {   $vektor = $1;
                   }
                   while ($vektor =~ m'\(([^\)]+)\)\s*(\d+) \d R'gos)
                   {   $script{$1} = $2;
                   }
                }
             }
          }
      }
      else                                #  Läsning av ett "doc"
      {  $objektet = getObject($namnObj);
         if ($objektet =~ m'<<(.+)>>'ogs)
         {  $objektet = $1; }
         if ($objektet =~ s'/JavaScript\s+(\d+)\s{1,2}\d+\s{1,2}R''os)
         {  my $byt = $1;
            push @kid, $1;
            while (scalar @kid)
            {  @soek = @kid;
               @kid = ();
               for my $sObj (@soek)
               {  $obj = getObject($sObj);
                  if ($obj =~ m'/Kids\s*\[([^]]+)'ogs)
                  {  $vektor = $1;
                  }
                  while ($vektor =~ m'\b(\d+)\s{1,2}\d+\s{1,2}R\b'ogs)
                  {  push @kid, $1;
                  }
                  undef $vektor;
                  if ($obj =~ m'/Names\s*\[([^]]+)'ogs)
                  {  $vektor = $1;
                  }
                  while ($vektor =~ m'\(([^\)]+)\)\s*(\d+) \d R'gos)
                  {   $script{$1} = $2;
                  }
               }
             }
          }
      }
   }
   for my $filnamn (@jsfiler)
   {   inkludera($filnamn);
   }
   my @nya = (keys %nyaFunk);
   while (scalar @nya)
   {   my @behandla = @nya;
       @nya = ();
       for $key (@behandla)
       {   if (exists $initScript{$key})
           {  if (exists $nyaFunk{$key})
              {   $initScript{$key} = $nyaFunk{$key};
              }
              if (exists $script{$key})   # företräde för nya funktioner !
              {   delete $script{$key};    # gammalt script m samma namn plockas bort
              }
              my @fall = ($initScript{$key} =~ m'([\w\d\_\$]+)\s*\('ogs);
              for (@fall)
              {   if (($_ ne $key) && (exists $nyaFunk{$_}))
                  {  $initScript{$_} = $nyaFunk{$_};
                     push @nya, $_;
                  }
              }
           }
       }
   }
   while  (($key, $func) = each %nyaFunk)
   {  $fObjnr = skrivJS($func);
      $script{$key} = $fObjnr;
      $nytt{$key}   = $fObjnr;
   }
 
   if (scalar %fields)
   {  push @inits, 'Ladda();';
      $fObjnr = defLadda();
      if ($duplicateInits)
      {  $script{'Ladda'} = $fObjnr;
         $nytt{'Ladda'} = $fObjnr;
      }
   }
 
   if ((scalar @inits) && ($duplicateInits))
   {  $fObjnr = defInit();
      $script{'Init'} = $fObjnr;
      $nytt{'Init'} = $fObjnr;
   }
   undef @jsfiler;
 
   for my $key (sort (keys %script))
   {  if (! defined $low)
      {  $objNr++;
         $ny = $objNr;
         $objekt[$ny] = $pos;
         $obj = "$ny 0 obj\n";
         $low  = $key;
         $obj .= '<< /Names [';
      }
      $high = $key;
      $obj .= '(' . "$key" . ')';
      if (! exists $nytt{$key})
      {  $nyttNr = quickxform($script{$key});
      }
      else
      {  $nyttNr = $script{$key};
      }
      $obj .= "$nyttNr 0 R\n";
      $antal++;
      if ($antal > 9)
      {   $obj .= ' ]/Limits [(' . "$low" . ')(' . "$high" . ')] >>' . "endobj\n";
          $pos += syswrite UTFIL, $obj;
          push @nod0, \[$ny, $low, $high];
          $antNod0++;
          undef $low;
          $antal = 0;
      }
   }
   if ($antal)
   {   $obj .= ']/Limits [(' . $low . ')(' . $high . ')]>>' . "endobj\n";
       $pos += syswrite UTFIL, $obj;
       push @nod0, \[$ny, $low, $high];
       $antNod0++;
   }
   $antal = 0;
 
   while (scalar @nod0)
   {   for $entry (@nod0)
       {   if ($antal == 0)
           {   $objNr++;
               $objekt[$objNr] = $pos;
               $obj = "$objNr 0 obj\n";
               $low  = $$entry->[1];
               $obj .= '<</Kids [';
           }
           $high = $$entry->[2];
           $obj .= " $$entry->[0] 0 R";
           $antal++;
           if ($antal > 9)
           {   $obj .= ']/Limits [(' . $low . ')(' . $high . ')]>>' . "endobj\n";
               $pos += syswrite UTFIL, $obj;
               push @nodUpp, \[$objNr, $low, $high];
               $antNodUpp++;
               undef $low;
               $antal = 0;
           }
       }
       if ($antal > 0)
       {   if ($antNodUpp == 0)     # inget i noderna över
           {   $obj .= ']>>' . "endobj\n";
               $pos += syswrite UTFIL, $obj;
           }
           else
           {   $obj .= ']/Limits [(' . "$low" . ')(' . "$high" . ')]>>' . "endobj\n";
               $pos += syswrite UTFIL, $obj;
               push @nodUpp, \[$objNr, $low, $high];
               $antNodUpp++;
               undef $low;
               $antal = 0;
           }
       }
       @nod0    = @nodUpp;
       $antNod0 = $antNodUpp;
       undef @nodUpp;
       $antNodUpp = 0;
   }
 
 
   $ny = $objNr;
   $objektet =~ s|\s*/JavaScript\s*\d+\s{1,2}\d+\s{1,2}R||os;
   $objektet =~ s/\b(\d+)\s{1,2}\d+\s{1,2}R\b/xform() . ' 0 R'/oegs;
   if (scalar %script)
   {  $objektet .= "\n/JavaScript $ny 0 R\n";
   }
   $objNr++;
   $ny = $objNr;
   $objekt[$ny] = $pos;
   $objektet = "$ny 0 obj<<" . $objektet . ">>endobj\n";
   $pos += syswrite UTFIL, $objektet;
   return $ny;
}
 
 
sub quickxform
{  my $inNr = shift;
   if (exists $old{$inNr})
   {  $old{$inNr}; }
   else
   {  push @skapa, [$inNr, ++$objNr];
      $old{$inNr} = $objNr;
   }
}
 
 
sub skrivKedja
{  my $code = ' ';
 
   for (values %initScript)
   {   $code .= $_ . "\n";
   }
   $code .= "function Init() { ";
   $code .= 'if (typeof this.info.ModDate == "object")' . " { return true; }";
   for (@inits)
   {  $code .= $_ . "\n";
   }
   $code .= "} Init(); ";
 
   my $spar = skrivJS($code);
   undef @inits;
   undef %initScript;
   return $spar;
}
 
 
 
sub skrivJS
{  my $kod = shift;
   my $obj;
   if (($compress) && (length($kod) > 99))
   {  $objNr++;
      $objekt[$objNr] = $pos;
      my $spar = $objNr;
      $kod = compress($kod);
      my $langd = length($kod);
      $obj = "$objNr 0 obj<</Filter/FlateDecode"
                           .  "/Length $langd>>stream\n" . $kod
                           .  "\nendstream\nendobj\n";
      $pos += syswrite UTFIL, $obj;
      $objNr++;
      $objekt[$objNr] = $pos;
      $obj = "$objNr 0 obj<</S/JavaScript/JS $spar 0 R >>endobj\n";
   }
   else
   {  $kod =~ s'\('\\('gso;
      $kod =~ s'\)'\\)'gso;
      $objNr++;
      $objekt[$objNr] = $pos;
      $obj = "$objNr 0 obj<</S/JavaScript/JS " . '(' . $kod . ')';
      $obj .= ">>endobj\n";
   }
   $pos += syswrite UTFIL, $obj;
   return $objNr;
}
 
sub inkludera
{   my $jsfil = shift;
    my $fil;
    if ($jsfil !~ m'\{'os)
    {   open (JSFIL, "<$jsfil") || return;
        while (<JSFIL>)
        { $fil .= $_;}
 
        close JSFIL;
    }
    else
    {  $fil = $jsfil;
    }
    $fil =~ s|function\s+([\w\_\d\$]+)\s*\(|"zXyZcUt function $1 ("|sge;
    my @funcs = split/zXyZcUt /, $fil;
    for my $kod (@funcs)
    {   if ($kod =~ m'^function ([\w\_\d\$]+)'os)
        {   $nyaFunk{$1} = $kod;
        }
    }
}
 
 
sub defLadda
{  my $code = "function Ladda() {";
   for (keys %fields)
   {  my $val = $fields{$_};
      if ($val =~ m'\s*js\s*\:(.+)'oi)
      {   $val = $1;
          $code .= "if (this.getField('$_')) this.getField('$_').value = $val; ";
      }
      else
      {  $val =~ s/([^A-Za-z0-9\-_.!* ])/sprintf("%%%02X", ord($1))/ge;
         $code .= "if (this.getField('$_')) this.getField('$_').value = unescape('$val'); ";
      }
 
   }
   $code .= " 1;} ";
 
 
   $initScript{'Ladda'} = $code;
   if ($duplicateInits)
   {  my $ny = skrivJS($code);
      return $ny;
   }
   else
   {  return 1;
   }
}
 
sub defInit
{  my $code = "function Init() { ";
   $code .= 'if (typeof this.info.ModDate == "object")' . " { return true; } ";
   for (@inits)
   {  $code .= $_ . "\n";
   }
   $code .= '}';
 
   my $ny = skrivJS($code);
   return $ny;
 
}
 
 
 
sub errLog
{   no strict 'refs';
    my $mess = shift;
    my $endMess  = " $mess \n More information might be found in";
    if ($runfil)
    {   $log .= "Log~Err: $mess\n";
        $endMess .= "\n   $runfil";
        if (! $pos)
        {  $log .= "Log~Err: No pdf-file has been initiated\n";
        }
        elsif ($pos > 15000000)
        {  $log .= "Log~Err: Current pdf-file is very big: $pos bytes, will not try to finish it\n";
        }
        else
        {  $log .= "Log~Err: Will try to finish current pdf-file\n";
           $endMess .= "\n   $utfil";
        }
    }
    my $errLog = 'error.log';
    my $now = localtime();
    my $lpos = $pos || 'undef';
    my $lobjNr = $objNr || 'undef';
    my $lutfil = $utfil || 'undef';
 
    my $lrunfil = $runfil || 'undef';
    open (ERRLOG, ">$errLog") || croak "$mess can't open an error log, $!";
    print ERRLOG "\n$mess\n\n";
    print ERRLOG Carp::longmess("The error occurred when executing:\n");
    print ERRLOG "\nSituation when the error occurred\n\n";
    print ERRLOG "   Bytes written to the current pdf-file,    pos    = $lpos\n";
    print ERRLOG "   Object processed, not necessarily written objNr  = $lobjNr\n";
    print ERRLOG "   Current pdf-file,                         utfil  = $lutfil\n";
    print ERRLOG "   File logging the run,                     runfil = $lrunfil\n";
    print ERRLOG "   Local time                                       = $now\n";
    print ERRLOG "\n\n";
    close ERRLOG;
    $endMess .= "\n   $errLog";
    if (($pos) && ($pos < 15000000))
    {  prEnd();
    }
    print STDERR Carp::shortmess("An error occurred \n");
    croak "$endMess\n";
}