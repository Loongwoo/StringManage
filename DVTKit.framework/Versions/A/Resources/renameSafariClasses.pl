#!/usr/bin/perl -s

# I know a lot of people dislike perl, but sometimes it's the right tool for the job. Sorry.
# Usage: renameSafariClasses.pl -g DVTNewTabButton.m
# Note: I usually run renameSafariClasses.pl -v -l DVTNewTabButton.m first, to see what I'm going to get and then pass the "go ahead" flag.

my $verbose = $v;
my $go_ahead = $g;
my $show_lines = $l;

use strict;

foreach my $file (@ARGV) {
	if(-e $file) {
		print "Starting $file\n";

# Open the file for reading. Open a new file for writing. We'll atomically swap this into place if the operation succeeds
		open (READ, "$file");
		open (WRITE, ">$file.new");


# This global state variable tells whether we should do replacements or not. It's very dumb, and doesn't handle nesting.
		my $isInsideSafariComment = 0;

# Now we loop over each line to see if modifications are needed to the contents of the file
		while(my $line = <READ>) {
			print "V: $line" if $show_lines;
			
			if ($line =~ m(#if DVT_COMMENT_SAFARI_CODE) ) {
				$isInsideSafariComment = 1;
			}
			if ($line =~ m(#endif //DVT_COMMENT_SAFARI_CODE) ) {
				$isInsideSafariComment = 0;
			}

# Try to brute force replace what they have with what we want
			if (!$isInsideSafariComment) {
				$line = replaceSafariClassesWithXcodeClasses($line);
			}

			print WRITE "$line";
		}
	}

	call_system(qq(mv $file $file.old));
	call_system(qq(mv $file.new $file));
}

sub call_system {
	my $system_command = shift;

	print "V: ", $system_command, "\n" if $verbose;
	my $output = `$system_command` if $go_ahead;
	return $output;
}


sub isLineNeeded {
	my $line = shift;
	my $isLineNeeded = 1;

#Each of these is added by the script, so we'll just skip them as we read through
	if ($line =~ m/DVT_SAFARI_CODE_NOT_NEEDED/) {
		$isLineNeeded = 0;
	}
	if ($line =~ m/SafariMacros.h/) {
		$isLineNeeded = 0;
	}

	return $isLineNeeded;
}

sub replaceSafariClassesWithXcodeClasses {
	my $line = shift;

# These should ALL be treated like regex! That means if the thing you want to replace has a * in it, you must double slash quote it.
	my %classesToSwap = (
		"BarBackground" => "DVTBarBackground",
		"ClippedItemsIndicator" => "DVTTabBarClippedItemsIndicator",
		"ButtonPlus" => "DVTMainStatusAwareButton",
		"MorphingDragImageController" => "DVTMorphingDragImageController",
		"MorphingDragImageView" => "DVTMorphingDragImageView",
		"NewTabButton" => "DVTNewTabButton",
		"RolloverImageButton" => "DVTRolloverImageButton",
		"RolloverTrackingButton" => "DVTRolloverTrackingButton",
		"SlidingAnimation" => "DVTSlidingAnimation",
		"SlidingViewsBar" => "DVTSlidingViewsBar",
		"TabBarEnclosureView" => "DVTTabBarEnclosureView",
		"TabBarView" => "DVTTabBarView",
		"BrowserTabViewItem" => "DVTTabbedWindowTabViewItem",
		"TabButton" => "DVTTabButton",
		"BrowserNSMenuExtras" => "DVTTemporaryTabCategories",
		"BrowserNSArrayExtras" => "DVTTemporaryTabCategories",
		"BrowserNSStringExtras" => "DVTTemporaryTabCategories",
		"BrowserNSScreenExtras" => "DVTTemporaryTabCategories",
		"BrowserNSWindowExtras" => "DVTTemporaryTabCategories",
		"TitleBarButton" => "DVTTitleBarButton",
		"ClippedItemsIndicatorCell" => "DVTTabBarClippedItemsIndicatorCell",
		"ScrollableTabButton" => "DVTScrollableTabButton",
		"ScrollableTabBarViewButton" => "DVTScrollableTabBarViewButton",
		"ScrollableTabBarViewAnimation" => "DVTScrollableTabBarViewAnimation",
		"ScrollableTabBarClipView" => "DVTScrollableTabBarClipView",
		"DetachedTabDraggingImageToBrowserWindowTransitionController" => "DVTDetachedTabDraggingImageToWindowTransitionController",
		"embed-color-profiles-in-artwork.py" => "embed-color-profiles-in-artwork.py",
		"BrowserWindowControllerMac \\*" => "id <DVTTabbedWindowControlling> ",
		"BrowserTabViewItem" => "DVTTabbedWindowTabViewItem",
		"ScrollableTabBarView" => "DVTScrollableTabBarView",
		"MorphingDragImageDropTarget" => "DVTMorphingDragImageDropTarget",
		"MorphingDragImageControllerDragSource" => "DVTMorphingDragImageControllerDragSource",
		"DragWindowAnimation" => "_DVTDragWindowAnimation",
		"TabButtonPboardType" => "Dragged Tab Pboard Type",
		"ScrollableTabBarViewAccessoryButton" => "DVTScrollableTabBarViewAccessoryButton",
		"ScrollableTabBarMaskingContainerView" => "ScrollableTabBarMaskingContainerView",
        "ASSERT" => "DVTAssert",
	);
	
	for my $key (keys %classesToSwap) {
#RegEx: replace whole instances (\b is word boundary) of the Safari class ($key) with its entry in the table globally
		if ($line =~ s(\b$key)($classesToSwap{"$key"})g ) {
			print "$key -> $line\n" if $verbose;
		}
	}

	return $line;
}

