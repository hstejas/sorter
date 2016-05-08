#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
use File::Copy;
use File::Path qw(make_path);
use JSON qw(decode_json);

my $url="http://www.omdbapi.com/";


if($#ARGV != 1)
{
   print "ERROR\n   usage: $0 <source_dir> <destination_dir>";
   exit -1;
}

my $src_dir=$ARGV[0];
my $dest_dir=$ARGV[1];

$src_dir=~s/\/$//;
$dest_dir=~s/\/$//;

my @names=();

opendir(S_DIR, $src_dir) or die "$!";
while(readdir(S_DIR))
{
   push @names, $_ if (/^[^.]/);
}
close(S_DIR);

sub sanitize($)
{
   my $fname = shift;
   print "$fname === \n";
   # remove file extension
   $fname=~s/\.avi|\.mkv|\.mp4|\.wmv|\.srt//i;

   #remove unwanted characters like -_.[]() 1080p 720p
   $fname=~s/_|\.|-/ /g;
   $fname=~s/[\[\]\(\)]/ /g;
   $fname=~s/1080[p]|720[p]|420[p]//gi;

   # extract year of form 19xx or 2xxx
   my $year="";
   $fname=~/(19[0-9]{2}|2[0-9]{3})/ and $year = $1;
   $fname=~s/$year//;
   
   #Add space between words if there arnt any "MayDay" -> "May Day"
   $fname=~s/([a-z]+)([A-Z]{1})/$1 $2/g;
   #Add space between word and part "Ice Age3" -> "Ice Age 3"
   $fname=~s/([a-zA-Z]+)([0-9]{1})/$1 $2/g;
   my $name = $fname;

   # trim extra spaces
   $name =~ s/^\s+|\s+$//g ;
   
   return ($name, $year);
}

foreach(@names)
{
   my $fname = $_;
   my ($name, $year) = sanitize($fname);
   #print "$name $year\n";
   my $query='?t="'.$name.'"&type="movie"&y="'.$year.'"';
   my $response = get($url.$query) or print "Couldnt get $query" and next;

   my $dec_json = decode_json($response);
   #print Dumper $dec_json;

   if($dec_json->{"Response"} eq "True")
   {
      print $dec_json->{"Title"}." --> ".$dec_json->{"Year"}." --> ".$dec_json->{"Rated"}." \n";

      print "Skip? ";
      print "Skipping\n" and next if(<STDIN>=~/y/);

      my $rating = $dec_json->{"Rated"};
      # Remove \ or / like in N/A-> NA
      $rating=~s/[\/\\]//;

      my $dest = "$dest_dir/$rating";

      make_path($dest) if(! -d $dest);
      move("$src_dir/$fname", "$dest/$fname") or print "Could not move $fname\n $!";
   }
}
