/*
 * Lightly modified from https://github.com/gamedevtech/CocoaOpenGLWindow
 *
 * The above-mentioned project was released under public domain.
 */

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>
#include <OpenGL/gl3.h>
#include "platform.h"

@class View;
static CVReturn GlobalDisplayLinkCallback(CVDisplayLinkRef, const CVTimeStamp*, const CVTimeStamp*, CVOptionFlags, CVOptionFlags*, void*);

@interface View : NSOpenGLView <NSWindowDelegate> {
@public
	CVDisplayLinkRef displayLink;
	bool running;
	NSRect windowRect;
	NSRecursiveLock* appLock;
	GLuint shader_program;
	GLuint vao;
}
@end

@implementation View
// Initialize
- (id) initWithFrame: (NSRect) frame {
	running = true;

	// No multisampling
	int samples = 0;

	// Keep multisampling attributes at the start of the attribute lists since code below assumes they are array elements 0 through 4.
	NSOpenGLPixelFormatAttribute windowedAttrs[] =
	{
		NSOpenGLPFAMultisample,
		NSOpenGLPFASampleBuffers, samples ? 1 : 0,
		NSOpenGLPFASamples, samples,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		0
	};

	// Try to choose a supported pixel format
	NSOpenGLPixelFormat* pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttrs];

	if (!pf) {
		bool valid = false;
		while (!pf && samples > 0) {
			samples /= 2;
			windowedAttrs[2] = samples ? 1 : 0;
			windowedAttrs[4] = samples;
			pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttrs];
			if (pf) {
				valid = true;
				break;
			}
		}

		if (!valid) {
			printf("OpenGL pixel format not supported.\n");
			return nil;
		}
	}

	self = [super initWithFrame:frame pixelFormat:[pf autorelease]];
	appLock = [[NSRecursiveLock alloc] init];

	return self;
}

- (void) prepareOpenGL {
	[super prepareOpenGL];

	[[self window] setLevel: NSNormalWindowLevel];
	[[self window] makeKeyAndOrderFront: self];

	// Make all the OpenGL calls to setup rendering and build the necessary rendering objects
	[[self openGLContext] makeCurrentContext];

	GLint swapInt = 1; // Vsync on!
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);

	CVDisplayLinkSetOutputCallback(displayLink, &GlobalDisplayLinkCallback, self);

	CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

	GLint dim[2] = {windowRect.size.width, windowRect.size.height};
	CGLSetParameter(cglContext, kCGLCPSurfaceBackingSize, dim);
	CGLEnable(cglContext, kCGLCESurfaceBackingSize);

	[appLock lock];
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);

	float points[] = {
		0.0f,  1.0f,  0.0f,
		1.0f, -1.0f,  0.0f,
		-1.0f, -1.0f,  0.0f
	};

	GLuint vbo = 0;
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(points) * sizeof(float), points, GL_STATIC_DRAW);

	vao = 0;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);
	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);

	GLint compile_success = GL_FALSE;
	const char *vert_source =
	"	#version 150\n"
	"	in vec2 coords;"

	"	void main() {"
	"		gl_Position = vec4(coords, 0.0, 1.0);"
	"	}";

	const char *frag_source =
	"	#version 150\n"
	"	out vec4 frag_color;"

	"	void main() {"
	"		frag_color = vec4(0.5, 0.0, 0.5, 1.0);"
	"	}";

	GLint vert_shader = glCreateShader(GL_VERTEX_SHADER);
	GLint frag_shader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(vert_shader, 1, &vert_source, NULL);
	glShaderSource(frag_shader, 1, &frag_source, NULL);

	glCompileShader(vert_shader);
	glCompileShader(frag_shader);

	glGetShaderiv(vert_shader, GL_COMPILE_STATUS, &compile_success);
	if (!compile_success) {
		printf("Vertex Shader error!\n");
		return;
	}

	glGetShaderiv(frag_shader, GL_COMPILE_STATUS, &compile_success);
	if (!compile_success) {
		printf("Frag Shader error!\n");
		return;
	}

	shader_program = glCreateProgram();
	glAttachShader(shader_program, vert_shader);
	glAttachShader(shader_program, frag_shader);
	glLinkProgram(shader_program);

	printf("GL version: %s\n", glGetString(GL_VERSION));
    printf("GLSL version: %s\n", glGetString(GL_SHADING_LANGUAGE_VERSION));

	glViewport(0, 0, windowRect.size.width, windowRect.size.height);

	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	[appLock unlock];

	CVDisplayLinkStart(displayLink);
}

// Tell the window to accept input events
- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)mouseMoved:(NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void) mouseDragged: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void)scrollWheel: (NSEvent*) event  {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void) mouseDown: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void) mouseUp: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void) rightMouseDown: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void) rightMouseUp: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void)otherMouseDown: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void)otherMouseUp: (NSEvent*) event {
	[appLock lock];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	[appLock unlock];
}

- (void) mouseEntered: (NSEvent*)event {
	[appLock lock];
	[appLock unlock];
}

- (void) mouseExited: (NSEvent*)event {
	[appLock lock];
	[appLock unlock];
}

- (void) keyDown: (NSEvent*) event {
	[appLock lock];
	if ([event isARepeat] == NO) {
	}
	[appLock unlock];
}

- (void) keyUp: (NSEvent*) event {
	[appLock lock];
	[appLock unlock];
}

// Update
- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime {
	[appLock lock];

	[[self openGLContext] makeCurrentContext];
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);

	glClearColor(0.1, 0.1, 0.1, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glUseProgram(shader_program);
	glBindVertexArray(vao);
	glDrawArrays(GL_TRIANGLES, 0, 4);

	CGLFlushDrawable((CGLContextObj)[[self openGLContext] CGLContextObj]);
    CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);

    if (false) {
		[NSApp terminate:self];
	}

	[appLock unlock];

	return kCVReturnSuccess;
}

// Resize
- (void)windowDidResize:(NSNotification*)notification {
	NSSize size = [ [ _window contentView ] frame ].size;
	[appLock lock];
	[[self openGLContext] makeCurrentContext];
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	// Temp
	windowRect.size.width = size.width;
	windowRect.size.height = size.height;
	glViewport(0, 0, windowRect.size.width, windowRect.size.height);
	// End temp
	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	[appLock unlock];
}

- (void)resumeDisplayRenderer  {
    [appLock lock];
    CVDisplayLinkStop(displayLink);
    [appLock unlock];
}

- (void)haltDisplayRenderer  {
    [appLock lock];
    CVDisplayLinkStop(displayLink);
    [appLock unlock];
}

// Terminate window when the red X is pressed
-(void)windowWillClose:(NSNotification *)notification {
	if (running) {
		running = false;

		[appLock lock];

		CVDisplayLinkStop(displayLink);
		CVDisplayLinkRelease(displayLink);

		[appLock unlock];
	}

	[NSApp terminate:self];
}

// Cleanup
- (void) dealloc {
	[appLock release];
	[super dealloc];
}
@end

static CVReturn GlobalDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext) {
	CVReturn result = [(View*)displayLinkContext getFrameForTime:outputTime];
	return result;
}

int main(int argc, const char *argv[])  {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[NSApplication sharedApplication];

	// Style flags
	NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;

	// Window bounds (x, y, width, height)
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect viewRect = NSMakeRect(0, 0, 800, 600);
	NSRect windowRect = NSMakeRect(NSMidX(screenRect) - NSMidX(viewRect), NSMidY(screenRect) - NSMidY(viewRect), viewRect.size.width, viewRect.size.height);

	NSWindow * window = [[NSWindow alloc] initWithContentRect:windowRect styleMask:windowStyle backing:NSBackingStoreBuffered defer:NO];
	[window autorelease];

	// Window controller
	NSWindowController * windowController = [[NSWindowController alloc] initWithWindow:window];
	[windowController autorelease];

	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

	id menubar = [[NSMenu new] autorelease];
	id appMenuItem = [[NSMenuItem new] autorelease];
	[menubar addItem:appMenuItem];
	[NSApp setMainMenu:menubar];

	id appMenu = [[NSMenu new] autorelease];
	id appName = [[NSProcessInfo processInfo] processName];
	id quitTitle = [@"Quit " stringByAppendingString:appName];
	id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
	[appMenu addItem:quitMenuItem];
	[appMenuItem setSubmenu:appMenu];

	// Create app delegate to handle system events
	View* view = [[[View alloc] initWithFrame:windowRect] autorelease];
	view->windowRect = windowRect;
	[window setAcceptsMouseMovedEvents:YES];
	[window setContentView:view];
	[window setDelegate:view];

	// Set app title
	[window setTitle:appName];

	// Add fullscreen button
	[window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];

	// Show window and run event loop
	[window orderFrontRegardless];
	[NSApp run];

	[pool drain];

	return (0);
}
