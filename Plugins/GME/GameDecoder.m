//
//  GameFile.m
//  Cog
//
//  Created by Vincent Spader on 5/29/06.
//  Copyright 2006 Vincent Spader. All rights reserved.
//

#import "GameDecoder.h"

#import "Logging.h"

#import "PlaylistController.h"

@implementation GameDecoder

gme_err_t readCallback(void *data, void *out, int count) {
	id source = (__bridge id)data;
	DLog(@"Amount: %i", count);
	int n = (int)[source read:out amount:count];
	DLog(@"Read: %i", n);
	if(n <= 0) {
		DLog(@"ERROR!");
		return (gme_err_t)1; // Return non-zero for error
	}

	return 0; // Return 0 for no error
}

- (id)init {
	self = [super init];
	if(self) {
		emu = NULL;
	}
	return self;
}

- (BOOL)open:(id<CogSource>)s {
	[self setSource:s];

	// We need file-size to use GME
	if(![source seekable]) {
		return NO;
	}

	gme_err_t error;

	NSString *ext = [[[source url] pathExtension] lowercaseString];

	gme_type_t type = gme_identify_extension([ext UTF8String]);
	if(!type) {
		ALog(@"GME: No type!");
		return NO;
	}

	sampleRate = 44100;

	if(type == gme_spc_type || type == gme_sfm_type)
		sampleRate = 32000;

	emu = gme_new_emu(type, (int)sampleRate);
	if(!emu) {
		ALog(@"GME: No new emu!");
		return NO;
	}

	[source seek:0 whence:SEEK_END];
	long size = [source tell];
	[source seek:0 whence:SEEK_SET];

	DLog(@"Size: %li", size);

	error = gme_load_custom(emu, readCallback, size, (__bridge void *)(s));
	if(error) {
		ALog(@"GME: ERROR Loding custom!");
		return NO;
	}

	NSURL *m3uurl = [[source url] URLByDeletingPathExtension];
	m3uurl = [m3uurl URLByAppendingPathExtension:@"m3u"];
	id audioSourceClass = NSClassFromString(@"AudioSource");
	id<CogSource> m3usrc = [audioSourceClass audioSourceForURL:m3uurl];
	if([m3usrc open:m3uurl]) {
		if([m3usrc seekable]) {
			[m3usrc seek:0 whence:SEEK_END];
			long size = [m3usrc tell];
			[m3usrc seek:0 whence:SEEK_SET];

			void *data = malloc(size);
			[m3usrc read:data amount:size];

			gme_load_m3u_data(emu, data, size);
			free(data);
		}
	}

	int track_num = [[[source url] fragment] intValue]; // What if theres no fragment? Assuming we get 0.

	gme_info_t *info;
	error = gme_track_info(emu, &info, track_num);
	if(error) {
		ALog(@"Unable to get track info");
		return NO;
	}

	// As recommended
	if(info->length > 0) {
		DLog(@"Using length: %i", info->length);
		length = info->length;
	} else if(info->loop_length > 0) {
		DLog(@"Using loop length: %i", info->loop_length);
		length = info->intro_length + 2 * info->loop_length;
	} else {
		length = 150000;
		DLog(@"Setting default: %li", length);
	}

	if(info->fade_length >= 0) {
		fade = info->fade_length;
	} else {
		fade = 8000;
	}

	gme_free_info(info);

	DLog(@"Length: %li", length);

	DLog(@"Track num: %i", track_num);
	error = gme_start_track(emu, track_num);
	if(error) {
		ALog(@"GME: Error starting track");
		return NO;
	}

	length += fade;

	[self willChangeValueForKey:@"properties"];
	[self didChangeValueForKey:@"properties"];

	return YES;
}

- (NSDictionary *)properties {
	return @{@"bitrate": [NSNumber numberWithInt:0],
			 @"sampleRate": [NSNumber numberWithFloat:(float)sampleRate],
			 @"totalFrames": [NSNumber numberWithLong:length * ((float)sampleRate * 0.001)],
			 @"bitsPerSample": [NSNumber numberWithInt:sizeof(short) * 8], // Samples are short
			 @"channels": [NSNumber numberWithInt:2], // output from gme_play is in stereo
			 @"seekable": [NSNumber numberWithBool:YES],
			 @"endian": @"host",
			 @"encoding": @"synthesized"};
}

- (NSDictionary *)metadata {
	return @{};
}

- (int)readAudio:(void *)buf frames:(UInt32)frames {
	int numSamples = frames * 2; // channels = 2

	if(gme_track_ended(emu)) {
		return 0;
	}

	if(IsRepeatOneSet())
		gme_set_fade(emu, -1, 0);
	else
		gme_set_fade(emu, (int)(length - fade), (int)fade);

	gme_play(emu, numSamples, (short int *)buf);

	// Some formats support length, but we'll add that in the future.
	//(From gme.txt) If track length, then use it. If loop length, play for intro + loop * 2. Otherwise, default to 2.5 minutes
	return frames; // GME will always generate samples. There's no real EOS.
}

- (long)seek:(long)frame {
	gme_err_t error;
	error = gme_seek(emu, frame / 44.1);
	if(error) {
		return -1;
	}

	return frame;
}

- (void)close {
	if(emu) {
		gme_delete(emu);
		emu = NULL;
	}
}

- (void)dealloc {
	[self close];
}

+ (NSArray *)fileTypes {
	return @[@"ay", @"gbs", @"hes", @"kss", @"nsf", @"nsfe", @"sap", @"sfm", @"sgc", @"spc"];
}

+ (NSArray *)mimeTypes {
	return nil;
}

+ (float)priority {
	return 1.0;
}

+ (NSArray *)fileTypeAssociations {
	NSMutableArray *ret = [[NSMutableArray alloc] init];
	[ret addObject:@"Game Music Emu Files"];
	[ret addObject:@"vg.icns"];
	[ret addObjectsFromArray:[self fileTypes]];

	return @[ret];
}

- (void)setSource:(id<CogSource>)s {
	source = s;
}

- (id<CogSource>)source {
	return source;
}

@end
