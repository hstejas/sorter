#!/usr/bin/perl
#
#  Script to sort movies into different directories based on movie rating.
#  Only works on a flat source directory right now and doesn't traverse recursively.
#  uses OMDB(http://www.omdbapi.com/) as it doesnt require any api keys right now :) 
#  Dont look at me if youdeleteyourmoviesusingthisscript and youcandowhateveryouwantusingthisscript
#

use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
use File::Copy;
use File::Path qw(make_path);
use JSON qw(decode_json);



if($#ARGV != 1)
{
   print ">>> ERROR\n   usage: $0 <source_dir> <destination_dir>";
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
   $fname=~s/_|\.|-|=/ /g;
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

   # trim extra spaces
   $fname =~ s/^\s+|\s+$//g ;
   my @name = split " ", $fname;
   
   return (\@name, $year);
}

sub getData
{
   my ($title, $year) = @_;

   my $url="http://www.omdbapi.com/";
   my $query='?t="'.$title.'"&type="movie"&y="'.$year.'"';
   my $response = get($url.$query) or print "Couldn't get $query" and next;
   my $dec_json = decode_json($response);
   #print Dumper $dec_json;
   return ($dec_json->{"Response"}, $dec_json->{"Title"}, $dec_json->{"Year"}, $dec_json->{"Rated"});
}

foreach(@names)
{
   my $fname = $_;
   my ($tokens, $year) = sanitize($fname);
   my $inp = "";
   my $name = join " ", @{$tokens};
   my $retries = 0;
   while (1)
   {
      my ($response, $title, $year, $rating) = getData($name, $year);
      if($response eq "True")
      {
         print "$title --> $year --> $rating\n";
   
         print "Skip (s) or retry(r) anything else to continue moving? ";
         chomp ( $inp = <STDIN>);
         print "Skipping\n" and last if($inp=~/s/);
         if($inp=~/r/)
         {
            print "Warn: Exhausted search, skipping this\n" and last if($retries > $#{$tokens});
            # TODO: put somthing fuzzy here?
            $name="";
            for(my $i = 0; $i<=$retries; $i++)
            {
               $name=$name." ".@{$tokens}[$i];
            }
            $retries++;
            next;
         }
         # Remove \ or / like in N/A-> NA
         $rating=~s/[\/\\\:]//;
         $title=~s/[\:]//;
         my $dest = "$dest_dir/$rating";
   
         make_path($dest) or die "$!" if(! -d $dest);
         my $dest_name = "$title ($year)";
         if( -f "$src_dir/$fname")
         {
            if($fname=~/(\.[^.]*)$/)
            {
               $dest_name.=$1;
            }
         }
         move("$src_dir/$fname", "$dest/$dest_name") or print ">>> ERROR: Could not move $fname\n $!";
         last;
      }
      else
      {
         print "Warn: Exhausted search, skipping this\n" and last if($retries > $#{$tokens});
         # TODO: put somthing fuzzy here?
         $name="";
         for(my $i = 0; $i<=$retries; $i++)
         {
            $name=$name.@{$tokens}[$i];
         }
         $retries++;

         print "Couldn't match: Skip (s)? or any other key to retry";
         chomp ( $inp = <STDIN>);
         print "Skipping\n" and last if($inp=~/s/);
      }
   }
}
